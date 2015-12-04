//
//  ViewController.swift
//  TextBox
//
//  Created by Brian Daneshgar on 7/30/15.
//  Copyright (c) 2015 Brian Daneshgar. All rights reserved.
//

import UIKit
import Parse

class ViewController: UIViewController {
    
    var texts = NSMutableArray()
    var adding = false
    @IBOutlet var text: UILabel!
    var moderator = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentUser = PFUser.currentUser()
        if currentUser != nil {

        } else {
            signUp()
        }
        
        setupText({
            self.setupGestures()
            self.next()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupGestures(){
        moderator = true
        let next = UITapGestureRecognizer(target: self, action: "next")
        self.view.addGestureRecognizer(next)
        
        let remove = UILongPressGestureRecognizer(target: self, action: "removeObject:")
        self.view.addGestureRecognizer(remove)
        
        let swipeAdd = UISwipeGestureRecognizer(target: self, action: "add:")
        swipeAdd.direction = UISwipeGestureRecognizerDirection.Up
        self.view.addGestureRecognizer(swipeAdd)
        
        
        if(moderator){
            let swipeMod = UISwipeGestureRecognizer(target: self, action: "mod:")
            swipeMod.direction = UISwipeGestureRecognizerDirection.Down
            self.view.addGestureRecognizer(swipeMod)
        }
    }
    
    func next(){
        
        text.alpha = 0
        let randomIndex = Int(arc4random_uniform(UInt32(texts.count)))
        let randomTextObject = texts[randomIndex] as! PFObject
        let randomText = randomTextObject["text"] as! String
        text.text = randomText
        
        UIView.animateWithDuration(1.0, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.text.alpha = 1
            }, completion: {
                (finished: Bool) -> Void in
        })
    }
    
    func add(sender: UIGestureRecognizer){
        if(sender.state == UIGestureRecognizerState.Began){
            self.addOne();
            return;
        }
        else{
            self.addOne();
        }
    }
    
    func addOne(){
        if(!adding){
            adding = true;
            self.performSegueWithIdentifier("add", sender: self)
        }
    }
    
    func mod(sender: UIGestureRecognizer){
        PFUser.currentUser()!.fetch()
        let currentUser: PFUser! = PFUser.currentUser()
        let moderator = currentUser["mod"] as! Bool
        print("\(moderator)")
        if(moderator){
            self.startMod();
        }
    }
    
    func startMod(){
        //check installation for mod if mod:
        self.performSegueWithIdentifier("mod", sender: self)

    }
    
    func removeObject(sender: UIGestureRecognizer){
        PFUser.currentUser()!.fetch()
        let currentUser: PFUser! = PFUser.currentUser()
        let moderator = currentUser["mod"] as! Bool
        if(moderator){
            let confirm = UIAlertController(title: "Delete?", message:"'" + text.text! + "'", preferredStyle: UIAlertControllerStyle.Alert)
            confirm.addAction(UIAlertAction(title: "No", style: .Default, handler: { (action: UIAlertAction!) in
            }))
            confirm.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction) in
                let query = PFQuery(className:"text")
                query.whereKey("text", equalTo:self.text.text!)
                query.findObjectsInBackgroundWithBlock {
                    (objects: [AnyObject]?, error: NSError?) -> Void in
                    if error == nil {
                        // The find succeeded.
                        // Do something with the found objects
                        if let objects = objects as? [PFObject] {
                            for object in objects {
                                object.deleteInBackground()
                                print("Successfully deleted")
                            }
                        }
                        self.setupText({
                            self.setupGestures()
                            self.next()
                        })
                    } else {
                        // Log details of the failure
                        print("Error: \(error!) \(error!.userInfo)")
                    }
                }

                
            }))
            presentViewController(confirm, animated: true, completion: nil)
            
            
        }
    }
    
    
    func setupText(completion : Void -> Void) {
        text.text = ""
        text.font = UIFont(name: "Roboto-Medium", size: 17)

        //pull from parse
        let query = PFQuery(className:"text")
        query.limit = 500
        query.orderByDescending("createdAt")
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                if let objects = objects as? [PFObject] {
                    self.texts.addObjectsFromArray(objects)
                    print("loaded")
                    completion()
                }
            } else {
                print("Error: \(error!) \(error!.userInfo)")
            }
        }
    }
    

    
    @IBAction func unwindToSegue(segue:UIStoryboardSegue) {
        
        if(segue.sourceViewController .isKindOfClass(AddOneViewController))
        {
            adding = false
            let aovc:AddOneViewController = segue.sourceViewController as! AddOneViewController
            if(aovc.submitted){
                    let alert = UIAlertView()
                    alert.title = "Thank you!"
                    alert.message = "You will be notified if your entry is added to the collection."
                    alert.addButtonWithTitle("OK")
                    alert.show()
            }
            if(aovc.modReq){
                let alert = UIAlertView()
                alert.title = "Thank you!"
                alert.message = "Your mod request has been sent."
                alert.addButtonWithTitle("OK")
                alert.show()
            }
        }
    }
    
    func signUp() {
        let user = PFUser()
        let randomString = randomStringWithLength(10) as String
        
        
        user.username = randomString
        user.password = randomString
        user["mod"] = false
        
        user.signUpInBackgroundWithBlock {
            (succeeded: Bool, error: NSError?) -> Void in
            if(succeeded){
                let currentInstallation = PFInstallation.currentInstallation()
                currentInstallation["owner"] = PFUser.currentUser()?.objectId
                currentInstallation["ownerPointer"] = PFUser.currentUser()
                
                
                currentInstallation.saveInBackground()
   
            }
        }
    }
    
    func randomStringWithLength (len : Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        for (var i=0; i < len; i++){
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        
        return randomString
    }
    
}

