//
//  ModViewController.swift
//  TextBox
//
//  Created by Brian Daneshgar on 7/30/15.
//  Copyright (c) 2015 Brian Daneshgar. All rights reserved.
//

import UIKit
import Parse

class ModViewController: UIViewController {
    
    var submissions = NSMutableArray()
    var adding = false
    var currentSubmission = PFObject(className:"submission")
    var index = 0
    
    @IBOutlet var cancel: UIButton!
    @IBAction func cancel(sender: AnyObject) {
        self.performSegueWithIdentifier("unwind", sender: self)
    }
    
    
    @IBOutlet var text: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubmission({
            self.setupGestures()
            self.next()
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func next(){
        
        if(submissions.count == 0 || index == submissions.count){
            print("end of array")
            setupSubmission({
            })
        }
        else{
            text.alpha = 0
            currentSubmission = submissions[index] as! PFObject
            let submissionText = currentSubmission["text"] as! String
            text.text = submissionText
            index++
            UIView.animateWithDuration(1.0, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                self.text.alpha = 1
                }, completion: {
                    (finished: Bool) -> Void in
            })

        }
        
    }


    func approve(sender: UIGestureRecognizer){
        if(submissions.count == 0){
            return
        }
        let approveAlert = UIAlertController(title: "Approve?", message:"'" + text.text! + "'", preferredStyle: UIAlertControllerStyle.Alert)
        approveAlert.addAction(UIAlertAction(title: "Wait", style: .Default, handler: { (action: UIAlertAction) in
        }))
        approveAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction) in
            
            let entry = PFObject(className:"text")
            let installation = PFInstallation.currentInstallation()
            
            entry["text"] = self.currentSubmission["text"]
            entry["approvedBy"] = installation.objectId
            
            entry.saveInBackgroundWithBlock {
                (success: Bool, error: NSError?) -> Void in
                if (success) {
                    let userId = self.currentSubmission["user"] as! String
                    let pushQuery: PFQuery = PFInstallation.query()!
                    pushQuery.whereKey("owner", equalTo: userId)
                    let push = PFPush()
                    push.setQuery(pushQuery)
                    push.setMessage("Your entry has been approved")
                    push.sendPushInBackgroundWithBlock(nil)
                    
                    self.submissions.removeObject(self.currentSubmission)
                    self.currentSubmission.deleteInBackgroundWithBlock({
                        (succeeded: Bool, error: NSError?) -> Void in
                        if(succeeded){
                            print("successfully added, push sent, removed from submissions")
                            self.setupSubmission({ self.index = 0})
                        }
                    })
                }
                else{
                    let alert = UIAlertView()
                    alert.title = "Oops"
                    alert.message = "Please check your network and try again."
                    alert.addButtonWithTitle("OK")
                    alert.show()
                }
            }

        }))
        presentViewController(approveAlert, animated: true, completion: nil)
    }
    
    func exit(sender: UIGestureRecognizer){
        self.exitMod();
    }
    func exitMod(){
        self.performSegueWithIdentifier("unwind", sender: self)        
    }
    
    func remove(){
        if(submissions.count == 0){
            return
        }
        let removeAlert = UIAlertController(title: "Remove?", message:"'" + text.text! + "'", preferredStyle: UIAlertControllerStyle.Alert)
        removeAlert.addAction(UIAlertAction(title: "Wait", style: .Default, handler: { (action: UIAlertAction) in
        }))
        removeAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction) in
            self.submissions.removeObject(self.currentSubmission)
            self.currentSubmission.deleteInBackgroundWithBlock({
                (succeeded: Bool, error: NSError?) -> Void in
                if(succeeded){
                    self.setupSubmission({ self.index = 0})
                }
            })
        }))
        presentViewController(removeAlert, animated: true, completion: nil)
    }
    
    
    
    func setupGestures(){
        let next = UITapGestureRecognizer(target: self, action: "next")
        self.view.addGestureRecognizer(next)
        
        let approve = UISwipeGestureRecognizer(target: self, action: "approve:")
        approve.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(approve)

        
        let remove = UISwipeGestureRecognizer(target: self, action: "remove")
        remove.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(remove)
        
        let exit = UISwipeGestureRecognizer(target: self, action: "exit:")
        exit.direction = [UISwipeGestureRecognizerDirection.Down, UISwipeGestureRecognizerDirection.Up]
        self.view.addGestureRecognizer(exit)
    }
    
    
    func setupSubmission(completion : Void -> Void) {
        
        self.text.font = UIFont(name: "Roboto-Medium", size: 17)

        
        //pull from parse
        let query = PFQuery(className:"submission")
        query.limit = 500
        query.orderByAscending("createdAt")
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let objects = objects as? [PFObject] {
                    for object: PFObject in objects{
                        self.submissions.addObject(object)
                    }
                    self.index = 0
                    if(self.submissions.count == 0){
                        self.text.text = ""
                    }
                    completion()
                }
            } else {
                self.text.text = "Check network and try again"
            }
        }
    }
    

}

