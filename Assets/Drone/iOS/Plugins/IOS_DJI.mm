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

@property(nonatomic, weak) DJIBaseProduct* product;
@property (nonatomic) NSDictionary *fromFlightDelegate;
@property (nonatomic) NSDictionary *fromGimbalDelegate;
@property (nonatomic) NSMutableDictionary *GetDroneData;
@property (nonatomic, assign) NSData *byteTex;
@property (copy) void (^GetModelNameCallback)(char*);

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
        // Calback with model name
        self.GetModelNameCallback((char *)[IOS_DJI_DataConvertor NSStringToChar:[NSString stringWithFormat:@"%@", product.model]]);
        
        // fetch drone data
        [self fetchDroneData];
        [self setupVideoStream];
        [self setupVideoPreviewer];
        
        UnitySendMessage("IOSDroneBridgeEventListener", "OnDroneConnected", [IOS_DJI_DataConvertor NSStringToChar:@""]);
    }
    else {
        UnitySendMessage("IOSDroneBridgeEventListener", "OnDroneDataNotAvailable", [IOS_DJI_DataConvertor NSStringToChar:@"Unable to fetch drone data"]);
    }
#else
    
    if(product){
        /// callback to Example section
        [self.delegate appDroneConnected:product];
        
        /// Collect product Instance
        self.product = product;
        
        /// Calback with model name
        self.GetModelNameCallback((char *)[IOS_DJI_DataConvertor NSStringToChar:[NSString stringWithFormat:@"%@", product.model]]);
        
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
    NSString *takeoffLocationAltitude = [NSString stringWithFormat:@"%f",state.takeoffLocationAltitude];
    
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
    
//    NSString *droneHeading = [NSString stringWithFormat:@"%f",yaw];
    
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
                              @"GetModelName"       : self.product.model,
                            //   @"GetHeading"       : droneHeading,
                              @"takeoffLocationAltitude": takeoffLocationAltitude,
                              @"GetHeading"         : droneHeadingStr,
                              };
    
    [self.GetDroneData addEntriesFromDictionary:dataDict];
    [[IOS_DJI_NativeUtility sharedInstance] NativeLog: @"OnFlightControllerPresent Done"];
#if UNITY_BUILD
    UnitySendMessage("IOSDroneBridgeEventListener", "OnFlightControllerPresent", [IOS_DJI_DataConvertor NSStringToChar:@"model / heading/ flight details can try"]);
#endif
}
/*
-(void) CheckDeleagteTaskCompleted:(NSDictionary *)fromFlight withDJIGimbal: (NSDictionary *)fromGimbal {
    self.fromFlightDelegate = fromFlight;
    self.fromGimbalDelegate = fromGimbal;
    
//     if([self.fromFlightDelegate count] > 0 && [self.fromGimbalDelegate count] > 0){
     
//         NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
//         [dict addEntriesFromDictionary: self.fromFlightDelegate];
//         [dict addEntriesFromDictionary: self.fromGimbalDelegate];
        
//         /// Parse Dictionary
//         NSError *err;
//         NSData  *data = [NSJSONSerialization  dataWithJSONObject:dict options:0 error:&err];
//         NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
#if UNITY_BUILD
        ///Send GPS State with data
        const char * parseData = [IOS_DJI_DataConvertor NSStringToChar:[NSString stringWithFormat:@"%@", dataString]];
        UnitySendMessage("IOSDrone", "DroneData", parseData);
#else
        NSLog(@"%@", dataString);
#endif
    }
    
}
*/

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
    if ([product.model isEqual:DJIAircraftModelNameA3] ||
            [product.model isEqual:DJIAircraftModelNameN3] ||
            [product.model isEqual:DJIAircraftModelNameMatrice600] ||
            [product.model isEqual:DJIAircraftModelNameMatrice600Pro]){
            [[DJISDKManager videoFeeder].secondaryVideoFeed addListener:self withQueue:nil];
            
    }else{
        [[DJISDKManager videoFeeder].primaryVideoFeed addListener:self withQueue:nil];
    }
    [[DJIVideoPreviewer instance] start];
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
    }
}

#pragma mark - DJIVideoFeedListener
-(void)videoFeed:(nonnull DJIVideoFeed *)videoFeed didUpdateVideoData:(nonnull NSData *)videoData{
    [[DJIVideoPreviewer instance] push:(uint8_t *)videoData.bytes length:(int)videoData.length];
   NSString *encodeData = [videoData base64Encoding];
    self.byteTex = videoData;
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

char* cStringCopy(const char* string)
{
    if (string == NULL)
        return NULL;

    char* res = (char*)malloc(strlen(string) + 1);
    strcpy(res, string);

    return res;
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
    }
    
    void _DJI_StopVideoStream() {
        [[IOS_DJI sharedInstance] StopVideoCapture];
    }

    float _GetDroneHeading(char* key) {
        return [[[IOS_DJI sharedInstance] getDataFromDictionary: key] floatValue];
    }
    
    char* _GetModelName(char* key) {
        NSString *modelName = [[IOS_DJI sharedInstance] getDataFromDictionary: key];
        return cStringCopy([modelName UTF8String]);
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

    char* _GetDroneAttitude(char* key) {
        NSString *droneAttitude = (NSString *)[[IOS_DJI sharedInstance] getAttitudeFromDictionary: key];
        return cStringCopy([droneAttitude UTF8String]);
    }
    
    char* _GetGimbalAttitude(char* key) {
        NSString *gimbleAttitude = (NSString *)[[IOS_DJI sharedInstance] getAttitudeFromDictionary: key];
        return cStringCopy([gimbleAttitude UTF8String]);
    }
    
    uint8_t * getTextureOption1(){
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
