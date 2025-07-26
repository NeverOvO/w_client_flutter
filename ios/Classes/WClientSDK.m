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

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr] options:@{} completionHandler:^(BOOL success) {}];
    result[@"resultCode"] = @"C0000000";
    result[@"resultDesc"] = @"成功";
    return result;
}

- (NSString *)getURLScheme {
    NSString *urlSchemeStr = @"";

    NSArray *arr = [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleURLTypes"];
    for (int i = 0; i < arr.count; i++) {
        NSString *key = arr[i][@"CFBundleURLName"];
        if ([key isEqualToString:@"cyberidentity"]) {
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
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:@"&%"] invertedSet];
    BOOL isFirst = YES;
    for (NSString *key in parameter) {
        NSString *encodingKey = [key stringByAddingPercentEncodingWithAllowedCharacters:cs];
        NSString *encodingValue = [parameter[key] stringByAddingPercentEncodingWithAllowedCharacters:cs];
        if (isFirst) {
            isFirst = NO;
            urlString = [NSString stringWithFormat:@"%@?%@=%@", urlString, encodingKey, encodingValue];
        } else {
            urlString = [NSString stringWithFormat:@"%@&%@=%@", urlString, encodingKey, encodingValue];
        }
    };
    return [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

@end
