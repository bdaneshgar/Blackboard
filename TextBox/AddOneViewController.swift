//
//  AddOneViewController.swift
//  TextBox
//
//  Created by Brian Daneshgar on 7/30/15.
//  Copyright (c) 2015 Brian Daneshgar. All rights reserved.
//

import UIKit
import Parse
import StoreKit
import Foundation


class AddOneViewController: UIViewController, UITextViewDelegate{
    
    
    
    
    let CHAR_LIMIT = 100
    
    var submitted = false
    var modReq = false
    
    
    
    @IBOutlet var cancel: UIButton!
    @IBAction func cancel(sender: AnyObject) {
        textView.resignFirstResponder()
        self.performSegueWithIdentifier("unwind", sender: self)
    }
    
    
    let vc = ViewController();
    var charCount = UILabel()
    
    //text field
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextView()
        setupGestures()
    }
    
    func setupGestures(){
        let cancel = UISwipeGestureRecognizer(target: self, action: "cancel:")
        cancel.direction = UISwipeGestureRecognizerDirection.Down
        self.view.addGestureRecognizer(cancel)
    }
    
    

    
    func textViewDidChange(textView: UITextView) {
        if(CHAR_LIMIT - textView.text.characters.count < 25){
            charCount.textColor = UIColor.redColor()
        }
        else if(CHAR_LIMIT - textView.text.characters.count < 50){
            charCount.textColor = UIColor.orangeColor()
        }
        else{
            charCount.textColor = UIColor.whiteColor()
        }
        charCount.text = "\(CHAR_LIMIT - textView.text.characters.count)"

    }
    
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n"){
            //check for errors
            self.textView.resignFirstResponder()
            
            let confirm = UIAlertController(title: "Please Confirm", message:"'" + textView.text + "'", preferredStyle: UIAlertControllerStyle.Alert)
            confirm.addAction(UIAlertAction(title: "Edit", style: .Default, handler: { (action: UIAlertAction!) in
                self.textView.becomeFirstResponder()
            }))
            confirm.addAction(UIAlertAction(title: "Confirm", style: .Default, handler: { (action: UIAlertAction) in
                self.confirmText()

                //create temp entry
                //notify me via push for every 10 entries
                //segue back to main view
                
            }))
            presentViewController(confirm, animated: true, completion: nil)
            return false
        }
        
        //create updated text entry
        let currentText:NSString = textView.text
        let updatedText = currentText.stringByReplacingCharactersInRange(range, withString:text)
        
        //if empty then init placeholder
        if updatedText.characters.count == 0 {
            
            textView.text = "New Entry"
            textView.textColor = UIColor.lightGrayColor()
            
            textView.selectedTextRange = textView.textRangeFromPosition(textView.beginningOfDocument, toPosition: textView.beginningOfDocument)
            charCount.text = "\(CHAR_LIMIT)"
            
            return false
        }
            
        //prepare for entry
        else if textView.textColor == UIColor.lightGrayColor() && text.characters.count > 0 {
            textView.text = nil
            textView.textColor = UIColor.whiteColor()
        }
        return true
    }
   
    //don't allow cursor to move when placeholder is visible
    func textViewDidChangeSelection(textView: UITextView) {
        if self.view.window != nil {
            if textView.textColor == UIColor.lightGrayColor() {
                textView.selectedTextRange = textView.textRangeFromPosition(textView.beginningOfDocument, toPosition: textView.beginningOfDocument)
            }
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool{
        let alert = UIAlertController(title: "Alert", message: "Message", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        return false;
    }
    
    func setupTextView(){
        cancel.tintColor = UIColor.whiteColor()
        cancel.setImage(UIImage(named: "x"), forState: UIControlState.Normal)
        cancel.addTarget(self, action: "cancel:", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(cancel)
       
        self.textView.delegate = self
        textView.text = "New Entry"
        textView.font = UIFont(name: "Roboto-Medium", size: 17)
        textView.textColor = UIColor.lightGrayColor()
        textView.becomeFirstResponder()
        
        //cursor
        textView.tintColor = UIColor.whiteColor()
        textView.selectedTextRange = textView.textRangeFromPosition(textView.beginningOfDocument, toPosition: textView.beginningOfDocument)
        
        
        
        charCount = UILabel(frame: CGRectMake(0, 32, view.frame.size.width, 20))
        charCount.textAlignment = NSTextAlignment.Center
        charCount.text = "100"
        charCount.font = UIFont(name: "Roboto-Light", size: 17)
        charCount.textColor = UIColor.whiteColor()
        self.view.addSubview(charCount)
    }
    
    
    
    func confirmText(){
        let currentUser: PFUser! = PFUser.currentUser()
        let enteringKey = "mod::"
        if(textView.text.rangeOfString(enteringKey) != nil){
            print("checking keys")
            let query = PFQuery(className:"modKey")
            query.whereKey("key", equalTo:textView.text)
            query.getFirstObjectInBackgroundWithBlock {
                (object: PFObject?, error: NSError?) -> Void in
                if object != nil {
                    print("key exists")
                    currentUser["mod"] = true
                    currentUser.saveInBackground()
                    object!.deleteInBackground()
                    
                    
                    let alert = UIAlertView()
                    alert.title = "Welcome"
                    alert.message = "You are now a mod."
                    alert.addButtonWithTitle("OK")
                    alert.show()
                }
                else{
                    let alert = UIAlertView()
                    alert.title = "Sorry"
                    alert.message = "Mod key not found."
                    alert.addButtonWithTitle("OK")
                    alert.show()
                }
            }
        }
        else{
            if(textView.text.characters.count < 3 || textView.text.characters.count > CHAR_LIMIT){
                let alert = UIAlertView()
                alert.title = "Oops"
                alert.message = "Entries must contain 3-100 characters"
                alert.addButtonWithTitle("Edit")
                alert.show()
            }
            else if(!submitted){ //ensure no duplicates
                submitted = true
                let submission = PFObject(className:"submission")
                submission["text"] = textView.text
                submission["user"] = PFUser.currentUser()?.objectId
                submission.saveInBackgroundWithBlock {
                    (success: Bool, error: NSError?) -> Void in
                    if (success) {
                        print("submitted")
                        self.performSegueWithIdentifier("unwind", sender: self)
                    } else {
                        let alert = UIAlertView()
                        alert.title = "Oops"
                        alert.message = "Please check your network and try again."
                        alert.addButtonWithTitle("OK")
                        alert.show()
                    }
                }
            }
        }
        
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.currentDevice().orientation.isLandscape.boolValue {
            charCount.frame = CGRectMake(0, 32, view.frame.size.height, 20)

        } else {
            charCount.frame = CGRectMake(0, 32, view.frame.size.height, 20)
        }
    }
    
    
}

