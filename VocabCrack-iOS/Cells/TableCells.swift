//
//  FriendCell.swift
//  VocabCrack-iOS
//
//  Created by aidancbrady on 12/6/14.
//  Copyright (c) 2014 aidancbrady. All rights reserved.
//

import UIKit

class FriendCell: UITableViewCell
{
    @IBOutlet weak var userAvatar: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var lastSeenLabel: UILabel!
    
    var controller:FriendsController?
    var user:Account?
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
        
        if controller != nil && user != nil && selected
        {
            if controller!.modeButton.selectedSegmentIndex == 1
            {
                Utilities.displayYesNo(controller!, title: "Confirm", msg: "Accept request from " + user!.username + "?", action: {(action) -> Void in
                    Handlers.friendHandler.acceptRequest(WeakWrapper(value: self.controller!), friend: self.user!.username)
                    
                    var path = self.controller!.tableView.indexPathForCell(self)
                    self.controller!.tableView(self.controller!.tableView, commitEditingStyle: .Delete, forRowAtIndexPath: path!)
                    Handlers.friendHandler.updateData(WeakWrapper(value: self.controller!))
                    return
                }, cancel: {(action) -> Void in
                    self.setSelected(false, animated: true)
                })
            }
        }
    }
}

class GameCell: UITableViewCell
{
    @IBOutlet weak var userAvatar: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var turnLabel: UILabel!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}

class UserCell:UITableViewCell
{
    @IBOutlet weak var usernameLabel: UILabel!
    
    var controller:AddFriendController?

    override func awakeFromNib()
    {
        super.awakeFromNib()
    }
    
    override func setSelected(selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
        
        if controller != nil && selected
        {
            Utilities.displayYesNo(controller!, title: "Confirm", msg: ("Send friend request to " + usernameLabel.text! + "?"), action: {(action) -> Void in
                Handlers.friendHandler.sendRequest(WeakWrapper(value: self.controller!), friend: self.usernameLabel.text!)
                self.controller!.navigationController!.popViewControllerAnimated(true)
            }, cancel: {(action) -> Void in
                self.setSelected(false, animated: true)
            })
        }
    }
}