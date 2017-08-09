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
- (void)pluginInitialize {
    
    __weak CDVGaodeLocation *weakSelf = self;
    self.completionBlock = ^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        if (error != nil && error.code == AMapLocationErrorLocateFailed)
        {
            //定位错误：此时location和regeocode没有返回值，不进行annotation的添加
            NSString *errorInfo = [[NSString alloc] initWithFormat:@"定位错误:{%ld - %@};", (long)error.code, error.localizedDescription];
            NSLog(@"%@", errorInfo);
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorInfo];
            [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:weakSelf.currentCallbackId];
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
            NSString *errorInfo = [[NSString alloc] initWithFormat:@"逆地理错误:{%ld - %@};", (long)error.code, error.localizedDescription];
            NSLog(@"%@", errorInfo);
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorInfo];
            [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:weakSelf.currentCallbackId];
        }
        else if (error != nil && error.code == AMapLocationErrorRiskOfFakeLocation)
        {
            //存在虚拟定位的风险：此时location和regeocode没有返回值，不进行annotation的添加
            NSString *errorInfo = [[NSString alloc] initWithFormat:@"存在虚拟定位的风险:{%ld - %@};", (long)error.code, error.localizedDescription];
            NSLog(@"%@", errorInfo);
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorInfo];
            [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:weakSelf.currentCallbackId];
            return;
        }
        else
        {
            NSNumber *latitude =  [[NSNumber alloc] initWithDouble:location.coordinate.latitude];
            NSNumber *longitude = [[NSNumber alloc] initWithDouble:location.coordinate.longitude];
            //没有错误：location有返回值，regeocode是否有返回值取决于是否进行逆地理操作，进行annotation的添加
            NSMutableDictionary *locationInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"latitude", [latitude stringValue], @"longitude", [longitude stringValue], nil];
            
            if (regeocode) {
                [locationInfo setValue:regeocode.formattedAddress forKey:@"address"];
                [locationInfo setValue:regeocode.country forKey:@"country"];
                [locationInfo setValue:regeocode.province forKey:@"province"];
                [locationInfo setValue:regeocode.city forKey:@"city"];
                [locationInfo setValue:regeocode.district forKey:@"district"];
            }
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:locationInfo];
            [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:weakSelf.currentCallbackId];
        }
    };
}

- (void)getLocation:(CDVInvokedUrlCommand *)command {
    NSDictionary *iosPara;
    NSDictionary *para = [command.arguments objectAtIndex:0];
    if ((NSNull *)para == [NSNull null]) {
        para = nil;
    } else {
        iosPara = [para objectForKey:@"ios"];
    }
    self.currentCallbackId = command.callbackId;
    // Accuracy map
    NSDictionary *accuracyMap = [[NSDictionary alloc] initWithObjectsAndKeys:@"1", [NSNumber numberWithDouble:kCLLocationAccuracyBest], @"2", [NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters], @"3", [NSNumber numberWithDouble:kCLLocationAccuracyHundredMeters], @"4", [NSNumber numberWithDouble:kCLLocationAccuracyKilometer], @"5", [NSNumber numberWithDouble:kCLLocationAccuracyThreeKilometers], nil];
    
    // 初始化Key
    NSString *key = [[self.commandDelegate settings] objectForKey:@"ioskey"];
    [AMapServices sharedServices].apiKey = key;
    self.locationManager = [[AMapLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    // 设置期望定位精度
    NSString *accuracyKey;
    if ([iosPara objectForKey:@"accuracy"] != nil) {
        accuracyKey = [[iosPara objectForKey:@"accuracy"] stringValue];
    }
    CLLocationAccuracy accuracy = accuracyKey != nil ? [[accuracyMap objectForKey:accuracyKey] doubleValue] : Gaode_DefaultAccuacy;
    [self.locationManager setDesiredAccuracy:accuracy];
    // 设置不允许系统暂停定位
    [self.locationManager setPausesLocationUpdatesAutomatically:[[iosPara objectForKey:@"enablePausesLocationUpdatesAutomatically"] boolValue] | NO];
    // 设置允许在后台定位
    [self.locationManager setAllowsBackgroundLocationUpdates:[[iosPara objectForKey:@"enableAllowsBackgroundLocationUpdates"] boolValue] | YES];
    // 定位超时时间，最低2s，此处设置为10s
    NSInteger locationTimeout = [[iosPara objectForKey:@"locationTimeout"] intValue] | Gaode_DefaultLocationTimeout;
    [self.locationManager setLocationTimeout:locationTimeout];
    // 逆地理请求超时时间，最低2s，此处设置为10s
    NSInteger reGeocodeTimeout = [[iosPara objectForKey:@"reGeocodeTimeout"] intValue] | Gaode_DefaultReGeocodeTimeout;
    [self.locationManager setReGeocodeTimeout:reGeocodeTimeout];
    // 设置开启虚拟定位风险监测，可以根据需要开启
    [self.locationManager setDetectRiskOfFakeLocation:[[iosPara objectForKey:@"enableDetectRiskOfFakeLocation"] boolValue] | NO];
    // 带逆地理（返回坐标和地址信息）。将下面代码中的 YES 改成 NO ，则不会返回地址信息。
    BOOL needAddress = [[iosPara objectForKey:@"needAddress"] boolValue] | YES;
    [self.locationManager requestLocationWithReGeocode:needAddress completionBlock:self.completionBlock];
}

@end
