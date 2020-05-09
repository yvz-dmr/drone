//
//  iOS_DJI_Native_Core.m
//  

#import "IOS_DJI_Native_Core.h"

NSString * const UNITY_SPLITTER = @"|";
NSString * const UNITY_EOF = @"endofline";


@implementation IOS_DJI_DataConvertor

+(NSString *) charToNSString:(char *)value {
    if (value != NULL) {
        return [NSString stringWithUTF8String: value];
    } else {
        return [NSString stringWithUTF8String: ""];
    }
}

+ (const char *) NSStringToChar:(NSString *)value {
    return [value UTF8String];
}

+ (const char *) NSStringsArrayToChar:(NSArray *) array{
    return [IOS_DJI_DataConvertor NSStringToChar:[IOS_DJI_DataConvertor serializeNSStringsArray:array]];
}

+ (NSString *) serializeNSStringsArray:(NSArray *) array {
    
    NSMutableString * data = [[NSMutableString alloc] init];
    
    
    for(NSString* str in array) {
        [data appendString:str];
        [data appendString: UNITY_SPLITTER];
    }
    
    [data appendString: UNITY_EOF];
    
    NSString *str = [data copy];
    return str;
}

@end

@implementation IOS_DJI_NativeUtility

static bool logState = false;
static IOS_DJI_NativeUtility * na_sharedInstance;

+ (id)sharedInstance {
    
    if (na_sharedInstance == nil)  {
        na_sharedInstance = [[self alloc] init];
    }
    
    return na_sharedInstance;
}

-(void) SetLogState:(BOOL)state {
    logState = state;
}

-(void) NativeLog:(NSString *)msg, ... {
    if(logState) {
        va_list argumentList;
        va_start(argumentList, msg);
        
        NSString *message = [[NSString alloc] initWithFormat:msg arguments:argumentList];
        
        va_end(argumentList);
        
        NSLog(@"NativeLog: %@", message);
    }
}

@end

extern "C" {
    void _DJI_SetLogState(bool state) {
        [[IOS_DJI_NativeUtility sharedInstance] SetLogState:(state)];
    }
    
    void _DJI_NativeLog(char* message) {
        [[IOS_DJI_NativeUtility sharedInstance] NativeLog: [IOS_DJI_DataConvertor charToNSString:message]];
    }
}
