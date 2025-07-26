import 'package:flutter/services.dart';
import 'w_client_flutter_platform_interface.dart';

class WClientFlutter {
  static const MethodChannel _channel = MethodChannel('w_client_flutter');

  Future<String?> getPlatformVersion() {
    return WClientFlutterPlatform.instance.getPlatformVersion();
  }

  /// 获取 SDK 版本号
  static Future<String?> getVersion() async {
    return await _channel.invokeMethod<String>('getVersion');
  }

  /// 发起认证并可选传入回调 Scheme
  /// [parameters] 必填：orgID、appID、bizSeq、type
  /// 可选：miniProgramID、miniProPgramPlatformID、urlScheme
  static Future<dynamic> getAuthResult(Map<String, dynamic> parameters) async {
    final result = await _channel.invokeMethod('getAuthResult', parameters);
    return result;
  }

}
