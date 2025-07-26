import 'package:flutter_test/flutter_test.dart';
import 'package:w_client_flutter/w_client_flutter.dart';
import 'package:w_client_flutter/w_client_flutter_platform_interface.dart';
import 'package:w_client_flutter/w_client_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWClientFlutterPlatform
    with MockPlatformInterfaceMixin
    implements WClientFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final WClientFlutterPlatform initialPlatform = WClientFlutterPlatform.instance;

  test('$MethodChannelWClientFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWClientFlutter>());
  });

  test('getPlatformVersion', () async {
    WClientFlutter wClientFlutterPlugin = WClientFlutter();
    MockWClientFlutterPlatform fakePlatform = MockWClientFlutterPlatform();
    WClientFlutterPlatform.instance = fakePlatform;

    expect(await wClientFlutterPlugin.getPlatformVersion(), '42');
  });
}
