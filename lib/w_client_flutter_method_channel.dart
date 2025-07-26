import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'w_client_flutter_platform_interface.dart';

/// An implementation of [WClientFlutterPlatform] that uses method channels.
class MethodChannelWClientFlutter extends WClientFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('w_client_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
