# Codex 执行规则

## 项目概况

* 这是 Flutter 插件项目，Dart 代码在 `lib/`，测试在 `test/`。
* iOS 插件代码在 `ios/`，Android 插件代码在 `android/`，示例工程在 `example/`。
* 开始任务时先阅读 `.codex/PROJECT_CONTEXT.md`（如存在）和本文件。

## 修改原则

* 严格遵循最小修改原则，只修改与当前任务直接相关的文件。
* 保持原文件的换行、缩进、空行、排序、命名和整体代码风格。
* 不执行全量格式化；确需格式化时只处理本次修改的最小范围。
* 不升级依赖、SDK、构建工具或锁文件，除非任务明确要求。
* 不主动执行 `git commit`、`git push` 或破坏性 Git 操作。

## iOS 约束

* 保留 CocoaPods 支持，不得删除 `ios/w_client_flutter.podspec`。
* 不改变 Dart API、MethodChannel 名称、插件注册类名和现有功能。
* iOS 最低版本、原生依赖和资源配置需同时兼容 SwiftPM 与 CocoaPods。

## 验证

* 常规检查优先使用项目现有命令：`flutter pub get`、`flutter analyze`、`flutter test`。
* iOS 集成变更需分别验证 SwiftPM 和 CocoaPods 构建路径。
* 无法验证时，在最终反馈中说明未执行内容、原因和建议命令。
