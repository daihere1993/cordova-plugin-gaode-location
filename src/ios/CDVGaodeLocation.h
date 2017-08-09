#import <Cordova/CDV.h>
#import <AMapLocationKit/AMapLocationKit.h>

@interface CDVGaodeLocation : CDVPlugin <AMapLocationManagerDelegate>

@property (nonatomic, strong) NSString *currentCallbackId;
@property (nonatomic, strong) AMapLocationManager *locationManager;

- (void)getLocation:(CDVInvokedUrlCommand *)command;

@end
