//
//  AddOneViewController.m
//  Blackboard
//
//  Created by Brian Daneshgar on 6/2/15.
//  Copyright (c) 2015 Brian Daneshgar. All rights reserved.
//

#import "AddOneViewController.h"


@interface AddOneViewController ()

//TEXT FIELD
@property (strong, nonatomic) IBOutlet UITextField *textField;

//SAVE + CANCEL BUTTONS
@property (strong, nonatomic) IBOutlet UIButton *saveOutlet;
- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

//CHAR COUNT LABEL
@property (strong, nonatomic) IBOutlet UILabel *charCount;

@end

@implementation AddOneViewController{
    //25
    int charLimit;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //CHANGE CHAR LIMIT?
    charLimit = 25;
    self.charCount.text = [NSString stringWithFormat:@"%d", charLimit];
    
    //TEXT FIELD CHECK LIMIT
    [self.textField addTarget:self action:@selector(showLimit:) forControlEvents:UIControlEventEditingChanged];
    self.textField.delegate = self;
    
    //HIDE SAVE BUTTON UNTIL THREE CHARACTERS TYPED
    self.saveOutlet.hidden = YES;
    self.saveOutlet.contentHorizontalAlignment = NSTextAlignmentRight;
    
    //PLACEHOLDER TEXT FOR TEXT FIELD
    UIColor *color = [UIColor grayColor];
    self.textField.attributedPlaceholder =
    [[NSAttributedString alloc] initWithString:@"New Entry"
                                    attributes:@{
                                                 NSForegroundColorAttributeName: color,
                                                 NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0]}];
    
    
    //DISMISS KEYBOARD ON OUTSIDE TAP
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];

    
    
    //NETWORK CONNECTIVITY TEST
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Add Entry"
                                                        message:@"You must be connected to the internet"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [self noInternet];
        NSLog(@"There IS NO internet connection");
    }
    else {
        NSLog(@"There IS internet connection");
    }
}

//RESIGN KEYBOARD ON OUTSIDE TAP
-(void)dismissKeyboard {
    [self.textField resignFirstResponder];
}

//HIDE STATUS BAR
-(BOOL)prefersStatusBarHidden{
    return YES;
}

//SHOW CHAR LIMIT, CHANGE COLORS
- (void)showLimit:(id)sender {
    if((int)self.textField.text.length > 3){
        self.saveOutlet.hidden = NO;
    }
    else{
        self.saveOutlet.hidden = YES;
    }
    charLimit = 25 - (int)self.textField.text.length;
    self.charCount.text =[NSString stringWithFormat:@"%d", charLimit];
    if(charLimit < 15 && charLimit >= 6){
        self.charCount.textColor = [UIColor orangeColor];
    }
    else if(charLimit <= 5){
        self.charCount.textColor = [UIColor redColor];
    }
    else{
        self.charCount.textColor = [UIColor whiteColor];
    }
}


//MAINTAIN PLACEHOLDER
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.textField.placeholder = nil;
}

//SET TEXT ON EDITING
- (void)textFieldDidEndEditing:(UITextField *)textField {
    UIColor *color = [UIColor grayColor];
    self.textField.attributedPlaceholder =
    [[NSAttributedString alloc] initWithString:@"New Entry"
                                    attributes:@{
                                                 NSForegroundColorAttributeName: color,
                                                 NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0]}];
    
}

//CANNOT TYPE PAST CHARLIMIT
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range     replacementString:(NSString *)string
{
    if (textField.text.length >= 25 && range.length == 0){
        return NO;
    }
    return YES;
}


//PRESSED RETURN KEY
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self save:self];
    [self.textField resignFirstResponder];
       return YES;
}


//HANDLE SAVE, CHECK SPAM FILTER, SPECIAL CHARACTERS, AND ILLEGAL EXPRESSIONS
- (IBAction)save:(id)sender {
    
    //ENTRY TOO SHORT
    if(self.textField.text.length < 3){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Add Entry"
                                                        message:@"The entry must contain at least 3 characters"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    
    //VALID CHARACTERS and PROFANITY CHECK
    NSString *illegalExpression = [self.textField.text iod_filteredString];
    NSCharacterSet * set = [[NSCharacterSet characterSetWithCharactersInString:@" abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.:/!?#$&~,-'"] invertedSet];
    if ([illegalExpression rangeOfCharacterFromSet:set].location != NSNotFound) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Add Entry"
                                                        message:@"The entry contains illegal characters or illegal expression"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }

    
    
    
    
    //AUTOCAPITALIZE FIRST LETTER
    NSString *firstChar = [self.textField.text substringToIndex:1];
    NSString *result = [[firstChar uppercaseString] stringByAppendingString:[self.textField.text substringFromIndex:1]];
    self.textField.text = result;
    
    //ASK TO CONFIRM
    [self askToConfirm];
    
}


//ERROR FOUND SPAM FILTER
-(void)error{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Add Entry"
                                                    message:@"The entry contains an illegal expression"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}


//CONFIRM ALERT
-(void)askToConfirm{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please Confirm"
                                                    message:[NSString stringWithFormat:@" '%@'", self.textField.text]
                                                   delegate:self
                                          cancelButtonTitle:@"Edit"
                                          otherButtonTitles:@"Confirm",nil];
    [alert show];
}

//HANDLE CONFIRM ALERT
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // the user clicked OK
    if (buttonIndex == 1) {
        [self confirmed];
    }
    if (buttonIndex == 0){
        [self.textField becomeFirstResponder];
    }
}

//CONFIRMED ENTRY
-(void)confirmed{
    
    //CREATE INDEX FOR NEW OBJECT
    PFQuery *master = [PFQuery queryWithClassName:@"text"];
    [master orderByDescending:@"createdAt"];
    [master getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        int index = [object[@"index"] intValue] + 1;
        NSString *stringIndex = [NSString stringWithFormat:@"%d", index];
        NSLog(@"Entry #: %d",index + 1);

        //CREATE OBJECT, ASSIGN INDEX
        PFObject *textObject = [PFObject objectWithClassName:@"text"];
        [textObject setObject:stringIndex forKey:@"index"];
        
        //QUERY FOR PREV OBJECT
        NSString *stringPrevIndex = [NSString stringWithFormat:@"%d", index - 1];
        PFQuery *textQuery = [PFQuery queryWithClassName:@"text"];
        [textQuery whereKey:@"index" equalTo:stringPrevIndex];
        [textQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                PFObject *prevObject = [textQuery getFirstObject];
                prevObject[@"nextObjectId"] = textObject.objectId;
                textObject[@"prevObjectId"] = prevObject.objectId;
                [prevObject saveInBackground];
                [textObject saveInBackground];

            } else {
                //NO MATCHING INDEX FOUND
                NSLog(@"Error");
            }
        }];
        
        textObject[@"textForYou"] = self.textField.text;
        textObject[@"reports"] = @0;
        [textObject save];

    }];
    
    
    //SEGUE VIEW
    [self dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"Saved");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thank You"
                                                    message:@"This entry is now added to the collection"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}



- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void) noInternet{
    [self dismissViewControllerAnimated:YES completion:nil];

}

@end
