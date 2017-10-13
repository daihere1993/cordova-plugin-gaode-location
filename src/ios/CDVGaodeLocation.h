#import <Cordova/CDV.h>
#import <AMapLocationKit/AMapLocationKit.h>

@interface CDVGaodeLocation : CDVPlugin <AMapLocationManagerDelegate>

@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSString *currentCallbackId;
@property (nonatomic, strong) AMapLocationManager *locationManager;
@property (nonatomic, strong) NSMutableDictionary *locationInfo;
@property (nonatomic) BOOL isStartUpdateLocation;

- (void)getLocation:(CDVInvokedUrlCommand *)command;
- (void)startUpdateLocation:(CDVInvokedUrlCommand *)command;

@end
