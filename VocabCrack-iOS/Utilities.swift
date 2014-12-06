//
//  Utilities.swift
//  VocabCrack-iOS
//
//  Created by aidancbrady on 12/3/14.
//  Copyright (c) 2014 aidancbrady. All rights reserved.
//

import UIKit

class Utilities
{
    class func displayAlert(controller:UIViewController, title:String, msg:String, action:((UIAlertAction!) -> Void)?)
    {
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: action)
        
        alertController.addAction(okAction)
        controller.presentViewController(alertController, animated: true, completion: nil)
    }
    
    class func isValidCredential(creds: String...) -> Bool
    {
        for s:String in creds
        {
            for c:Character in Constants.BAD_CHARS
            {
                if contains(s, c)
                {
                    return false
                }
            }
        }
    
        return true
    }
    
    class func buildGravatarURL(email:String, size:Int) -> NSURL
    {
        var str:NSMutableString = NSMutableString(format:"http://gravatar.com/avatar/%@?", buildMD5(email))
        str.appendString("&size=\(size)")
        
        return NSURL(string: str)!
    }
    
    class func buildMD5(email:String) -> String
    {
        let str = email.cStringUsingEncoding(NSUTF8StringEncoding)
        let strLen = CC_LONG(email.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
        
        CC_MD5(str!, strLen, result)
        
        var hash = NSMutableString()
        
        for i in 0..<digestLen
        {
            hash.appendFormat("%02x", result[i])
        }
        
        result.destroy()
        
        return String(format: hash)
    }
    
    class func trim(s:String) -> String
    {
        return s.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    
    class func readRemote(url:NSURL) -> String?
    {
        let task = NSURLSession.sharedSession().dataTaskWithURL(Constants.DATA_URL);
        
        return nil
    }
    
    class func loadData()
    {
        let reader:HTTPReader = HTTPReader()
        let request:NSMutableURLRequest = NSMutableURLRequest(URL: Constants.DATA_URL)
        
        reader.getHTTP(request)
        {
            (response:String?) -> Void in
            if let str = response
            {
                let array:[String] = str.componentsSeparatedByString("\n")
                
                Constants.IP = array[0]
                Constants.PORT = array[1].toInt()!
            
                println("Loaded data")
            }
            else {
                println("Failed to load data")
            }
            
            return
        }
    }
    
    class func loadAvatar(view:UIImageView, email:String)
    {
        if Constants.CORE.avatars[email] != nil
        {
            view.image = Constants.CORE.avatars[email]
            return
        }
        
        weak var weakView = view
        
        Operations.loadingAvatars.addObject(email)
        
        let url:NSURL = Utilities.buildGravatarURL(email, size: 512)
        var request: NSURLRequest = NSURLRequest(URL: url)
        
        var image:UIImage? = nil
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            image = UIImage(data: data)
            
            if weakView != nil
            {
                if image != nil
                {
                    weakView!.image = image
                    Constants.CORE.avatars[email] = image
                }
            }
            
            Operations.loadingAvatars.removeObject(email)
        })
    }
    
    class HTTPReader: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate
    {
        func getHTTP(request: NSMutableURLRequest!, action:(String?) -> Void)
        {
            var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            var session = NSURLSession(configuration: configuration, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
            
            var task = session.dataTaskWithRequest(request)
            {
                (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
                if error == nil
                {
                    action(NSString(data: data, encoding:NSUTF8StringEncoding))
                }
                else {
                    action(nil)
                }
                
                return
            }
            
            task.resume()
        }
        
        func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void)
        {
            completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, NSURLCredential(forTrust: challenge.protectionSpace.serverTrust))
        }
        
        func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest!) -> Void)
        {
            var newRequest: NSURLRequest? = request
            completionHandler(newRequest)
        }
    }
}