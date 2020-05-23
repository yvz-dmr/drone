//
//  iOS_DJI.m
//

// Set 1 for running with ios
#define UNITY_BUILD 1

#import <Foundation/Foundation.h>
#import <DJISDK/DJISDK.h>
#import <DJIWidget/DJIVideoPreviewer.h>

#import "IOS_DJI_Native_Core.h"
#import "IOS_DJI_Utility.h"

#if UNITY_BUILD
#import "UnityInterface.h"
#else
#import "IOS_DJI.h"
#endif

#define RADIAN(x) ((x)*M_PI/180.0)

#if UNITY_BUILD
@interface IOS_DJI : NSObject<DJISDKManagerDelegate, DJIFlightControllerDelegate,
DJIVideoFeedListener, DJICameraDelegate, DJIGimbalDelegate>
+ (id) sharedInstance;

@property(nonatomic, strong) NSString* modelName1;
@property(nonatomic, weak) DJIBaseProduct* product;
@property (nonatomic) NSDictionary *fromFlightDelegate;
@property (nonatomic) NSDictionary *fromGimbalDelegate;
@property (nonatomic) NSMutableDictionary *GetDroneData;
@property (nonatomic, assign) NSData *byteTex;
@property (copy) void (^GetModelNameCallback)(char*);

// video related
@property(nonatomic) UIView* videoPreviewView;
@property (nonatomic, strong) UIViewController *presentedController;
@property (nonatomic, strong) UIViewController *DemoViewController;

@end
#endif

@implementation IOS_DJI

static IOS_DJI * _sharedInstance;

+ (id)sharedInstance {
    
    if (_sharedInstance == nil)  {
        _sharedInstance = [[self alloc] init];
    }
    
    return _sharedInstance;
}

- (void)registerApp
{
    /// allocate Dictionary for drone data
    self.GetDroneData = [[NSMutableDictionary alloc]init];
    [[IOS_DJI_NativeUtility sharedInstance] SetLogState:true];
    [DJISDKManager registerAppWithDelegate:self];
}

- (void)appRegisteredWithError:(NSError *)error
{
#if UNITY_BUILD
    if (error) {
        [[IOS_DJI_NativeUtility sharedInstance] NativeLog: [NSString stringWithFormat:@"%@", [error description]]];
        const char * err = [IOS_DJI_DataConvertor NSStringToChar:[NSString stringWithFormat:@"%@", [error description]]];
        UnitySendMessage("IOSDroneBridgeEventListener", "OnRegisterFailed", err);
    }
    else {
        [[IOS_DJI_NativeUtility sharedInstance] NativeLog:@"App Registered Success"];
        [DJISDKManager startConnectionToProduct];
        UnitySendMessage("IOSDroneBridgeEventListener", "OnRegistered", [IOS_DJI_DataConvertor NSStringToChar:@""]);
    }
#else
    if (error) {
        [self.delegate appRegisterFailed:[NSString stringWithFormat:@"%@", [error description]]];
    }else {
        [DJISDKManager enableBridgeModeWithBridgeAppIP:@"192.168.43.43"];
        [self.delegate appRegisterCalled];
    }
#endif
}

- (void)didUpdateDatabaseDownloadProgress:(NSProgress *)progress {
}

- (void)productConnected:(DJIBaseProduct *)product{
    [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"Product Connected"];
#if UNITY_BUILD
    if(product){
        self.product = product;
        self.modelName1 = self.product.model;
        [[IOS_DJI_NativeUtility sharedInstance] NativeLog:@"Model name is this :"];
        [[IOS_DJI_NativeUtility sharedInstance] NativeLog:self.modelName1];
        // Calback with model name
        // self.GetModelNameCallback((char *)[IOS_DJI_DataConvertor NSStringToChar:[NSString stringWithFormat:@"%@", product.model]]);
        
        // fetch drone data
        [self fetchDroneData];
        [self setupVideoStream];
//        [self setupVideoPreviewer];
        
        UnitySendMessage("IOSDroneBridgeEventListener", "OnDroneConnected", [IOS_DJI_DataConvertor NSStringToChar:@""]);
    }
    else {
        UnitySendMessage("IOSDroneBridgeEventListener", "OnDroneDataNotAvailable", [IOS_DJI_DataConvertor NSStringToChar:@"Unable to fetch drone data"]);
    }
#else
    
    if(product){
        /// callback to Example section
        // [self.delegate appDroneConnected:product];
        
        // /// Collect product Instance
        // self.product = product;
        
        // /// Calback with model name
        // self.GetModelNameCallback((char *)[IOS_DJI_DataConvertor NSStringToChar:[NSString stringWithFormat:@"%@", product.model]]);
        
        /// fetch drone data
        [self fetchDroneData];
        [self setupVideoStream];
        [self setupVideoPreviewer];
    }
#endif
}

- (void)productDisconnected {
    [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"Product Disconnected"];
    [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"Video Stream Disconnected"];
    [self removeVideoStream];
#if UNITY_BUILD
    UnitySendMessage("IOSDroneBridgeEventListener", "OnDroneDisconnected", [IOS_DJI_DataConvertor NSStringToChar:@""]);
#else
    [self.delegate appDroneDisConnected];
#endif
}

///MARK:- Connect to Drone
-(void) SetDroneActivate:(BOOL)state withIP: (NSString *)ipAddress {
    if (state) {
        [DJISDKManager enableBridgeModeWithBridgeAppIP:ipAddress];
    }
    else
    {
        [DJISDKManager startConnectionToProduct];
    }
}

#if !UNITY_BUILD
- (void)addDelegate:(id<DroneDelegate>)delegate{
    self.delegate = delegate;
}
#endif

-(void) fetchDroneData {
    
    
    //// If above one is not working try this one
        DJIAircraft* aircraft = (DJIAircraft *)self.product;
        if (aircraft == nil) {
            [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"Aircraft Instance null"];
            return;
        }
    
    aircraft.flightController.delegate = self;
    aircraft.gimbal.delegate = self;
}

#pragma MARK - DJIGimbalDelegate method
- (void)gimbal:(DJIGimbal *)gimbal didUpdateState:(DJIGimbalState *)state {
    if(state){
        /// Drone attitude
        double radianPitch = RADIAN(state.attitudeInDegrees.pitch);
        double radianRoll = RADIAN(state.attitudeInDegrees.roll);
        double radianYaw = RADIAN(state.attitudeInDegrees.yaw);
        
        NSString *pitch = [NSString stringWithFormat:@"%f", radianPitch];
        NSString *roll = [NSString stringWithFormat:@"%f", radianRoll];
        NSString *yaw = [NSString stringWithFormat:@"%f", radianYaw];
        
        NSMutableArray* gimbalAttitude = [[NSMutableArray alloc] init];
        [gimbalAttitude addObject:pitch];
        [gimbalAttitude addObject:roll];
        [gimbalAttitude addObject:yaw];
    
        NSDictionary *dataDict = @{ @"GetGimbalAttitude": gimbalAttitude };
        [self.GetDroneData addEntriesFromDictionary:dataDict];
        [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"OnGimbalDataPresent Done"];
    #if UNITY_BUILD
        UnitySendMessage("IOSDroneBridgeEventListener", "OnGimbalDataPresent", [IOS_DJI_DataConvertor NSStringToChar:@"OnGimbalDataPresent"]);
    #endif
    }
}

#pragma mark - DJIFlightControllerDelegate Method

- (void)flightController:(DJIFlightController *)fc didUpdateState:(DJIFlightControllerState *)state
{
    CLLocation *location = state.aircraftLocation;
    
    ///Convert Data to Dictionary
    NSString *signalLevel       = [NSString stringWithFormat:@"%lu", (unsigned long)state.GPSSignalLevel];
    NSString *altitude          = [NSString stringWithFormat:@"%f",state.altitude];
    NSString *latitude          = [NSString stringWithFormat:@"%f",location.coordinate.latitude];
    NSString *longitude         = [NSString stringWithFormat:@"%f",location.coordinate.longitude];
    NSString *satelliteCount    = [NSString stringWithFormat:@"%lu", (unsigned long)state.satelliteCount];
    
    NSString *isFlying          = [NSString stringWithFormat:@"%d",state.isFlying];
    NSString *takeofLocationAltitude = [NSString stringWithFormat:@"%f",state.takeoffLocationAltitude];
    
    /// Drone attitude
    double radianPitch = RADIAN(state.attitude.pitch);
    double radianRoll = RADIAN(state.attitude.roll);
    double radianYaw = RADIAN(state.attitude.yaw);
    
    NSString *pitch = [NSString stringWithFormat:@"%f", radianPitch];
    NSString *roll = [NSString stringWithFormat:@"%f", radianRoll];
    NSString *yaw = [NSString stringWithFormat:@"%f", radianYaw];
    
    NSMutableArray* droneAttitude = [[NSMutableArray alloc] init];
    [droneAttitude addObject:pitch];
    [droneAttitude addObject:roll];
    [droneAttitude addObject:yaw];
    
    DJIBaseProduct *product = [IOS_DJI_Utility fetchProduct];
    
    double droneHeading = 0.0;
    if([fc compass] != NULL){
        droneHeading = fc.compass.heading;
    }
    NSString *droneHeadingStr = [NSString stringWithFormat:@"%f",droneHeading];
    
    
    NSDictionary *dataDict = @{@"signalLevel"       : signalLevel,
                              @"latitude"           : latitude,
                              @"longitude"          : longitude,
                              @"altitudeFromGround" : altitude,
                              @"satelliteCount"     : satelliteCount,
                              @"isFlying"           : isFlying,
                              @"GetDroneAttitude"   : droneAttitude,
                              @"takeofLocationAltitude": takeofLocationAltitude,
                              @"GetHeading"         : droneHeadingStr,
                              };
    
    [self.GetDroneData addEntriesFromDictionary:dataDict];
    [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"OnFlightControllerPresent Done"];
#if UNITY_BUILD
    UnitySendMessage("IOSDroneBridgeEventListener", "OnFlightControllerPresent", [IOS_DJI_DataConvertor NSStringToChar:@"model / heading/ flight details can try"]);
#endif
}

///MARK:- Camera Delegate
-(void) setupVideoStream {
    DJICamera *camera = [IOS_DJI_Utility fetchCamera];
    if (camera != nil) {
        camera.delegate = self;
    }
    [self setupVideoPreviewer];
    
    [camera setMode:DJICameraModeRecordVideo withCompletion:^(NSError * _Nullable error) {
        if (error) {
            [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"Set DJICameraModeRecordVideo Failed"];
            #if UNITY_BUILD
            const char * err = [IOS_DJI_DataConvertor NSStringToChar:[NSString stringWithFormat:@"%@", [error description]]];
            UnitySendMessage("IOSDrone", "OnVideoStreamFailed", err);
            #endif
        }
    }];
}
    
-(void) removeVideoStream {
    DJICamera *camera = [IOS_DJI_Utility fetchCamera];
    if (camera && camera.delegate == self) {
        [camera setDelegate:nil];
    }
    [self resetVideoPreview];
}

- (void)setupVideoPreviewer {
    DJIBaseProduct *product = [DJISDKManager product];
    if ([self.modelName1 isEqual:DJIAircraftModelNameA3] ||
        [self.modelName1 isEqual:DJIAircraftModelNameN3] ||
        [self.modelName1 isEqual:DJIAircraftModelNameMatrice600] ||
        [self.modelName1 isEqual:DJIAircraftModelNameMatrice600Pro]){
        [[DJISDKManager videoFeeder].secondaryVideoFeed addListener:self withQueue:nil];
        
    }else{
        [[DJISDKManager videoFeeder].primaryVideoFeed addListener:self withQueue:nil];
    }
}

-(void) attachViewToVideoPreviewer:(UIViewController*) targetViewController {
    // general view
//    self.videoPreviewView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    targetViewController.view.backgroundColor = [UIColor redColor];
    //    [self.view addSubview:self.videoPreviewView];
    //    [self.view sendSubviewToBack:self.videoPreviewView];
//    [self.targetViewController.view addSubview:self.videoPreviewView];
//    [self.targetViewController.view sendSubviewToBack:self.videoPreviewView];
    
    // init dji preview
    [DJIVideoPreviewer instance].type = DJIVideoPreviewerTypeAutoAdapt;
    [[DJIVideoPreviewer instance] start];
    [[DJIVideoPreviewer instance] reset];
//    [[DJIVideoPreviewer instance] setView:self.videoPreviewView];
    [[DJIVideoPreviewer instance] setView:targetViewController.view];
    // set enable decode
    [[DJIVideoPreviewer instance] setEnableHardwareDecode:YES];
}

- (void)resetVideoPreview {
    [[DJIVideoPreviewer instance] unSetView];
    DJIBaseProduct *product = [DJISDKManager product];
    if ([product.model isEqual:DJIAircraftModelNameA3] ||
        [product.model isEqual:DJIAircraftModelNameN3] ||
        [product.model isEqual:DJIAircraftModelNameMatrice600] ||
        [product.model isEqual:DJIAircraftModelNameMatrice600Pro]){
        [[DJISDKManager videoFeeder].secondaryVideoFeed removeListener:self];
    }else{
        [[DJISDKManager videoFeeder].primaryVideoFeed removeListener:self];
    }
}
    
-(void) StartVideoCapture {
    DJICamera *camera = [IOS_DJI_Utility fetchCamera];
    if (camera) {
        [camera startRecordVideoWithCompletion:^(NSError * _Nullable error) {
            if (error) {
                [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"Start Record Video Error"];
                #if UNITY_BUILD
                const char * err = [IOS_DJI_DataConvertor NSStringToChar:[NSString stringWithFormat:@"%@", [error description]]];
                UnitySendMessage("IOSDrone", "OnVideoStreamFailed", err);
                #endif
            }
        }];
    }
}

-(void) StopVideoCapture {
    DJICamera *camera = [IOS_DJI_Utility fetchCamera];
    if (camera) {
        [camera stopRecordVideoWithCompletion:^(NSError * _Nullable error) {
            if (error) {
                [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"Stop Record Video Error"];
                #if UNITY_BUILD
                const char * err = [IOS_DJI_DataConvertor NSStringToChar:[NSString stringWithFormat:@"%@", [error description]]];
                UnitySendMessage("IOSDrone", "OnVideoStreamFailed", err);
                #endif
            }
        }];
        [self removeContainedController:self.presentedController];
    }
}

#pragma mark - DJIVideoFeedListener
-(void)videoFeed:(nonnull DJIVideoFeed *)videoFeed didUpdateVideoData:(nonnull NSData *)videoData{
    [[DJIVideoPreviewer instance] push:(uint8_t *)videoData.bytes length:(int)videoData.length];
   NSString *encodeData = [videoData base64Encoding];
    self.byteTex = videoData;
    [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"tracking video data"];
    [[IOS_DJI_NativeUtility sharedInstance] NativeLog: [NSString stringWithFormat:@"byte in form of string : %@",encodeData]];
    [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"tracking video data"];
    [[IOS_DJI_NativeUtility sharedInstance] NativeLog: [NSString stringWithFormat:@"byte in form of string : %@",self.byteTex]];
    #if UNITY_BUILD
    UnitySendMessage("IOSDrone", "OnVideoStreamSuccessWithData", [IOS_DJI_DataConvertor NSStringToChar:encodeData]);
    #endif
}
    
#pragma mark - DJICameraDelegate
-(void) camera:(DJICamera*)camera didUpdateSystemState:(DJICameraSystemState*)systemState {}

#pragma mark- get Data
-(id) getDataFromDictionary: (char *)key {
    NSString *keyForObject = [IOS_DJI_DataConvertor charToNSString:key];
    NSString* str = [self.GetDroneData objectForKey:keyForObject];
    if(str == nil || [str isKindOfClass:[NSNull class]] || str.length==0) {
        NSString* errMsg = [NSString stringWithFormat:@"Key is not present yet: %s",key];
        [[IOS_DJI_NativeUtility sharedInstance] NativeLog: errMsg];
        return @"";
    }
    [[IOS_DJI_NativeUtility sharedInstance] NativeLog: [NSString stringWithFormat:@"Key %s is present with value : %@",key, str]];
    return str;
}

-(id) getAttitudeFromDictionary: (char *)key {
    NSString *keyForObject = [IOS_DJI_DataConvertor charToNSString:key];
    return [IOS_DJI_DataConvertor serializeNSStringsArray:[self.GetDroneData objectForKey:keyForObject]];
}

-(char *) getModelNameOrig {
    return cStringCopy([IOS_DJI_DataConvertor NSStringToChar:[NSString stringWithFormat:@"%@", self.modelName1]]);
}

-(char *) convertNSStringToChar:(NSString *)value {
    return cStringCopy([IOS_DJI_DataConvertor NSStringToChar:value]);
}

char* cStringCopy(const char* string)
{
    if (string == NULL)
        return NULL;

    char* res = (char*)malloc(strlen(string) + 1);
    strcpy(res, string);

    return res;
}

#pragma mark Video related work


-(void) showDemoView
{
    [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"method to show demo view"];
    // if you displayed as a contained controller and removed it then self.presentedController will be nil
    if (self.presentedController == nil)
    {
        // either load as contained controller or as presented controller
        // change this to see both ways of displaying your content then remove
        // when you know what you want to use
        BOOL loadAsContained = true;
        
        // this view controller is defined in a storyboard, get a reference to the containing storyboard
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        
        // instantiate the view controller from the storyboard
        DemoViewController *demo = [storyboard instantiateViewControllerWithIdentifier:@"DemoVC"];
        
        if (loadAsContained)
        {
            [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"goes for demo controllrt"];
            // add this view controller as a contained controller (child) of the presented view controller
            [self addContainedController:demo];
        }
        else
        {
            [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"not as child but as present view contorller"];
            // if you don't want to display as a child, and instead want to present the view controller
            // on top of the currently presented controller then use this method instead of the previous one
            [[self getTopViewController] presentViewController:demo animated:YES completion:nil];
        }
    }
    else
    {
        [self removeContainedController:self.presentedController];
    }
    [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"end demo view method"];
}

#pragma mark Video related work Helper
// condensed version
- (UIWindow*) getTopApplicationWindow
{
    [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"getTopApplicationWindow"];
    // grabs the top most window
    NSArray* windows = [[UIApplication sharedApplication] windows];
    return ([windows count] > 0) ? windows[0] : nil;
}


- (UIViewController*) getTopViewController
{
    [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"getTopViewController"];
    // get the top most window
    UIWindow *window = [self getTopApplicationWindow];
    
    // get the root view controller for the top most window
    UIViewController *vc = window.rootViewController;
    
    // check if this view controller has any presented view controllers, if so grab the top most one.
    while (vc.presentedViewController != nil)
    {
        // drill to topmost view controller
        vc = vc.presentedViewController;
    }
    
    return vc;
}


-(void) addContainedController:(UIViewController*)controller
{
    [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"addContainedController"];
    // get a reference to the current presented view controller
    UIViewController *parent = [self getTopViewController];
    
    // notify of containment
    [controller willMoveToParentViewController:parent];
    
    // add content as child
    [parent addChildViewController:controller];
    
    // set frame of child content (for demo inset by 100px padding on all sides)
    controller.view.frame = CGRectMake(100.0, 100.0, parent.view.bounds.size.width - 200.0, parent.view.bounds.size.height - 200.0);
    
    // get fancy, lets animate in
    controller.view.alpha = 0.0;
    
    [self attachViewToVideoPreviewer:controller];
    
    // add as subview
    [parent.view addSubview:controller.view];
    
    // animation duration
    CGFloat duration = 0.3;
    
    // animate the alpha in and bring top views to top
    [UIView animateWithDuration:duration
                     animations:^
     {
         controller.view.alpha = 1.0;
     }
                     completion:nil
     ];
    
    // set our tracker variable
    self.presentedController = controller;
}

-(void) removeContainedController:(UIViewController*)controller
{
    [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"removeContainedController"];
    // if fade out our view here just because
    [UIView animateWithDuration:0.3
                     animations:^
     {
         controller.view.alpha = 0;
     }
                     completion:^(BOOL finished)
     {
         
         // inform the child it is being removed by passing nil here
         [controller willMoveToParentViewController:nil];
         
         // remove the view
         [controller.view removeFromSuperview];
         
         // remove view controller from container
         [controller removeFromParentViewController];
         
         // nil out tracker
         self.presentedController = nil;
     }];
}

- (NSData *) getDataTexOption1 {
    return self.byteTex;
}

extern "C" {
    //--------------------------------------
    //  IOS Native Plugin Section
    //--------------------------------------
    void _DJI_Register() {
        [[IOS_DJI sharedInstance] registerApp];
    }
    
    void _DJI_SetDebugDroneActivate(bool* state, char* ipAddress){
        NSString *ip = [IOS_DJI_DataConvertor charToNSString:ipAddress];
        [[IOS_DJI sharedInstance] SetDroneActivate: state withIP: ip];
    }
    
    void _DJI_StartVideoStream() {
        [[IOS_DJI sharedInstance] StartVideoCapture];
        [[IOS_DJI sharedInstance] showDemoView];
    }
    
    void _DJI_StopVideoStream() {
        [[IOS_DJI sharedInstance] StopVideoCapture];
    }

    float _GetDroneHeading(char* key) {
        return [[[IOS_DJI sharedInstance] getDataFromDictionary: key] floatValue];
    }
    
    char* _GetModelName(char* key) {        
        return [[IOS_DJI sharedInstance] getModelNameOrig];
//        NSString *modelName = (NSString *)[[IOS_DJI sharedInstance] getDataFromDictionary: key];
//        return cStringCopy([modelName UTF8String]);
    }

    char* _GetDroneAttitude(char* key) {
        NSString *droneAttitude = (NSString *)[[IOS_DJI sharedInstance] getAttitudeFromDictionary: key];
        return cStringCopy([droneAttitude UTF8String]);
    }
    
    char* _GetGimbalAttitude(char* key) {
        NSString *gimbleAttitude = (NSString *)[[IOS_DJI sharedInstance] getAttitudeFromDictionary: key];
        return cStringCopy([gimbleAttitude UTF8String]);
    }
    
    bool _IsFlying(char *key) {
        return [[[IOS_DJI sharedInstance] getDataFromDictionary: key] boolValue];
    }
    
    float _GetAltitudeFromGround(char* key) {
        return [[[IOS_DJI sharedInstance] getDataFromDictionary: key] floatValue];
    }
    
    float _GetTakeofLocationAltitude(char* key) {
        return [[[IOS_DJI sharedInstance] getDataFromDictionary: key] floatValue];
    }

    int _GetSignalLevel(char* key) {
        return [[[IOS_DJI sharedInstance] getDataFromDictionary: key] intValue];
    }
    
    int _GetSatelliteCount(char* key) {
        return [[[IOS_DJI sharedInstance] getDataFromDictionary: key] intValue];
    }
    
    double _GetLatitude(char* key) {
        return [[[IOS_DJI sharedInstance] getDataFromDictionary: key] doubleValue];
    }
    
    double _GetLongitude(char* key) {
        return [[[IOS_DJI sharedInstance] getDataFromDictionary: key] doubleValue];
    }
    
    uint8_t * _getTextureOption1(){
        return (uint8_t *) [[IOS_DJI sharedInstance] getDataTexOption1].bytes;
    }
    
    ////Another Method Get Model name
    void _DJI_ModelName(void(*callback)(char*)) {
        IOS_DJI *sharedInstance = [IOS_DJI sharedInstance];
        sharedInstance.GetModelNameCallback = ^(char* model){
            if(callback) {
                callback(model);
            }
        };
    }

    
    // uintptr_t UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API _GetNativeTexturePtr(int width, int height)
    // {
    //     MTLTextureDescriptor *descriptor = [[MTLTextureDescriptor alloc] init];
    //     descriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    //     descriptor.width = width;
    //     descriptor.height = height;

    //     id<MTLTexture> texture = [s_MetalGraphics->MetalDevice() newTextureWithDescriptor:descriptor];
    
    //     return (uintptr_t)texture;
    // }
    
    }
@end
