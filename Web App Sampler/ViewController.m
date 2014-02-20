//
//  ViewController.m
//  Web App Sampler
//
//  Created by Jeremy White on 2/19/14.
//  Copyright (c) 2014 Connect SDK. All rights reserved.
//

#import "ViewController.h"
#import <ConnectSDK/ConnectSDK.h>

@interface ViewController () <UITextFieldDelegate, DevicePickerDelegate, ConnectableDeviceDelegate>
{
    DiscoveryManager *_discoveryManager;
    DevicePicker *_devicePicker;
    ConnectableDevice *_device;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    if (!_devicePicker)
    {
        _devicePicker = [_discoveryManager devicePicker];
        [_devicePicker setDelegate:self];
    }
    
    [_devicePicker showPicker:sender];
}

- (IBAction)hSend:(id)sender {
    if (self.messageTextField.text.length == 0)
        return;
    
    [_device.webAppLauncher sendText:self.messageTextField.text success:nil failure:nil];
    
    [self hFocusLost:nil];
    self.messageTextField.text = @"";
}

- (IBAction)hFocusLost:(id)sender {
    [self.messageTextField resignFirstResponder];
}

- (void) enableFunctions
{
    self.launchButton.enabled = NO;
    self.sendButton.enabled = YES;
    self.messageTextField.enabled = YES;
}

- (void) disableFunctions
{
    [self hFocusLost:nil];
    
    self.launchButton.enabled = YES;
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
    _device = device;
    _device.delegate = self;
    [_device connect];
}

- (void)devicePicker:(DevicePicker *)picker didCancelWithError:(NSError *)error
{
    // do nothing
}

#pragma mark - ConnectableDeviceDelegate methods

- (void)connectableDeviceReady:(ConnectableDevice *)device
{
    self.launchButton.enabled = NO;
    
    [_device.webAppLauncher launchWebApp:@"6F8A4929" success:^(LaunchSession *launchSession) {
        [self enableFunctions];
    } failure:^(NSError *error) {
        self.launchButton.enabled = YES;
    }];
}

- (void)connectableDevice:(ConnectableDevice *)device capabilitiesAdded:(NSArray *)added removed:(NSArray *)removed
{
    // do nothing
}

- (void)connectableDeviceDisconnected:(ConnectableDevice *)device withError:(NSError *)error
{
    [self disableFunctions];
}

@end
