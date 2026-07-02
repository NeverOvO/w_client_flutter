//
//  WClientSDK.h
//  WClientSDK
//
//  Created by Wenchu Du on 2024/08/14.
//

#import <UIKit/UIKit.h>

@interface WClientSDK: NSObject

/// 获取WH客户端SDK版本号
- (NSString *)getVersion;

/// 调用网络身份认证App获取认证数据
/// @param parameters 参数字典  需包含orgID、appID、bizSeq、type、miniProgramID（可选）、miniProPgramPlatformID（可选）、uLink（可选）键值对
- (NSDictionary *)getAuthResult:(NSDictionary *)parameters;

/// 调用网络身份认证App获取认证数据，并在启动失败时回调错误结果
- (NSDictionary *)getAuthResult:(NSDictionary *)parameters completion:(void (^)(NSDictionary *result))completion;

@end
