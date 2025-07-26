import 'dart:io';

import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';
import 'package:w_client_flutter/w_client_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  String paramsStr = "";

  @override
  void initState() {
    super.initState();
  }


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
    setState(() {
      paramsStr = authResult.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('国家数字身份认证插件示例'),
        ),
        body: Center(
          child: InkWell(
            onTap: (){
              doAuth();
            },
            child: ListView(
              children: [
                SizedBox(height: 20,),
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    //边框圆角设置
                    border: Border.all(width: 1, color: Color.fromRGBO(15, 159, 131, 1)),
                    borderRadius: BorderRadius.all(Radius.circular(3.0)),
                  ),
                  child: Text("拉起国家数字身份认证APP"),
                ),
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Text("回调结果:$paramsStr"),
                ),
              ],
            ),
            
          ),
        ),
      ),
    );
  }
}
