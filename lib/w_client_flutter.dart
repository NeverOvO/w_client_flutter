import 'dart:async';

import 'package:flutter/services.dart';
import 'w_client_flutter_platform_interface.dart';

class WClientFlutter {
  static const MethodChannel _channel = MethodChannel('w_client_flutter');
  static const EventChannel _eventChannel = EventChannel(
    'w_client_flutter/events',
  );
  static const List<String> _requiredAuthKeys = [
    'orgID',
    'appID',
    'bizSeq',
    'type',
  ];
  static Stream<Map<String, dynamic>>? _authResultStream;

  Future<String?> getPlatformVersion() {
    return WClientFlutterPlatform.instance.getPlatformVersion();
  }

  /// 获取 SDK 版本号
  static Future<String?> getVersion() async {
    return await _channel.invokeMethod<String>('getVersion');
  }

  /// 发起认证并可选传入回调 Scheme
  /// [parameters] 必填：orgID、appID、bizSeq、type
  /// 可选：miniProgramID、miniProPgramPlatformID、uLink
  static Future<Map<String, dynamic>> getAuthResult(
    Map<String, dynamic> parameters, {
    Duration timeout = const Duration(seconds: 130),
  }) async {
    final invalidResult = _validateAuthParameters(parameters);
    if (invalidResult != null) {
      return invalidResult;
    }

    try {
      final result = await _channel
          .invokeMethod('getAuthResult', parameters)
          .timeout(timeout);
      return _normalizeAuthResult(result);
    } on TimeoutException {
      return {'resultCode': 'C0412003', 'resultDesc': '认证等待超时'};
    } on PlatformException catch (e) {
      return {'resultCode': e.code, 'resultDesc': e.message ?? e.code};
    }
  }

  /// 监听原生认证回调事件。
  static Stream<Map<String, dynamic>> get authResultStream {
    return _authResultStream ??= _eventChannel
        .receiveBroadcastStream()
        .map<Map<String, dynamic>>(_normalizeAuthResult);
  }

  static Map<String, dynamic> _normalizeAuthResult(dynamic result) {
    if (result is Map) {
      return result.map((key, value) => MapEntry(key.toString(), value));
    }

    if (result is String) {
      return {'resultCode': result, 'resultDesc': result};
    }

    if (result == null) {
      return {'resultCode': 'UNKNOWN', 'resultDesc': '认证结果为空'};
    }

    return {'resultCode': 'UNKNOWN', 'resultDesc': result.toString()};
  }

  static Map<String, dynamic>? _validateAuthParameters(
    Map<String, dynamic> parameters,
  ) {
    for (final key in _requiredAuthKeys) {
      final value = parameters[key];
      if (value == null || value.toString().isEmpty) {
        return {'resultCode': 'INVALID_ARGUMENT', 'resultDesc': '缺少必要参数$key'};
      }
    }

    return null;
  }
}
