//
//  WordListHandler.swift
//  VocabCrack-iOS
//
//  Created by aidancbrady on 12/10/14.
//  Copyright (c) 2014 aidancbrady. All rights reserved.
//

import UIKit

struct CoreFiles
{
    static let dataFile:NSString = WordListHandler.getDocumentsDir().stringByAppendingPathComponent("ListData.txt")
    static let wordFile:NSString = WordListHandler.getDocumentsDir().stringByAppendingPathComponent("WordData.txt")
    static let defaultList:NSString = WordListHandler.getDefaultList()
}

class WordListHandler
{
    class func populateDefaults(inout array:[(String, String)])
    {
        array.append("Default", "DefaultURL")
    }
    
    class func loadList(id:String, controller:WeakWrapper<NewGameController>)
    {
        Constants.CORE.listID = nil
        Constants.CORE.activeList.removeAll(keepCapacity: false)
        
        if id == "Default"
        {
            loadDefaultList(controller);
        }
        else {
            loadCustomList(id, controller: controller);
        }
    }
    
    class func loadCustomList(id:String, controller:WeakWrapper<NewGameController>)
    {
        println("Loading '" + id + "' word list...");
        
        let url = Constants.CORE.listURLs[id]!
        
        let reader:Utilities.HTTPReader = Utilities.HTTPReader()
        let request:NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: url)!)
        
        var returned = false
        
        reader.getHTTP(request)
        {
            (response:String?) -> Void in
            if let str = response
            {
                let array:[String] = str.componentsSeparatedByString("\n")
                
                if array.count == 1 && array[0] == "null"
                {
                    controller.value?.listLoaded(false)
                    returned = true
                    return
                }
                
                var failed:Bool = false
                
                for s in array
                {
                    let split:[String] = Utilities.split(s, separator: String(Constants.LIST_SPLITTER))
                    
                    if split.count != 2
                    {
                        failed = true
                        
                        break
                    }
                    
                    Constants.CORE.activeList.append(Utilities.trim(s))
                }
                
                if !failed && Constants.CORE.activeList.count >= 10
                {
                    Constants.CORE.listID = id
                    controller.value?.listLoaded(true)
                }
                else {
                    Constants.CORE.activeList.removeAll(keepCapacity: false)
                    controller.value?.listLoaded(false)
                }
                
                returned = true
            }
            else {
                println("Failed to load '" + id + "' word list.")
            }
            
            return
        }
        
        if !returned
        {
            controller.value?.listLoaded(false)
        }
    }
    
    class func loadDefaultList(controller:WeakWrapper<NewGameController>)
    {
        let manager:NSFileManager = NSFileManager()
        
        println("Loading default word list...");
        
        if manager.fileExistsAtPath(CoreFiles.defaultList)
        {
            let content:String = NSString(contentsOfFile: CoreFiles.defaultList, encoding: NSUTF8StringEncoding, error: nil)!
            let split = content.componentsSeparatedByString("\n")
            
            var failed = false
            
            for str in split
            {
                let dataSplit = Utilities.split(str, separator: String(Constants.LIST_SPLITTER))
                
                if(dataSplit.count != 2)
                {
                    failed = true
                    
                    break
                }
                
                Constants.CORE.activeList.append(Utilities.trim(str));
            }
            
            if !failed && Constants.CORE.activeList.count >= 10
            {
                Constants.CORE.listID = "Default"
                controller.value?.listLoaded(true)
            }
            else {
                Constants.CORE.activeList.removeAll(keepCapacity: false)
                controller.value?.listLoaded(false)
            }
        }
        else {
            controller.value?.listLoaded(false)
        }
    }
    
    class func loadListData()
    {
        let manager:NSFileManager = NSFileManager()
        
        println("Loading word list data...")
        if manager.fileExistsAtPath(CoreFiles.dataFile)
        {
            let content:String = NSString(contentsOfFile: CoreFiles.dataFile, encoding: NSUTF8StringEncoding, error: nil)!
            let split = content.componentsSeparatedByString("\n")
            
            for str in split
            {
                let dataSplit = Utilities.split(str, separator: ":")
                
                if dataSplit.count == 2
                {
                    Constants.CORE.listURLs[dataSplit[0]] = dataSplit[1]
                }
            }
        }
    }
    
    class func saveListData()
    {
        let manager:NSFileManager = NSFileManager()
        
        println("Saving word list data...")
        
        if manager.fileExistsAtPath(CoreFiles.dataFile)
        {
            manager.removeItemAtPath(CoreFiles.dataFile, error: nil)
        }
        
        manager.createFileAtPath(CoreFiles.dataFile, contents: nil, attributes: nil)
        
        var str = NSMutableString()
        
        for entry in Constants.CORE.listURLs
        {
            str.appendString("\(entry.0):\(entry.1)\n")
        }
        
        let data = str.dataUsingEncoding(NSUTF8StringEncoding)!
        data.writeToFile(CoreFiles.dataFile, atomically: true)
    }
    
    class func listNames() -> [String]
    {
        return Array(Constants.CORE.listURLs.keys)
    }
    
    class func addList(name:String, url:String)
    {
        Constants.CORE.listURLs[name] = url
        saveListData()
    }
    
    class func deleteList(name:String)
    {
        Constants.CORE.listURLs.removeValueForKey(name)
        saveListData();
    }
    
    class func getDocumentsDir() -> NSString
    {
        let paths:NSArray = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        
        return paths.objectAtIndex(0) as NSString
    }
    
    class func getDefaultList() -> NSString
    {
        return NSBundle.mainBundle().pathForResource("DefaultList", ofType: "txt")!
    }
}

class ListHandler
{
    func confirmList(controller:WeakWrapper<NewListController>, identifier:String?)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            let str = identifier != nil ? compileMsg("CONFLIST", Constants.CORE.account.username, identifier!) : compileMsg("CONFLIST", Constants.CORE.account.username, Constants.NULL)
            let ret = NetHandler.sendData(str)
            
            dispatch_async(dispatch_get_main_queue(), {
                if let newList = controller.value
                {
                    if let response = ret
                    {
                        let array:[String] = Utilities.split(response, separator: Constants.SPLITTER_1)
                        
                        if array[0] == "ACCEPT"
                        {
                            let createList:UINavigationController = newList.storyboard?.instantiateViewControllerWithIdentifier("CreateListNavigation") as UINavigationController
                            
                            newList.presentViewController(createList, animated: true, completion: nil)
                        }
                        else {
                            Utilities.displayAlert(newList, title: "Error", msg: array[1], action: nil)
                        }
                    }
                    else {
                        Utilities.displayAlert(newList, title: "Error", msg: "Unable to connect.", action: nil)
                    }
                    
                    if newList.activityIndicator.isAnimating()
                    {
                        newList.activityIndicator.stopAnimating()
                    }
                }
            })
        })
    }
    
    func updateLists(controller:WeakWrapper<WordListsController>)
    {
        if Operations.loadingLists
        {
            return
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            Operations.loadingLists = true
            
            let str = compileMsg("LLISTS", Constants.CORE.account.username)
            let ret = NetHandler.sendData(str)
            
            dispatch_async(dispatch_get_main_queue(), {
                Operations.loadingLists = false
                
                if let table = controller.value
                {
                    if let response = ret
                    {
                        let array:[String] = Utilities.split(response, separator: Constants.SPLITTER_1)
                        
                        if array[0] == "ACCEPT"
                        {
                            var urlArray:[(String, String)] = [(String, String)]()
                            
                            for var i = 1; i < array.count; i++
                            {
                                let split:[String] = Utilities.split(array[i], separator: Constants.SPLITTER_2)
                                
                                if split.count == 2
                                {
                                    urlArray.append(split[0], split[1])
                                }
                            }
                            
                            table.serverArray = urlArray
                            table.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
                        }
                    }
                    
                    if table.refresher.refreshing
                    {
                        table.refresher.endRefreshing()
                    }
                }
            })
        })
    }
}