//
//  ViewController.h
//  Web App Sampler
//
//  Created by Jeremy White on 2/19/14.
//  Copyright (c) 2014 Connect SDK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *launchButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet UITextView *statusTextView;

- (IBAction)hLaunch:(id)sender;
- (IBAction)hClose:(id)sender;
- (IBAction)hSend:(id)sender;
- (IBAction)hFocusLost:(id)sender;

@end
