//
//  ViewController.m
//  Blackboard
//
//  Created by Brian Daneshgar on 6/1/15.
//  Copyright (c) 2015 Brian Daneshgar. All rights reserved.
//

#import "ViewController.h"
#import <Parse/Parse.h>

//RANDOM COLOR
typedef struct _Color {
    CGFloat red, green, blue;
} Color;
static Color _colors[12] = {
    {237, 230, 4},  // Yellow just to the left of center
    {158, 209, 16}, // Next color clockwise (green)
    {80, 181, 23},
    {23, 144, 103},
    {71, 110, 175},
    {159, 73, 172},
    {204, 66, 162},
    {255, 59, 167},
    {255, 88, 0},
    {255, 129, 0},
    {254, 172, 0},
    {255, 204, 0}
};


@interface ViewController ()


//MAIN TEXT
@property (strong, nonatomic) IBOutlet UILabel *text;

//DESCRIPTION TEXT (OPENING SCREEN DESCRIPTION )
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;

//UIBUTTON SIZE OF SCREEN
@property (strong, nonatomic) IBOutlet UIButton *screen;
- (IBAction)nextOne:(id)sender;

//PLUS BUTTON TO ADD ENTRY
@property (strong, nonatomic) IBOutlet UIButton *addEntry;

//PLUS BUTTON IMAGE (ONE LAYER BELOW BUTTON)
//(HIDDEN)
@property (strong, nonatomic) IBOutlet UIImageView *plusView;

//REPORT BUTTON
@property (strong, nonatomic) IBOutlet UIVisualEffectView *effectView;
@property (strong, nonatomic) IBOutlet UIButton *reportButton;
- (IBAction)reportButtonAction:(id)sender;

@end


@implementation ViewController{
    
    //LOCAL ARRAY
    NSMutableArray *arrayText;
    
    //LONG TAP VARIABLES
    NSTimeInterval touchStartTime;
    NSTimeInterval touchTimeDuration;
    
    //STORE PARSE INDEX
    NSString *stringIndexOfTextOnScreen;
    
    //SCREEN SHIFTED UP
    BOOL reporting;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    ////////* INIT VIEW *////////
    
    
    //HIDE PLUS IMAGE
    self.plusView.hidden = YES;
    
    //INIT BOOLS
    reporting = NO;
    
    //INIT FONTS
    UIFont *customFont = [UIFont fontWithName:@"DIN-MediumAlternate" size:19];
    UIFont *customDetailFont = [UIFont fontWithName:@"DIN-LightAlternate" size:14];
    self.text.font = customFont;
    self.descriptionLabel.font = customDetailFont;
    
    //INIT LONG PRESS RECOGNIZER
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.screen addGestureRecognizer:longPress];
    

    
    //LOCAL ARRAY
    //(NOT USED) --> SHOULD IMPLEMENT FOR OFFLINE USE (POSSIBLY PULL AND CACHE NEWER ONES?)
    arrayText = [NSMutableArray arrayWithObjects:@"Accept advice",
                 @"Be extravagant",
                 @"Define an area as 'safe' and use it as an anchor",
                 @"Use filters",
                 @"Simply a matter of work",
                 @"State the problem in words as clearly as possible",
                 @"Don't break the silence",
                 @"Disciplined self-indulgence",
                 @"The inconsistency principle",
                 @"You can only make one dot at a time",
                 @"A line has two sides",
                 @"The tape is now the music",
                 @"Destroy -nothing -the most important thing",
                 @"Don't be afraid of things because they're easy to do",
                 @"Bridges -build -burn",
                 @"Humanize something free of error",
                 @"Don't stress one thing more than another",
                 @"Remove ambiguities and convert to specifics",
                 @"Abandon normal instruments",
                 @"Do we need holes?",
                 @"Listen to the quiet voice",
                 @"Lost in useless territory",
                 @"Ask people to work against their better judgement",
                 @"Do something boring",
                 @"Decorate, decorate",
                 @"Discover the recipes you are using and abandon them",
                 @"Emphasize differences",
                 @"Change nothing and continue with immaculate consistency",
                 @"Is it finished?",
                 @"Cluster analysis",
                 @"Convert a melodic element into a rhythmic element",
                 @"Disciplined self-indulgence",
                 @"Be dirty",
                 @"In total darkness, or in a very large room, very quietly",
                 @"Assemble some of the elements in a group and treat the group",
                 @"Always give yourself credit for having more than personality",
                 @"Repetition is a form of change",
                 @"Don't be frightened of cliches",
                 @"Use an unacceptable color",
                 @"Are there sections? Consider transitions",
                 @"Make a sudden, destructive unpredictable action; incorporate",
                 @"Mute and continue",
                 @"Is there something missing?",
                 @"Think of the radio",
                 @"Remember those quiet evenings",
                 @"From nothing to more than nothing",
                 @"Faced with a choice, do both",
                 @"What are the sections sections of? Imagine a caterpillar moving",
                 @"Give the game away",
                 @"Don't be frightened to display your talents",
                 @"Infinitesimal gradations",
                 @"Imagine the piece as a set of disconnected events",
                 @"Emphasize repetitions",
                 @"Do the washing up",
                 @"Left channel, right channel, centre channel",
                 @"Would anybody want it?",
                 @"Reverse",
                 @"Look closely at the most embarrassing details and amplify them",
                 @"Overtly resist change",
                 @"Cut a vital connection",
                 @"You are an engineer",
                 @"Remove specifics and convert to ambiguities",
                 @"Change instrument roles",
                 nil];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



//HIDE STATUS BAR
-(BOOL)prefersStatusBarHidden{
    return YES;
}

//RECOGNIZE SHAKE
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (UIEventSubtypeMotionShake) {    [self nextText];    }
}

//HANDLE TAP, IF REPORTING SHIFT DOWN, ELSE NEXT TEXT
- (IBAction)nextOne:(id)sender {
    if(reporting){  [self shiftDown];   }
    else        {   [self nextText];    }
}


//////////* PULL NEXT ENTRY FROM PARSE *//////////
-(void) nextText{
    
    //INIT SCREEN
    self.descriptionLabel.text = @"";
    self.text.text = @"";
    self.text.textColor = [UIColor whiteColor];
    self.text.lineBreakMode = NSLineBreakByWordWrapping;
    self.text.numberOfLines = 2;
    
    
    
    //GET INDEX FOR NEW OBJECT (GET INDEX OF MOST RECENT [MAX], SELECT RANDOM INDEX 0-MAX)
    //SET LIMIT FOR INDEX. USE ONLY NEWEST 200? USE RANDOM TO FIND TOP 200     //master.limit = 200;
    //ADD LOCATION FILTERING? WHEREKEY:NEARGEOPOINT:WITHINMILES
    PFQuery *master = [PFQuery queryWithClassName:@"text"];
    [master orderByDescending:@"createdAt"];
    [master getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        int maxIndex = [object[@"index"] intValue] + 1;
        int randomIndex = arc4random() % maxIndex;
        NSString *stringRandomIndex = [NSString stringWithFormat:@"%d", randomIndex];
        
        //QUERY FOR TEXT WITH RANDOM INDEX
        PFQuery *textQuery = [PFQuery queryWithClassName:@"text"];
        [textQuery whereKey:@"index" equalTo:stringRandomIndex];
        [textQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                [stringIndexOfTextOnScreen isEqualToString:stringRandomIndex];
                PFObject *text = [textQuery getFirstObject];
                NSString *string = text[@"textForYou"];
                if ([string isEqualToString:@"Use an unacceptable color"]) { self.text.textColor = [self randomColor]; } //EASTER EGG
                self.text.text = string;
            } else {
                //NO MATCHING INDEX FOUND, CALL RECURSIVELY
                [self nextText];
                NSLog(@"Error");
            }
        }];
    }];
}


//RANDOM COLOR
- (UIColor *)randomColor {
    Color randomColor = _colors[arc4random_uniform(12)];
    return [UIColor colorWithRed:(randomColor.red / 255.0f) green:(randomColor.green / 255.0f) blue:(randomColor.blue / 255.0f) alpha:1.0f];
}


//UNWIND SEGUE
-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
}

//REPORTING
- (void)longPress:(UILongPressGestureRecognizer*)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if(reporting){
            [self shiftDown];
        }
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"])
        {
            [self shiftUp];
            
        }
    }
}

//REPORTING --> SHIFT UP
- (void)shiftUp{
    [UIView animateWithDuration:0.5 animations:^{
        // set new position of label which it will animate to
        self.text.frame = CGRectMake(self.text.frame.origin.x, self.text.frame.origin.y - 80, self.text.frame.size.width, self.text.frame.size.height);
        self.effectView.frame = CGRectMake(self.effectView.frame.origin.x, self.effectView.frame.origin.y - 80, self.effectView.frame.size.width, self.effectView.frame.size.height);
        self.reportButton.frame = CGRectMake(self.reportButton.frame.origin.x, self.reportButton.frame.origin.y - 80, self.reportButton.frame.size.width, self.reportButton.frame.size.height);
    }];
    reporting = YES;
}

//REPORTING --> SHIFT DOWN
- (void)shiftDown{
    [UIView animateWithDuration:0.5 animations:^{
        // set new position of label which it will animate to
        self.text.frame = CGRectMake(self.text.frame.origin.x, self.text.frame.origin.y + 80, self.text.frame.size.width, self.text.frame.size.height);
        self.effectView.frame = CGRectMake(self.effectView.frame.origin.x, self.effectView.frame.origin.y + 80, self.effectView.frame.size.width, self.effectView.frame.size.height);
        self.reportButton.frame = CGRectMake(self.reportButton.frame.origin.x, self.reportButton.frame.origin.y + 80, self.reportButton.frame.size.width, self.reportButton.frame.size.height);
    }];
    reporting = NO;
}


//HANDLE REPORT
- (IBAction)reportButtonAction:(id)sender {
    PFQuery *query = [PFQuery queryWithClassName:@"text"];
    [query whereKey:@"textForYou" equalTo:self.text.text];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!object) {
            NSLog(@"The getFirstObject request failed.");
        } else {
            [object incrementKey:@"reports" byAmount:[NSNumber numberWithInt:1]];
            [object saveInBackground];
        }
    }];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reported"
                                                    message:@"You have reported this entry"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [self shiftDown];
    [self nextText];
}



//CHECK FOR INTERNET CONNECTIVITY
- (void)testInternetConnection
{
    internetReachableFoo = [Reachability reachabilityWithHostname:@"www.google.com"];

    //INTERNET CONNECTION
    internetReachableFoo.reachableBlock = ^(Reachability*reach)
    {
        // Update the UI on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Yayyy, we have the interwebs!");
        });
    };
    
    //NO INTERNET CONNECTION
    internetReachableFoo.unreachableBlock = ^(Reachability*reach)
    {
        // Update the UI on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Someone broke the internet :(");
        });
    };
    
    [internetReachableFoo startNotifier];
}

//HANDLE NO INTERNET (MAYBE DIFFERENT SCREEN) IF NO INTERNET, DON'T REPORT. HANDLE THIS
//TO BE IMPLEMENTED
-(void)noInternet{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot connect"
                                                    message:@"There is no internet connection"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}


//SPIN ANIMATION
- (void) runSpinAnimationOnView:(UIView*)view duration:(CGFloat)duration rotations:(CGFloat)rotations repeat:(float)repeat;
{
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * rotations * duration ];
    rotationAnimation.duration = duration;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = repeat;
    
    [view.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

@end
