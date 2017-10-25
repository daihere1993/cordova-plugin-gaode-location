/*
 * @Author: 玖叁(N.T) 
 * @Date: 2017-10-25 17:09:54 
 * @Last Modified by: 玖叁(N.T)
 * @Last Modified time: 2017-10-25 17:10:47
 */
#import <Cordova/CDV.h>
#import <AMapLocationKit/AMapLocationKit.h>
 
@interface CDVGaodeLocation : CDVPlugin <AMapLocationManagerDelegate>
 
@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSString *currentCallbackId;
@property (nonatomic, strong) AMapLocationManager *locationManager;
@property (nonatomic, strong) NSMutableDictionary *locationInfo;
 
- (void)getLocation:(CDVInvokedUrlCommand *)command;
- (void)configLocationManager:(CDVInvokedUrlCommand *)command;
 
@end
 
