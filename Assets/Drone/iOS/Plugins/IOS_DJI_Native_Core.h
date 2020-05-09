//
//  iOS_DJI_Native_Core.h
//  

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IOS_DJI_DataConvertor : NSObject

+ (NSString*) charToNSString: (char*)value;
+ (const char *) NSStringToChar: (NSString *) value;

+ (const char *) NSStringsArrayToChar:(NSArray *) array;
+ (NSString *) serializeNSStringsArray:(NSArray *) array;

@end

@interface IOS_DJI_NativeUtility : NSObject
+ (id) sharedInstance;
- (void) NativeLog: (NSString *) appId, ...;
- (void) SetLogState: (BOOL) appId;
@end

NS_ASSUME_NONNULL_END
