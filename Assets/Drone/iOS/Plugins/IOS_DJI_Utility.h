//
//  IOS_DJI_Utility.h
//  

#import <Foundation/Foundation.h>
#import <DJISDK/DJISDK.h>

NS_ASSUME_NONNULL_BEGIN

@class DJIBaseProduct;
@class DJIAircraft;
@class DJIGimbal;
@class DJIFlightController;

@interface IOS_DJI_Utility : NSObject
+(DJIBaseProduct*) fetchProduct;
+(DJIAircraft*) fetchAircraft;
+(DJIFlightController*) fetchFlightController;
+(DJICamera*) fetchCamera;
@end

NS_ASSUME_NONNULL_END
