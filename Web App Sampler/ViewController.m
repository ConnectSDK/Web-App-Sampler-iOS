//
//  ViewController.m
//  Web App Sampler
//
//  Created by Jeremy White on 2/19/14.
//  Connect SDK Sample App by LG Electronics
//
//  To the extent possible under law, the person who associated CC0 with
//  this sample app has waived all copyright and related or neighboring rights
//  to the sample app.
//
//  You should have received a copy of the CC0 legalcode along with this
//  work. If not, see http://creativecommons.org/publicdomain/zero/1.0/.
//

#import "ViewController.h"
#import <ConnectSDK/ConnectSDK.h>

#define QuickLog(s,...) [self quickLog:(s),##__VA_ARGS__]

@interface ViewController () <UITextFieldDelegate, DevicePickerDelegate, ConnectableDeviceDelegate, WebAppSessionDelegate>
{
    DiscoveryManager *_discoveryManager;
    DevicePicker *_devicePicker;
    ConnectableDevice *_device;
    WebAppSession *_webAppSession;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"ViewController::viewDidLoad");
    
    NSArray *webAppCapabilities = @[
                                    kWebAppLauncherLaunch,
                                    kWebAppLauncherMessageSend,
                                    kWebAppLauncherMessageReceive,
                                    kWebAppLauncherClose
                                    ];
    CapabilityFilter *webAppCapabilityFilter = [CapabilityFilter filterWithCapabilities:webAppCapabilities];
    
    _discoveryManager = [DiscoveryManager sharedManager];
    [_discoveryManager setCapabilityFilters:@[webAppCapabilityFilter]];
    [_discoveryManager startDiscovery];
}

- (IBAction)hLaunch:(id)sender {
    [self hFocusLost:nil];

    self.statusTextView.text = @"";

    QuickLog(@"ViewController::hLaunch");
    
    if (!_devicePicker)
    {
        _devicePicker = [_discoveryManager devicePicker];
        [_devicePicker setDelegate:self];
    }
    
    [_devicePicker showPicker:sender];
}

- (IBAction)hClose:(id)sender {
    [self hFocusLost:nil];
    
    if (!_webAppSession)
        return;
    
    QuickLog(@"ViewController::hClose trying to close web app");
    
    [_webAppSession closeWithSuccess:^(id responseObject) {
        QuickLog(@"ViewController::hClose web app closed");
        
        [self disableFunctions];

        _device.delegate = nil;
        [_device disconnect];
        _device = nil;
    } failure:^(NSError *error) {
        QuickLog(@"ViewController::hClose could not close web app");
    }];
}

- (IBAction)hSend:(id)sender {
    if (self.messageTextField.text.length == 0)
        return;
    
    NSString *messageText = self.messageTextField.text;
    
    QuickLog(@"ViewController::hSend trying to send message: %@", messageText);
    
    [_webAppSession sendText:messageText success:^(id responseObject) {
        QuickLog(@"ViewController::hSend message sent!");
    } failure:^(NSError *error) {
        QuickLog(@"ViewController::hSend message could not be sent: %@", error.localizedDescription);
    }];
    
    self.messageTextField.text = @"";
    [self hFocusLost:nil];
}

- (IBAction)hFocusLost:(id)sender {
    [self.messageTextField resignFirstResponder];
}

#pragma mark - Helper methods

- (void) quickLog:(NSString *) format, ...; {
    va_list ap;
    
    va_start(ap, format);
    NSString *logMessage = [[NSString alloc] initWithFormat:format arguments: ap];
    va_end(ap);
    
    NSLog(@"%@", logMessage);
    
    NSString *statusString = [NSString stringWithFormat:@"%@\n%@", logMessage, self.statusTextView.text];
    self.statusTextView.text = statusString;
}

- (void) enableFunctions
{
    self.launchButton.enabled = NO;
    self.closeButton.enabled = YES;
    self.sendButton.enabled = YES;
    self.messageTextField.enabled = YES;
}

- (void) disableFunctions
{
    [self hFocusLost:nil];
    
    _webAppSession = nil;
    self.launchButton.enabled = YES;
    self.closeButton.enabled = NO;
    self.sendButton.enabled = NO;
    self.messageTextField.enabled = NO;
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.text.length > 0)
    {
        [self hSend:nil]; 
        return YES;
    } else
    {
        return NO;
    }
}

#pragma mark - DevicePickerDelegate methods

- (void)devicePicker:(DevicePicker *)picker didSelectDevice:(ConnectableDevice *)device
{
    QuickLog(@"ViewController::devicePicker:didSelectDevice:");
    
    _device = device;
    _device.delegate = self;
    [_device connect];
}

- (void)devicePicker:(DevicePicker *)picker didCancelWithError:(NSError *)error
{
    QuickLog(@"ViewController::devicePicker:didCancelWithError:");
}

#pragma mark - ConnectableDeviceDelegate methods

- (void)connectableDeviceReady:(ConnectableDevice *)device
{
    QuickLog(@"ViewController::connectableDeviceReady launching app");
    
    self.launchButton.enabled = NO;
    
    NSString *webAppId;
    
    if ([_device serviceWithName:@"Chromecast"])
        webAppId = @"4F6217BC";
    else if ([_device serviceWithName:@"webOS TV"])
        webAppId = @"MediaPlayer";
    
    [_device.webAppLauncher launchWebApp:webAppId success:^(WebAppSession *webAppSession) {
        QuickLog(@"ViewController::connectableDeviceReady app successfully launched");
        
        _webAppSession = webAppSession;
        
        [webAppSession connectWithSuccess:^(id responseObject)
        {
            webAppSession.delegate = self;
            QuickLog(@"ViewController::connectableDeviceReady successfully connected to app");

            [self enableFunctions];
        } failure:^(NSError *error)
        {
            QuickLog(@"ViewController::connectableDeviceReady failed to connect to app %@", error.localizedDescription);
        }];
    } failure:^(NSError *error) {
        QuickLog(@"ViewController::connectableDeviceReady app failed to launch %@", error.localizedDescription);
        
        self.launchButton.enabled = YES;
    }];
}

- (void)connectableDeviceDisconnected:(ConnectableDevice *)device withError:(NSError *)error
{
    QuickLog(@"ViewController::connectableDeviceDisconnected:withError: %@", error);
    
    [self disableFunctions];
}

#pragma mark - WebAppSessionDelegate

- (void)webAppSession:(WebAppSession *)webAppSession didReceiveMessage:(id)message
{
    QuickLog(@"ViewController::connectableDeviceReady received message from device: %@", message);
}

- (void)webAppSessionDidDisconnect:(WebAppSession *)webAppSession
{
    [self disableFunctions];
}

@end
