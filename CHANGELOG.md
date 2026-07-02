## 2.1.0

* 新增 iOS 插件 UIScene URL 回调支持，适配 Flutter 新生命周期要求。
* 保留原有 AppDelegate URL 回调兼容逻辑，不影响旧版宿主项目接入。

## 2.0.0

* 新增 iOS Swift Package Manager 支持，同时保留 CocoaPods 集成能力。
* 调整 iOS 原生源码目录结构，适配当前 Flutter 插件模板。
* 更新 example iOS 工程，改用 SwiftPM 集成，并补充 UIScene 生命周期配置和构建版本信息。
* 优化 iOS URL Scheme 认证回调处理，减少宿主 AppDelegate 手动接入要求。
* 统一认证结果返回结构，通过 `resultCode` 和 `resultDesc` 返回成功、失败、取消、超时等状态。
* 新增认证结果事件流监听能力。
* 新增认证等待超时处理，并优化 iOS 和 Android 认证启动结果返回。
* 优化 Dart、iOS、Android 参数校验逻辑。
* 新增 Android 国家网络身份认证 App 包可见性声明。

## 1.0.0

* 首次发布，基于 SDK 1.5.2。
* 支持 iOS 源码集成。
* 支持 Android 集成，宿主 App 需要自行引入官方 AAR 包。
