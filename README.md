# w_client_flutter

基于国家网络身份认证iOS/Android SDK进行二次开发的Flutter插件，作者NeverOuO

代码已获得软著保护，登记号为：2025SR1924434

代码已申请发明专利，公开号为：CN121842676A

# 使用方法
## 引入组件

1:本地包体引入：

```
  uuid: ^4.5.1
  w_client_flutter:
    path: ../
```
2:云端引入：w_client_flutter: ^2.0.0

## 核心代码

### 使用

```
  void doAuth() async {
    String bizSeq = Uuid().v4().toString().replaceAll("-", "");
    // 可选传入你自己的 scheme
    final authResult = await WClientFlutter.getAuthResult({
      'orgID': '机构ID',//机构ID
      'appID': Platform.isAndroid ? '0002' : '0003',//应用ID 例如 0003 iOS 0002 安卓
      'bizSeq': bizSeq,//业务序列号 UUID32位
      'type': '1',//业务类型
      // 'uLink' :'uLink', // iOS项目，可不填，自动从Info.plist中的CFBundleURLName为uLink项获取
    });

    print('认证返回：$authResult');
  }
```

bizSeq 由接入机构生成32位字母或数字，用于标识每笔业务的唯一性，故采用UUID生成32位字符较为合适，需要其他方案生成可自行选择
```
  String bizSeq = Uuid().v4().toString().replaceAll("-", "");
```
orgID：填写机构ID

appID：应用ID 例如 0003 iOS 0002 安卓

type：0：网络身份认证凭证 ； 1：网络身份认证凭证+口令 ；1）当认证模式选择R01、R03时，type值为0 ；2）当认证模式选择R02、R04时，type值为1

uLink：即在申请开通时填写的网页Url scheme 地址参数，这里我允许用户手动填写与自动获取，为保证业务可靠性，请在宿主APP的iOS项目Info.plist中添加如下代码
```
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>uLink</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>Url scheme 地址参数</string>
    </array>
  </dict>
</array>
```

Url scheme 地址参数 请替换为申请时地址，例如申请时为 nbexample://

则CFBundleURLName 为 uLink ，CFBundleURLSchemes 为 nbexample ，即如下：

```
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>uLink</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>nbexample</string>
    </array>
  </dict>
</array>
```

### 参数返回

参数统一返回为一个Map。
常见字段为resultCode、resultDesc、idCardAuthData、certPwdData。
异常、取消、未安装、启动失败或等待超时时，也会通过resultCode、resultDesc返回，请根据机构文档和业务需要处理。

也可以监听认证回调事件：
```
WClientFlutter.authResultStream.listen((result) {
  print('认证事件回调：$result');
});
```

详细报错信息请查阅机构文档。

## iOS端需要额外配置

#### iOS最低支持为iOS12

插件同时支持 Swift Package Manager 与 CocoaPods。

Flutter 3.44.4 及以上默认启用 SwiftPM 时，会通过 `ios/w_client_flutter/Package.swift` 集成插件；使用 CocoaPods 的宿主项目仍可通过 `ios/w_client_flutter.podspec` 集成。

iOS认证回跳由插件自动注册 application delegate 处理。宿主APP只需要保证 Info.plist 中存在 `CFBundleURLName` 为 `uLink` 的 URL Scheme 配置，一般不需要再手动修改 AppDelegate。

如果宿主APP已经重写 `application(_:open:options:)` 或 SceneDelegate 的 URL 回调方法，请不要直接吞掉认证回跳。未自行处理时应调用 `super`，否则插件无法收到认证结果。

由于SDK内为HTTP通信，请确保项目允许HTTP链接
```
<key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <true/>
  </dict>
```
## Android端需要额外配置

插件 manifest 已内置国家网络身份认证 App 的包可见性声明：
```
<queries>
  <package android:name= "cn.cyberIdentity.certification"/>
</queries>
```

正常 Flutter/Android 构建会自动合并该声明，用于查询国家网络身份认证APP是否安装。若宿主项目有自定义 manifest 合并规则，请确认最终 APK 中仍保留该 `<queries>` 配置。

#### cn.cyberIdentity.certification即国家网络身份认证APP包名

在宿主APP的android项目中，Android根目录下添加libs文件夹，与app文件夹同级，引入w_auth-release.aar包
具体包体可以导入example/android/libs下的w_auth-release.aar包

注：libs目录与app目录同级，或处于app目录下级均可，推荐同级。

在宿主Android项目的 app/build.gradle 中最下方添加代码，引入该aar包
```
//Kotlin写法
dependencies {
    implementation(fileTree("libs") {
        include("*.aar")
    })
}

//Groovy写法
dependencies {
    implementation fileTree(include: ['*.aar'], dir: 'libs')
}

```
此处为简略写法，全部引入，忽略名称

# 代码说明

## Dart层

插件对外入口为 `WClientFlutter`，MethodChannel 名称为 `w_client_flutter`。

当前主要方法：

* `getVersion()`：获取原生 SDK 版本号。
* `getAuthResult(Map<String, dynamic> parameters)`：发起认证，统一返回 `Map<String, dynamic>`。
* `authResultStream`：监听原生认证回调事件。

`getAuthResult` 的整体流程保持为：Dart传参 -> Dart和原生端校验参数 -> 拉起国家网络身份认证 App 或下载页 -> 原生端等待认证回调 -> 返回认证结果。

默认等待超时时间为130秒，可按业务需要传入 `timeout`：
```
final result = await WClientFlutter.getAuthResult(params, timeout: Duration(seconds: 180));
```

## iOS层

iOS原生代码位于：

```
ios/w_client_flutter/Sources/w_client_flutter/
```

关键文件：

* `WClientFlutterPlugin.m`：注册 MethodChannel、处理 Flutter 方法调用、接收认证 App 回跳 URL 并返回 Dart。
* `WClientSDK.m`：拼接认证 Universal Link，拉起国家网络身份认证 App 或网页。
* `Package.swift`：SwiftPM 集成入口。
* `w_client_flutter.podspec`：CocoaPods 集成入口。

iOS回跳规则：

* 插件会查找宿主 `Info.plist` 中 `CFBundleURLName = uLink` 的 URL Scheme。
* 认证 App 回跳时，插件匹配该 scheme 后解析 URL query 参数。
* 插件消费该 URL，避免 Flutter 将 `/?bundleID=...&resultCode=...` 当成页面路由。
* 认证等待超时、启动失败时会返回统一 Map 结果。

## Android层

Android原生代码位于：

```
android/src/main/kotlin/com/neverouo/w_client_flutter/WClientFlutterPlugin.kt
```

Android整体流程：

* 检查国家网络身份认证 App 包名 `cn.cyberIdentity.certification` 是否安装。
* 已安装时通过 `WAuthActivity` 发起认证。
* 未安装时跳转官方下载页。
* 认证结束后通过 `onActivityResult` 返回 `resultCode`、`resultDesc`、`idCardAuthData`、`certPwdData`。
* 认证等待超时、取消或未返回结果时会返回统一 Map 结果。

宿主 Android 项目仍需要按上文说明引入官方 AAR 包，否则无法拉起认证 Activity。

# 异常处理

未安装网络身份认证iOS/Android APP的情况下，会直接进行网页跳转

https://cdnrefresh.ctdidcii.cn/w1/WHClient_H5/Install/UL.html

此为网络身份认证官方下载地址

#### Android sdk 打release包无法拉起，如何配置混淆？
```
-keep class cn.wh.**（*；｝
-keep class com.fort.andJni.**(*;}
```

# 赞助投喂

 <img src="https://github.com/NeverOvO/NeverOvO/blob/main/alipay-2025.JPG" width="250" /><img src="https://github.com/NeverOvO/NeverOvO/blob/main/wepay-2025.JPG" width="250" />
 
 <img src="https://github.com/NeverOvO/NeverOvO/blob/main/okx-usdt-bnb.JPG" width="166" /><img src="https://github.com/NeverOvO/NeverOvO/blob/main/okx-usdt-tron.JPG" width="166" /><img src="https://github.com/NeverOvO/NeverOvO/blob/main/okx-usdt-okx.JPG" width="166" />


