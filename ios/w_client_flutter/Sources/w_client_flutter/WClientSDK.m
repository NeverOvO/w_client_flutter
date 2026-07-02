//
//  WClientSDK.m
//  WClientSDK
//
//  Created by Wenchu Du on 2024/08/14.
//

#import "WClientSDK.h"

@interface WClientSDK()

@end

@implementation WClientSDK

// 1 获取控件版本号
- (NSString *)getVersion {
    return @"1.5.2";
}

// 2 调用网络身份认证App获取认证数据
- (NSDictionary *)getAuthResult:(NSDictionary *)parameters {
    return [self getAuthResult:parameters completion:nil];
}

- (NSDictionary *)getAuthResult:(NSDictionary *)parameters completion:(void (^)(NSDictionary *result))completion {
    if (![parameters isKindOfClass:[NSDictionary class]]) {
        return @{@"resultCode": @"C0405001", @"resultDesc": @"参数不能为空"};
    }

    NSMutableDictionary *localParameter = [NSMutableDictionary dictionaryWithDictionary:parameters];
    NSMutableDictionary *result = [NSMutableDictionary new];
    if (localParameter[@"miniProgramID"] != NULL && ![localParameter[@"miniProgramID"] isEqual: @""]) {
        result[@"miniProgramID"] = localParameter[@"miniProgramID"];
    }

    // 获取urlScheme
    if (localParameter[@"uLink"] == NULL || [localParameter[@"uLink"]  isEqual: @""]) {
        NSString *urlSchemeStr = [self getURLScheme];
        if ([urlSchemeStr isEqualToString:@""]) {
            result[@"resultCode"] = @"C0405001";
            result[@"resultDesc"] = @"数据处理异常";
            return result;
        }
        localParameter[@"urlScheme"] = urlSchemeStr;
    }

    // 获取packageName
    NSString *packageName = [[NSBundle mainBundle] bundleIdentifier];
    localParameter[@"packageName"] = packageName;

    NSString *urlStr = [self convertToUniversalLinksFrom:localParameter];
    NSURL *url = [NSURL URLWithString:urlStr];
    if (!url) {
        result[@"resultCode"] = @"C0405001";
        result[@"resultDesc"] = @"数据处理异常";
        return result;
    }

    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
        if (!success && completion) {
            completion(@{@"resultCode": @"C0412001", @"resultDesc": @"认证启动失败"});
        }
    }];
    result[@"resultCode"] = @"C0000000";
    result[@"resultDesc"] = @"成功";
    return result;
}

- (NSString *)getURLScheme {
    NSString *urlSchemeStr = @"";

    NSArray *arr = [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleURLTypes"];
    for (int i = 0; i < arr.count; i++) {
        NSString *key = arr[i][@"CFBundleURLName"];
        if ([key isEqualToString:@"uLink"] || [key isEqualToString:@"cyberidentity"]) {
            NSArray *schemes = arr[i][@"CFBundleURLSchemes"];
            if (schemes.count > 0) {
                urlSchemeStr = schemes[0];
                break;
            }
        }
    }
    return urlSchemeStr;
}

// 拼接URL
-(NSString *)convertToUniversalLinksFrom:(NSDictionary *)parameter  {
    NSString *urlString = @"https://cdnrefresh.ctdidcii.cn/ulink";
    NSMutableCharacterSet *cs = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [cs removeCharactersInString:@"!*'();:@&=+$,/?%#[]"];
    BOOL isFirst = YES;
    for (NSString *key in parameter) {
        NSString *encodingKey = [[key description] stringByAddingPercentEncodingWithAllowedCharacters:cs];
        NSString *encodingValue = [[parameter[key] description] stringByAddingPercentEncodingWithAllowedCharacters:cs];
        if (isFirst) {
            isFirst = NO;
            urlString = [NSString stringWithFormat:@"%@?%@=%@", urlString, encodingKey, encodingValue];
        } else {
            urlString = [NSString stringWithFormat:@"%@&%@=%@", urlString, encodingKey, encodingValue];
        }
    };
    return urlString;
}

@end
