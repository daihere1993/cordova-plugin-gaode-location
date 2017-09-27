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
        [self.locationManager setDistanceFilter:200];
        // 设置是否返回逆地址编码信息
        [self.locationManager setLocatingWithReGeocode:NO];
        // 开启持续定位
        [self.locationManager startUpdatingLocation];
    }];
}

#pragma mark - AMapLocationManager Delegate

- (void)amapLocationManager:(AMapLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"%s, amapLocationManager = %@, error = %@", __func__, [manager class], error);
}

- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location {
    NSNumber *latitude = [[NSNumber alloc] initWithDouble:location.coordinate.latitude];
    NSNumber *longitude = [[NSNumber alloc] initWithDouble:location.coordinate.longitude];
    
    NSMutableDictionary *locationInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[latitude stringValue], @"latitude", [longitude stringValue], @"longitude", nil];
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:locationInfo];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.currentCallbackId];
}

@end
