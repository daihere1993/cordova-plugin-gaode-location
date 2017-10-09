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
    NSLog(@"%s, amapLocationManager = %@, error = %@", __func__, [manager class], error);
}

- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location reGeocode:(AMapLocationReGeocode *)reGeocode {
    NSNumber *latitude = [[NSNumber alloc] initWithDouble:location.coordinate.latitude];
    NSNumber *longitude = [[NSNumber alloc] initWithDouble:location.coordinate.longitude];
    
    NSMutableDictionary *locationInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[latitude stringValue], @"latitude", [longitude stringValue], @"longitude", nil];
    
    BOOL isReGeocoding = manager.locatingWithReGeocode;
    
    if (!reGeocode && isReGeocoding) {
        return;
    }

    if (reGeocode) {
        [locationInfo setValue:reGeocode.formattedAddress forKey:@"address"];
        [locationInfo setValue:reGeocode.country forKey:@"country"];
        [locationInfo setValue:reGeocode.province forKey:@"province"];
        [locationInfo setValue:reGeocode.city forKey:@"city"];
        [locationInfo setValue:reGeocode.district forKey:@"district"];
    }
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:locationInfo];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.currentCallbackId];
}

@end
