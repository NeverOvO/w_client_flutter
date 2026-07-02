# Project Context

## 技术栈与目录

* Flutter 插件仓库，Dart API 位于 `lib/`，单元测试位于 `test/`。
* iOS 插件同时支持 Swift Package Manager 与 CocoaPods。
* iOS 原生代码为 Objective-C，SwiftPM 源码目录为 `ios/w_client_flutter/Sources/w_client_flutter/`。

## iOS 集成约束

* pubspec 中 iOS `pluginClass` 为 `WClientFlutterPlugin`。
* MethodChannel 名称为 `w_client_flutter`。
* iOS 最低版本为 12.0，需与 `ios/w_client_flutter.podspec` 和 `ios/w_client_flutter/Package.swift` 保持一致。
* CocoaPods 和 SwiftPM 应引用同一份 iOS 源码，避免重复源码副本。
* `PrivacyInfo.xcprivacy` 位于 SwiftPM target 目录，并需要同时在 SwiftPM 和 podspec 中声明。
* iOS 认证回跳由 `WClientFlutterPlugin` 注册 application delegate 处理，匹配 `CFBundleURLName = uLink` 的 URL scheme 后消费回调，避免 Flutter 将回跳 URL 当成页面路由。
* example iOS 工程使用 SwiftPM 集成插件，不再保留 CocoaPods App 集成；插件自身仍保留 podspec 供宿主 CocoaPods 使用。
* example iOS 工程已按 Flutter 3.44.4 模板补充 `SceneDelegate.swift` 和 `UIApplicationSceneManifest`。
* `WClientFlutter.getAuthResult` 统一返回 `Map<String, dynamic>`，业务失败也通过 `resultCode` 和 `resultDesc` 返回。
* 认证结果事件流为 `WClientFlutter.authResultStream`，原生 EventChannel 名称为 `w_client_flutter/events`。
* iOS/Android 原生认证等待超时为 120 秒，Dart 默认等待超时为 130 秒。

## 已验证命令

* `flutter pub get` 可在根目录成功解析根包和 example 依赖。
* `flutter test` 通过现有单元测试。
* SwiftPM 开启时，`example` 可执行 `flutter build ios --debug --no-codesign`。
* 插件 podspec 保留 CocoaPods 支持；example iOS 已移除 CocoaPods App 集成，不再作为 CocoaPods 示例工程验证入口。
* `dart analyze` 当前无问题。
* `example` 可执行 `flutter test`。
* `example` 可执行 `flutter build apk --debug`。
* `flutter pub publish --dry-run` 可识别发布版本 2.0.0；当前剩余 warning 来自 Git 工作区未提交和旧文件删除待提交。

## 已知环境问题

* 当前路径下 `flutter analyze` 会触发 analysis_server `FormatException: Unexpected end of input` 并以 255 退出；`dart analyze` 可运行，并报告 `example/lib/main.dart` 既有 `avoid_print` info。
