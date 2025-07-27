import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  //手动添加
  override func application(_ app: UIApplication,open url: URL,options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    //scheme（必须与 Info.plist 中的 uLink字段一致）
    if url.scheme == "uLink字段一致" {
        // 通过通知转发给插件监听者
        NotificationCenter.default.post(name: Notification.Name("WClientAuthResultCallback"),object: url,)
        return true
    }
      return super.application(app, open: url, options: options)
    }
}
