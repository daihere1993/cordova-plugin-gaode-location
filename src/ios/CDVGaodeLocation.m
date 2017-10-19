#import "CDVGaodeLocation.h"
#import <AMapFoundationKit/AMapFoundationKit.h>

@interface CDVGaodeLocation () <AMapLocationManagerDelegate>

@property (nonatomic, copy) AMapLocatingCompletionBlock completionBlock;

@end

@implementation CDVGaodeLocation

#pragma mark "API"

- (void)getLocation:(CDVInvokedUrlCommand *)command {
    self.currentCallbackId = command.callbackId;
    
    if (!self.isStartUpdateLocation) {
        [self failWithCallbackID:command.callbackId withMessage:@"Please invoke 'startUpdateLocation' first."];
    } else {
        [self successWithCallbackID:command.callbackId withDictionary:self.locationInfo];
    }
}

- (void)startUpdateLocation:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        
        NSDictionary *iosPara;
        NSDictionary *para = [command.arguments objectAtIndex:0];
        if ([para objectForKey:@"appName"]) {
            self.appName = [para objectForKey:@"appName"];
        } else {
            self.appName = @"当前应用";
        }
        if ((NSNull *)para == [NSNull null]) {
            para = nil;
        } else {
            iosPara = [para objectForKey:@"ios"];
        }
        
        self.currentCallbackId = command.callbackId;
        
        // 初始化Key
        NSString *key = [[self.commandDelegate settings] objectForKey:@"gaodekey"];
        key = [key substringFromIndex:5];
        [AMapServices sharedServices].apiKey = key;
        
        self.locationManager = [[AMapLocationManager alloc] init];
        [self.locationManager setDelegate:self];
        // 设置定位最小更新距离，单位米
        double updateDistance;
        if ([iosPara objectForKey:@"updateDistance"]) {
            updateDistance = [[iosPara objectForKey:@"updateDistance"] doubleValue];
        } else {
            updateDistance = 200;
        }
        
        [self.locationManager setDistanceFilter:updateDistance];
        // 设置是否返回逆地址编码信息
        BOOL needsAddress;
        if ([iosPara objectForKey:@"needsAddress"]) {
            needsAddress = [[iosPara objectForKey:@"needsAddress"] boolValue];
        } else {
            needsAddress = NO;
        }
        [self.locationManager setLocatingWithReGeocode:needsAddress];
        // 开启持续定位
        [self.locationManager startUpdatingLocation];
    }];
}

#pragma mark - AMapLocationManager Delegate

- (void)amapLocationManager:(AMapLocationManager *)manager didFailWithError:(NSError *)error {
    if (error.code == 1) {
        NSString *alertTitle = @"定位服务已关闭";
        NSString *alertMessage = [NSString stringWithFormat:@"请到设置->隐私->定位服务中，开启【%@】对应的定位服务", self.appName];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            
            [[UIApplication sharedApplication]openURL:settingsURL];
        }];
        [alert addAction:cancelAction];
        [alert addAction:okAction];
        
        UIViewController *viewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
        if ( viewController.presentedViewController && !viewController.presentedViewController.isBeingDismissed ) {
            viewController = viewController.presentedViewController;
        }
        
        NSLayoutConstraint *constraint = [NSLayoutConstraint
                                          constraintWithItem:alert.view
                                          attribute:NSLayoutAttributeHeight
                                          relatedBy:NSLayoutRelationLessThanOrEqual
                                          toItem:nil
                                          attribute:NSLayoutAttributeNotAnAttribute
                                          multiplier:1
                                          constant:viewController.view.frame.size.height*2.0f];
        
        [alert.view addConstraint:constraint];
        [viewController presentViewController:alert animated:YES completion:^{}];
    }
    [self failWithCallbackID:self.currentCallbackId withMessage:@"Get location fail."];
}

- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location reGeocode:(AMapLocationReGeocode *)reGeocode {
    NSNumber *latitude = [[NSNumber alloc] initWithDouble:location.coordinate.latitude];
    NSNumber *longitude = [[NSNumber alloc] initWithDouble:location.coordinate.longitude];
    
    self.locationInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[latitude stringValue], @"latitude", [longitude stringValue], @"longitude", nil];
    
    BOOL isReGeocoding = manager.locatingWithReGeocode;
    
    self.isStartUpdateLocation = YES;
    [self successWithCallbackID:self.currentCallbackId];
    
    if (!reGeocode && isReGeocoding) {
        return;
    }

    if (reGeocode) {
        [self.locationInfo setValue:reGeocode.formattedAddress forKey:@"address"];
        [self.locationInfo setValue:reGeocode.country forKey:@"country"];
        [self.locationInfo setValue:reGeocode.province forKey:@"province"];
        [self.locationInfo setValue:reGeocode.city forKey:@"city"];
        [self.locationInfo setValue:reGeocode.district forKey:@"district"];
    }
}

#pragma mark "Private methods"

- (void)successWithCallbackID:(NSString *)callbackID {
    [self successWithCallbackID:callbackID withMessage:@"success"];
}

- (void)successWithCallbackID:(NSString *)callbackID withMessage:(NSString *)message {
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

- (void)successWithCallbackID:(NSString *)callbackID withDictionary:(NSDictionary *)dictionary {
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

- (void)failWithCallbackID:(NSString *)callbackID withError:(NSError *)error {
    [self failWithCallbackID:callbackID withMessage:[error localizedDescription]];
}

- (void)failWithCallbackID:(NSString *)callbackID withMessage:(NSString *)message {
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

@end
