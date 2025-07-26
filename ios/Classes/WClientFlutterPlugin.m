#import "WClientFlutterPlugin.h"
#import <Flutter/Flutter.h>
#import "WClientSDK.h"

static FlutterEventSink _eventSink; // 保存 event sink 用于后续发送事件

@interface WClientFlutterPlugin()<FlutterStreamHandler>

@property(nonatomic, strong) FlutterResult pendingResult;

@end

@implementation WClientFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"w_client_flutter" binaryMessenger:[registrar messenger]];
    WClientFlutterPlugin *instance = [[WClientFlutterPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];

    // 监听 URL 回调通知，由 AppDelegate openURL 触发
    [[NSNotificationCenter defaultCenter] addObserverForName:@"WClientAuthResultCallback" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        NSURL *url = (NSURL *)note.object;

        // 解析 URL 参数为字典
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
        for (NSURLQueryItem *item in components.queryItems) {
            if (item.name && item.value) {
                queryParams[item.name] = item.value;
            }
        }

        // 通过 pendingResult 回调给 Dart
        if (instance.pendingResult) {
            instance.pendingResult(queryParams);
            instance.pendingResult = nil;
        }

        // 同时发送事件
        if (_eventSink) {
            _eventSink(queryParams);
        }
    }];
}

#pragma mark - FlutterPlugin 方法

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    WClientSDK *sdk = [[WClientSDK alloc] init];

    if ([@"getVersion" isEqualToString:call.method]) {
        result([sdk getVersion]);

    } else if ([@"getAuthResult" isEqualToString:call.method]) {
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
        [sdk getAuthResult:params];

    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end