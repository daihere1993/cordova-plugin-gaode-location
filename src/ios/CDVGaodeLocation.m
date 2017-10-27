/*
 * @Author: 玖叁(N.T) 
 * @Date: 2017-10-25 17:37:18 
 * @Last Modified by:   玖叁(N.T) 
 * @Last Modified time: 2017-10-25 17:37:18 
 */

#import "CDVGaodeLocation.h"
#import <AMapFoundationKit/AMapFoundationKit.h>

#define DefaultLocationTimeout 2
#define DefaultReGeocodeTimeout 5

@interface CDVGaodeLocation () <AMapLocationManagerDelegate>

@property (nonatomic, copy) AMapLocatingCompletionBlock completionBlock;

@end

@implementation CDVGaodeLocation


#pragma mark "API"

- (void)pluginInitialize {
    // 初始化Key
    NSString *key = [[self.commandDelegate settings] objectForKey:@"gaodekey"];
    key = [key substringFromIndex:5];
    [AMapServices sharedServices].apiKey = key;
    
    [self initCompleteBlock];
}

- (void)configLocationManager:(CDVInvokedUrlCommand *)command {
    NSDictionary *iosPara;
    NSDictionary *param = [command.arguments objectAtIndex:0];
    
    if ((NSNull *)param == [NSNull null]) {
        param = nil;
    } else {
        iosPara = [param objectForKey:@"ios"];
    }
    
    if ([param objectForKey:@"appName"]) {
        self.appName = [param objectForKey:@"appName"];
    } else {
        self.appName = @"当前应用";
    }
    
    self.locationManager = [[AMapLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    
    // 设置期望的定位精度
    CLLocationAccuracy accuracy = kCLLocationAccuracyHundredMeters;
    NSString *accuracyCode = [iosPara objectForKey:@"accuracy"];
    
    if ([accuracyCode isEqualToString:@"1"]) {
        accuracy = kCLLocationAccuracyBestForNavigation;
    } else if ([accuracyCode isEqualToString:@"2"]) {
        accuracy = kCLLocationAccuracyBest;
    } else if ([accuracyCode isEqualToString:@"3"]) {
        accuracy = kCLLocationAccuracyNearestTenMeters;
    } else if ([accuracyCode isEqualToString:@"4"]) {
        accuracy = kCLLocationAccuracyHundredMeters;
    } else if ([accuracyCode isEqualToString:@"5"]) {
        accuracy = kCLLocationAccuracyKilometer;
    } else if ([accuracyCode isEqualToString:@"6"]) {
        accuracy = kCLLocationAccuracyThreeKilometers;
    }
    [self.locationManager setDesiredAccuracy:accuracy];
    
    // 设置是否允许系统暂停定位
    [self.locationManager setPausesLocationUpdatesAutomatically:NO];
    
    // 设置是否允许后台定位
    [self.locationManager setAllowsBackgroundLocationUpdates:NO];
    
    // 设置定位超时时间
    NSInteger locationTimeout;
    if ([iosPara objectForKey:@"locationTimeout"]) {
        locationTimeout = [[iosPara objectForKey:@"locationTimeout"] integerValue];
    } else {
        locationTimeout = DefaultLocationTimeout;
    }
    [self.locationManager setLocationTimeout:locationTimeout];
    
    //设置逆地址超时时间
    NSInteger reGeoCodeTimeout;
    if ([iosPara objectForKey:@"reGeoCodeTimeout"]) {
        reGeoCodeTimeout = [[iosPara objectForKey:@"reGeoCodeTimeout"] integerValue];
    } else {
        reGeoCodeTimeout = DefaultReGeocodeTimeout;
    }
    [self.locationManager setReGeocodeTimeout:reGeoCodeTimeout];
    
    [self successWithCallbackID:command.callbackId];
}

- (void)getLocation:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        self.currentCallbackId = command.callbackId;
        
        NSDictionary *param = [command.arguments objectAtIndex:0];
        
        if ([[param objectForKey:@"retGeo"] boolValue] == YES) {
            [self reGeocodeAction];
        } else {
            [self locAction];
        }
    }];
    
}

- (void)reGeocodeAction
{
    //进行单次带逆地理定位请求
    [self.locationManager requestLocationWithReGeocode:YES completionBlock:self.completionBlock];
}

- (void)locAction {
    // 进行单次定位
    [self.locationManager requestLocationWithReGeocode:NO completionBlock:self.completionBlock];
}

- (void)initCompleteBlock {
    __weak CDVGaodeLocation *weakSelf = self;
    self.completionBlock = ^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error)
    {
        if (error != nil && error.code == AMapLocationErrorLocateFailed)
        {
            [weakSelf showLoctionSettingAlert];
            //定位错误：此时location和regeocode没有返回值，不进行annotation的添加
            NSLog(@"定位错误:{%ld - %@};", (long)error.code, error.localizedDescription);
            return;
        }
        else if (error != nil
                 && (error.code == AMapLocationErrorReGeocodeFailed
                     || error.code == AMapLocationErrorTimeOut
                     || error.code == AMapLocationErrorCannotFindHost
                     || error.code == AMapLocationErrorBadURL
                     || error.code == AMapLocationErrorNotConnectedToInternet
                     || error.code == AMapLocationErrorCannotConnectToHost))
        {
            //逆地理错误：在带逆地理的单次定位中，逆地理过程可能发生错误，此时location有返回值，regeocode无返回值，进行annotation的添加
            NSString *errorMsg = [NSString stringWithFormat:@"逆地理错误:{%ld - %@};", (long)error.code, error.localizedDescription];
            [weakSelf failWithCallbackID:weakSelf.currentCallbackId withMessage:errorMsg];
            NSLog(@"%@", errorMsg);
        } else if (error != nil && error.code == AMapLocationErrorRiskOfFakeLocation) {
            NSString *errorMsg = [NSString stringWithFormat:@"存在虚拟定位的风险:{%ld - %@};", (long)error.code, error.localizedDescription];
            [weakSelf failWithCallbackID:weakSelf.currentCallbackId withMessage:errorMsg];
            //存在虚拟定位的风险：此时location和regeocode没有返回值，不进行annotation的添加
            NSLog(@"%@", errorMsg);
            return;
        }
        
        NSNumber *latitude = [[NSNumber alloc] initWithDouble:location.coordinate.latitude];
        NSNumber *longitude = [[NSNumber alloc] initWithDouble:location.coordinate.longitude];
        weakSelf.locationInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[latitude stringValue], @"latitude", [longitude stringValue], @"longitude", nil];
        
        //修改label显示内容
        if (regeocode) {
            [weakSelf.locationInfo setValue:regeocode.formattedAddress forKey:@"address"];
            [weakSelf.locationInfo setValue:regeocode.country forKey:@"country"];
            [weakSelf.locationInfo setValue:regeocode.province forKey:@"province"];
            [weakSelf.locationInfo setValue:regeocode.city forKey:@"city"];
            [weakSelf.locationInfo setValue:regeocode.district forKey:@"district"];
            
            NSLog(@"地址信息：%@", [NSString stringWithFormat:@"%@ \n %@-%@-%.2fm", regeocode.formattedAddress,regeocode.citycode, regeocode.adcode, location.horizontalAccuracy]);
        } else {
            [weakSelf.locationInfo setValue:[NSString stringWithFormat:@"%.2fm", location.horizontalAccuracy] forKey:@"accuracy"];
            
            NSLog(@"经纬度：%@", [NSString stringWithFormat:@"lat:%f;lon:%f \n accuracy:%.2fm", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy]);
        }
        
        [weakSelf successWithCallbackID:weakSelf.currentCallbackId withDictionary:weakSelf.locationInfo];
    };
}

- (void)showLoctionSettingAlert {
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
