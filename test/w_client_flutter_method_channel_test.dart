import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:w_client_flutter/w_client_flutter.dart';
import 'package:w_client_flutter/w_client_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelWClientFlutter platform = MethodChannelWClientFlutter();
  const MethodChannel channel = MethodChannel('w_client_flutter');
  final validAuthParams = {
    'orgID': 'org',
    'appID': 'app',
    'bizSeq': 'biz',
    'type': '1',
  };

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('getAuthResult returns map result', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return {'resultCode': 'C0000000', 'resultDesc': '成功'};
        });

    expect(await WClientFlutter.getAuthResult(validAuthParams), {
      'resultCode': 'C0000000',
      'resultDesc': '成功',
    });
  });

  test('getAuthResult normalizes legacy string result', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return 'C0412002';
        });

    expect(await WClientFlutter.getAuthResult(validAuthParams), {
      'resultCode': 'C0412002',
      'resultDesc': 'C0412002',
    });
  });

  test('getAuthResult normalizes platform exception', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw PlatformException(code: 'INVALID_ARGUMENT', message: '参数不能为空');
        });

    expect(await WClientFlutter.getAuthResult(validAuthParams), {
      'resultCode': 'INVALID_ARGUMENT',
      'resultDesc': '参数不能为空',
    });
  });

  test('getAuthResult validates required parameters', () async {
    expect(await WClientFlutter.getAuthResult({}), {
      'resultCode': 'INVALID_ARGUMENT',
      'resultDesc': '缺少必要参数orgID',
    });
  });
}
