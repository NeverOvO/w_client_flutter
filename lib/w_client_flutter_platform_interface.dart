import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'w_client_flutter_method_channel.dart';

abstract class WClientFlutterPlatform extends PlatformInterface {
  /// Constructs a WClientFlutterPlatform.
  WClientFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static WClientFlutterPlatform _instance = MethodChannelWClientFlutter();

  /// The default instance of [WClientFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelWClientFlutter].
  static WClientFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WClientFlutterPlatform] when
  /// they register themselves.
  static set instance(WClientFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
