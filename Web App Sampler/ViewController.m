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
#import <ConnectSDK/AirPlayService.h>

#define QuickLog(s,...) [self quickLog:(s),##__VA_ARGS__]

@interface ViewController () <UITextFieldDelegate, ConnectableDeviceDelegate, WebAppSessionDelegate, DevicePickerDelegate>
{
    DiscoveryManager *_discoveryManager;
    DevicePicker *_devicePicker;
    
    NSMutableDictionary *_devices;
    NSMutableDictionary *_webAppSessions;
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
    
    [AirPlayService setAirPlayServiceMode:AirPlayServiceModeWebApp];
    
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
        _devicePicker.delegate = self;
    }
    
    [_devicePicker showPicker:sender];
}

- (IBAction)hClose:(id)sender {
    [self hFocusLost:nil];
    
    if (!_webAppSessions)
        return;
    
    QuickLog(@"ViewController::hClose trying to close web app");
    
    [_webAppSessions enumerateKeysAndObjectsUsingBlock:^(NSString *address, WebAppSession *webAppSession, BOOL *stop) {
        [webAppSession closeWithSuccess:^(id responseObject) {
            QuickLog(@"ViewController::hClose web app closed");
            
            ConnectableDevice *device = _devices[address];
            
            if (device)
            {
                device.delegate = nil;
                [device disconnect];
                [_devices removeObjectForKey:address];
            }
        } failure:^(NSError *error) {
            QuickLog(@"ViewController::hClose could not close web app");
        }];
    }];
    
    [self disableFunctions];
}

- (IBAction)hSend:(id)sender {
    if (self.messageTextField.text.length == 0)
        return;
    
    NSString *messageText = self.messageTextField.text;
    
    QuickLog(@"ViewController::hSend trying to send message: %@", messageText);
    
    [_webAppSessions enumerateKeysAndObjectsUsingBlock:^(id key, WebAppSession *webAppSession, BOOL *stop) {
        [webAppSession sendText:messageText success:^(id responseObject) {
            QuickLog(@"ViewController::hSend message sent!");
        } failure:^(NSError *error) {
            QuickLog(@"ViewController::hSend message could not be sent: %@", error.localizedDescription);
        }];
    }];
    
    self.messageTextField.text = @"";
    [self hFocusLost:nil];
}

- (IBAction)hFocusLost:(id)sender {
    [self.messageTextField resignFirstResponder];
}

#pragma mark - DevicePickerDelegate

- (void)devicePicker:(DevicePicker *)picker didSelectDevice:(ConnectableDevice *)device
{
    // do nothing
}

- (void)devicePicker:(DevicePicker *)picker didCancelWithError:(NSError *)error
{
    if (_devices)
    {
        [_devices enumerateKeysAndObjectsUsingBlock:^(id key, ConnectableDevice *device, BOOL *stop) {
            device.delegate = nil;
            [device disconnect];
        }];
    }
    
    _devices = [NSMutableDictionary new];
    _webAppSessions = [NSMutableDictionary new];
    
    [[_discoveryManager compatibleDevices] enumerateKeysAndObjectsUsingBlock:^(id key, ConnectableDevice *device, BOOL *stop) {
        device.delegate = self;
        [device connect];
        
        _devices[device.address] = device;
    }];
    
    [self enableFunctions];
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
    
    [self.messageTextField addTarget:self action:@selector(handleTextFieldValueChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void) disableFunctions
{
    [self hFocusLost:nil];
    
    self.launchButton.enabled = YES;
    self.closeButton.enabled = NO;
    self.sendButton.enabled = NO;
    self.messageTextField.enabled = NO;
    
    [self.messageTextField removeTarget:self action:@selector(handleTextFieldValueChange:) forControlEvents:UIControlEventEditingChanged];
}

#pragma mark - UITextFieldDelegate methods

- (void) handleTextFieldValueChange:(UITextField *)textField
{
    [_webAppSessions enumerateKeysAndObjectsUsingBlock:^(id key, WebAppSession *webAppSession, BOOL *stop) {
        [webAppSession sendText:textField.text success:^(id responseObject) {
            QuickLog(@"ViewController::hSend message sent!");
        } failure:^(NSError *error) {
            QuickLog(@"ViewController::hSend message could not be sent: %@", error.localizedDescription);
        }];
    }];
}

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

#pragma mark - ConnectableDeviceDelegate methods

- (void)connectableDeviceReady:(ConnectableDevice *)device
{
    QuickLog(@"ViewController::connectableDeviceReady launching app");
    
    NSString *webAppId;
    
    if ([device serviceWithName:@"Chromecast"])
        webAppId = @"4F6217BC";
    else if ([device serviceWithName:@"webOS TV"])
        webAppId = @"SampleWebApp";
    else if ([device serviceWithName:@"AirPlay"])
        webAppId = @"http://ec2-54-201-108-205.us-west-2.compute.amazonaws.com/samples/connect-bridge/";
    
    if (!webAppId)
        return;
    
    [device.webAppLauncher launchWebApp:webAppId success:^(WebAppSession *webAppSession) {
        QuickLog(@"ViewController::connectableDeviceReady app successfully launched");
        
        _webAppSessions[device.address] = webAppSession;
        
        [webAppSession connectWithSuccess:^(id responseObject)
        {
            webAppSession.delegate = self;
            QuickLog(@"ViewController::connectableDeviceReady successfully connected to app");
        } failure:^(NSError *error)
        {
            QuickLog(@"ViewController::connectableDeviceReady failed to connect to app %@", error.localizedDescription);
        }];
    } failure:^(NSError *error) {
        QuickLog(@"ViewController::connectableDeviceReady app failed to launch %@", error.localizedDescription);
    }];
    
    [self enableFunctions];
}

- (void)connectableDeviceDisconnected:(ConnectableDevice *)device withError:(NSError *)error
{
    QuickLog(@"ViewController::connectableDeviceDisconnected:withError: %@", error);
}

#pragma mark - WebAppSessionDelegate

- (void)webAppSession:(WebAppSession *)webAppSession didReceiveMessage:(id)message
{
    QuickLog(@"ViewController::connectableDeviceReady received message from device: %@", message);
}

- (void)webAppSessionDidDisconnect:(WebAppSession *)webAppSession
{
}

@end
