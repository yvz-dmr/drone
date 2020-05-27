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
@property (nonatomic, assign) NSData *byteTex;
@property(nonatomic, weak) DJIBaseProduct* product;
@property(nonatomic, strong) NSString* modelName1;
@property (nonatomic) NSMutableDictionary *GetDroneData;
@property (copy) void (^GetModelNameCallback)(char*);

//video related
@property(nonatomic) UIView* videoPreviewView;
@property (nonatomic, strong) UIViewController *presentedController;
@property (nonatomic, strong) UIViewController *demoViewController;


@end

NS_ASSUME_NONNULL_END
