#import "WClientFlutterPlugin.h"
#import <Flutter/Flutter.h>
#import "WClientSDK.h"

static FlutterEventSink _eventSink; // 保存 event sink 用于后续发送事件

@interface WClientFlutterPlugin()<FlutterStreamHandler, FlutterSceneLifeCycleDelegate>

@property(nonatomic, strong) FlutterResult pendingResult;
@property(nonatomic, strong) NSTimer *authTimeoutTimer;
@property(nonatomic, strong) id authCallbackObserver;

@end

@implementation WClientFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"w_client_flutter" binaryMessenger:[registrar messenger]];
    WClientFlutterPlugin *instance = [[WClientFlutterPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addApplicationDelegate:instance];

    FlutterEventChannel *eventChannel = [FlutterEventChannel eventChannelWithName:@"w_client_flutter/events" binaryMessenger:[registrar messenger]];
    [eventChannel setStreamHandler:instance];

    // 监听 URL 回调通知，由 AppDelegate openURL 触发
    __weak WClientFlutterPlugin *weakInstance = instance;
    instance.authCallbackObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"WClientAuthResultCallback" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        NSURL *url = (NSURL *)note.object;
        [weakInstance handleAuthCallbackURL:url];
    }];
}

- (void)dealloc {
    if (self.authCallbackObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.authCallbackObserver];
    }
    [self clearAuthTimeoutTimer];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if (![self isAuthCallbackURL:url]) {
        return NO;
    }

    [self handleAuthCallbackURL:url];
    return YES;
}

- (BOOL)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts API_AVAILABLE(ios(13.0)) {
    for (UIOpenURLContext *context in URLContexts) {
        NSURL *url = context.URL;
        if ([self isAuthCallbackURL:url]) {
            [self handleAuthCallbackURL:url];
            return YES;
        }
    }

    return NO;
}

- (BOOL)isAuthCallbackURL:(NSURL *)url {
    if (![url isKindOfClass:[NSURL class]] || url.scheme.length == 0) {
        return NO;
    }

    NSArray *urlTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    if (![urlTypes isKindOfClass:[NSArray class]]) {
        return NO;
    }

    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    if (components.queryItems.count == 0) {
        return NO;
    }

    for (NSDictionary *item in urlTypes) {
        if ([item isKindOfClass:[NSDictionary class]] &&
            [item[@"CFBundleURLName"] isKindOfClass:[NSString class]] &&
            [item[@"CFBundleURLSchemes"] isKindOfClass:[NSArray class]] &&
            [item[@"CFBundleURLName"] isEqualToString:@"uLink"]) {

            for (NSString *scheme in item[@"CFBundleURLSchemes"]) {
                if ([scheme isKindOfClass:[NSString class]] &&
                    [url.scheme caseInsensitiveCompare:scheme] == NSOrderedSame) {
                    return YES;
                }
            }
        }
    }

    return NO;
}

- (void)handleAuthCallbackURL:(NSURL *)url {
    if (![url isKindOfClass:[NSURL class]]) {
        return;
    }

    // 解析认证 App 回跳参数，避免 Flutter 将回跳 URL 当成页面路由处理
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in components.queryItems) {
        if (item.name && item.value) {
            queryParams[item.name] = item.value;
        }
    }

    [self completeAuthWithResult:queryParams];
}

- (void)completeAuthWithResult:(NSDictionary *)result {
    [self clearAuthTimeoutTimer];

    // 通过 pendingResult 回调给 Dart
    if (self.pendingResult) {
        self.pendingResult(result);
        self.pendingResult = nil;
    }

    // 同时发送事件
    if (_eventSink) {
        _eventSink(result);
    }
}

#pragma mark - FlutterPlugin 方法

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    WClientSDK *sdk = [[WClientSDK alloc] init];

    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);

    } else if ([@"getVersion" isEqualToString:call.method]) {
        result([sdk getVersion]);

    } else if ([@"getAuthResult" isEqualToString:call.method]) {
        if (![call.arguments isKindOfClass:[NSDictionary class]]) {
            result(@{@"resultCode": @"INVALID_ARGUMENT", @"resultDesc": @"参数不能为空"});
            return;
        }

        if (self.pendingResult) {
            result(@{@"resultCode": @"AUTH_IN_PROGRESS", @"resultDesc": @"已有认证请求正在处理中"});
            return;
        }

        NSMutableDictionary *params = [call.arguments mutableCopy];

        // 优先使用 Dart 传入的 uLink，否则从 Info.plist 查找 CFBundleURLName 为 "uLink" 的 scheme
        if (![params[@"uLink"] isKindOfClass:[NSString class]] || [params[@"uLink"] length] == 0) {
            NSArray *urlTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
            NSString *scheme = nil;

            if ([urlTypes isKindOfClass:[NSArray class]]) {
                for (NSDictionary *item in urlTypes) {
                    if ([item isKindOfClass:[NSDictionary class]] &&
                        [item[@"CFBundleURLName"] isKindOfClass:[NSString class]] &&
                        [item[@"CFBundleURLSchemes"] isKindOfClass:[NSArray class]] &&
                        [item[@"CFBundleURLName"] isEqualToString:@"uLink"]) {

                        NSArray *schemes = item[@"CFBundleURLSchemes"];
                        if (schemes.count > 0 && [schemes.firstObject isKindOfClass:[NSString class]]) {
                            scheme = schemes.firstObject;
                            break;
                        }
                    }
                }
            }

            if (scheme.length > 0) {
                params[@"uLink"] = [NSString stringWithFormat:@"%@://", scheme];
            } else {
                NSLog(@"[WClientFlutterPlugin] ⚠️ 未找到 CFBundleURLName 为 uLink 的 URL Scheme");
            }
        }

        // 保存 result 用于异步返回
        self.pendingResult = result;

        // 调用 SDK 启动认证流程，结果通过通知返回
        NSDictionary *launchResult = [sdk getAuthResult:params completion:^(NSDictionary *openResult) {
            if (self.pendingResult) {
                [self completeAuthWithResult:openResult];
            }
        }];
        if (![launchResult[@"resultCode"] isEqualToString:@"C0000000"]) {
            [self completeAuthWithResult:launchResult];
        } else {
            [self startAuthTimeoutTimer];
        }

    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    _eventSink = nil;
    return nil;
}

- (void)startAuthTimeoutTimer {
    [self clearAuthTimeoutTimer];
    self.authTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:120 target:self selector:@selector(handleAuthTimeout) userInfo:nil repeats:NO];
}

- (void)clearAuthTimeoutTimer {
    [self.authTimeoutTimer invalidate];
    self.authTimeoutTimer = nil;
}

- (void)handleAuthTimeout {
    if (!self.pendingResult) {
        return;
    }

    [self completeAuthWithResult:@{@"resultCode": @"C0412003", @"resultDesc": @"认证等待超时"}];
}

@end
