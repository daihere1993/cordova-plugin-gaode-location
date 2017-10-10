#import "CDVGaodeLocation.h"
#import <AMapFoundationKit/AMapFoundationKit.h>

#define Gaode_DefaultLocationTimeout 2
#define Gaode_DefaultReGeocodeTimeout 2
#define Gaode_DefaultAccuacy kCLLocationAccuracyHundredMeters

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
        if ((NSNull *)para == [NSNull null]) {
            para = nil;
        } else {
            iosPara = [para objectForKey:@"ios"];
        }
        
        self.currentCallbackId = command.callbackId;
        
        // 初始化Key
        NSString *key = [[self.commandDelegate settings] objectForKey:@"ioskey"];
        [AMapServices sharedServices].apiKey = key;
        
        AMapLocationManager *locationManager = [[AMapLocationManager alloc] init];
        [locationManager setDelegate:self];
        // 设置定位最小更新距离，单位米
        double updateDistance;
        if ([iosPara objectForKey:@"updateDistance"]) {
            updateDistance = [[iosPara objectForKey:@"updateDistance"] doubleValue];
        } else {
            updateDistance = 200;
        }
        
        [locationManager setDistanceFilter:updateDistance];
        // 设置是否返回逆地址编码信息
        BOOL needsAddress;
        if ([iosPara objectForKey:@"needsAddress"]) {
            needsAddress = [[iosPara objectForKey:@"needsAddress"] boolValue];
        } else {
            needsAddress = NO;
        }
        [locationManager setLocatingWithReGeocode:needsAddress];
        // 开启持续定位
        [locationManager startUpdatingLocation];
    }];
}

#pragma mark - AMapLocationManager Delegate

- (void)amapLocationManager:(AMapLocationManager *)manager didFailWithError:(NSError *)error {
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
