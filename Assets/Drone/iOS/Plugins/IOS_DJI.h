//
//  iOS_DJI.h
//

#import <Foundation/Foundation.h>
#import <DJISDK/DJISDK.h>
#import <DJIWidget/DJIVideoPreviewer.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DroneDelegate <NSObject>
- (void) appRegisterCalled;
- (void) appRegisterFailed:(NSString * )err;
- (void) appDroneConnected:(DJIBaseProduct *)product;
- (void) appDroneDisConnected;
@end

@interface IOS_DJI : NSObject<DJISDKManagerDelegate, DJIFlightControllerDelegate, DJIVideoFeedListener, DJICameraDelegate, DJIGimbalDelegate>
@property (nonatomic, weak) id <DroneDelegate> delegate;

+ (id)sharedInstance;
- (void)registerApp;
- (void)addDelegate:(id<DroneDelegate>)delegate;
@property (nonatomic) NSDictionary *fromFlightDelegate;
@property (nonatomic) NSDictionary *fromGimbalDelegate;
@property (nonatomic) NSMutableDictionary *GetDroneData;
@end

NS_ASSUME_NONNULL_END
