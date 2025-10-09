# w_client_flutter

基于国家网络身份认证iOS/Android SDK进行二次开发的Flutter插件，作者NeverOuO

代码已获得软著保护，登记号为：2025SR1924434

# 更新日志

## 1.0.0 

2025.07.26 
首次提交，基于SDK 1.5.2版本，iOS端采用源码直接引用，Android需要用户自行引入AAR包体。

# 使用方法
## 引入组件

1:本地包体引入：

```
  uuid: ^4.5.1
  w_client_flutter:
    path: ../
```
2:云端引入：w_client_flutter: ^1.0.0

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

Url scheme 地址参数 请替换为申请时地址

### 参数返回

正确返回时，参数返回为一个Map
包含参数为resultCode、resultDesc、idCardAuthData、certPwdData
报错返回时，参数可能为错误代码字符串，请做好异常处理

详细报错信息请查阅机构文档，后续会尽量统一返回样式

## iOS端需要额外配置

#### iOS最低支持为iOS12

在宿主APP的iOS项目中AppDelegate中，添加如下代码，代码为swift，OC代码请自行修改
```
  //手动添加
  override func application(_ app: UIApplication,open url: URL,options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    //scheme（必须与 Info.plist 中的 uLink字段一致）
    if url.scheme == "Url scheme 地址参数" {
        // 通过通知转发给插件监听者
        NotificationCenter.default.post(name: Notification.Name("WClientAuthResultCallback"),object: url,)
        return true
    }
      return super.application(app, open: url, options: options)
    }
```

Url scheme 地址参数 请替换为与Info.plist中一致

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

在宿主APP的android项目中，app/main/AndroidManifest.xml中添加
```
<queries>
  <package android:name= "cn.cyberIdentity.certification"/>
</queries>
```
用于查询国家网络身份认证APP是否安装

#### cn.cyberIdentity.certification即国家网络身份认证APP包名

在宿主APP的android项目中，Android根目录下添加libs文件夹，与app文件夹同级，引入w_auth-release.aar包
具体包体可以导入example/android/libs下的w_auth-release.aar包

在宿主Android项目的 app/build.gradle 中最下方添加代码，引入该aar包，代码写法为kt风格，java请自行修改
```
dependencies {
    implementation(fileTree("libs") {
        include("*.aar")
    })
}
```
此处为简略写法，全部引入，忽略名称

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






