package com.neverouo.w_client_flutter

import android.app.Activity
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry

class WClientFlutterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
  ActivityAware, PluginRegistry.ActivityResultListener, EventChannel.StreamHandler {

  private lateinit var channel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private var eventSink: EventChannel.EventSink? = null

  private var activity: Activity? = null
  private var pendingResult: MethodChannel.Result? = null
  private val requestCode = 10001

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "w_client_flutter")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "getVersion" -> {
        result.success("1.5.2") // SDK版本号，可以动态替换
      }

      "getAuthResult" -> {
        val args = call.arguments as? Map<*, *>
        if (args == null) {
          result.error("INVALID_ARGUMENT", "参数不能为空", null)
          return
        }

        // 检查App是否安装
        val targetPackage = "cn.cyberIdentity.certification"//国家网络身份认证APP包名
        if (!isAppInstalled(targetPackage)) {
          // 未安装，打开下载页
          openDownloadPage()
          // 立即返回 false 给 Dart 表示没安装
          result.success("C0412002")//国家网络身份认证APP尚未安装
          return
        }

        try {

          val currentPackageName = activity?.packageName ?: "unknown"
          val intent = Intent()
          // 注意这里的包名和类名，确保与你实际的一致
          intent.setClassName(targetPackage, "cn.wh.project.view.v.authorization.WAuthActivity")

          args["orgID"]?.let { intent.putExtra("orgID", it as String) }
          args["appID"]?.let { intent.putExtra("appID", it as String) }
          args["bizSeq"]?.let { intent.putExtra("bizSeq", it as String) }
          args["type"]?.let { intent.putExtra("type", it as String) }
          args["clsT"]?.let { intent.putExtra("clsT", activity?.javaClass?.name) }

          intent.putExtra("packageName", currentPackageName)

          if (pendingResult != null) {
            // 如果上一次调用还没返回，先返回错误避免重复
            result.success("已有认证请求正在处理中")
            return
          }

          pendingResult = result
          activity?.startActivityForResult(intent, requestCode)
        } catch (e: Exception) {
          result.success("认证启动失败: ${e.message}")
//          Log.e("WClientFlutterPlugin", "认证启动失败: ${e.localizedMessage}", e)
//          result.error("LAUNCH_ERROR", "认证启动失败: ${e.message}", null)
        }
      }

      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode == this.requestCode) {
      try {
        val resultMap = mutableMapOf<String, Any?>()

        resultMap["resultCode"] = data?.getStringExtra("resultCode") ?: ""
        resultMap["resultDesc"] = data?.getStringExtra("resultDesc") ?: ""
        resultMap["idCardAuthData"] = data?.getStringExtra("idCardAuthData") ?: ""
        resultMap["certPwdData"] = data?.getStringExtra("certPwdData") ?: ""

        pendingResult?.success(resultMap)
        eventSink?.success(resultMap)
      } catch (e: Exception) {
        Log.e("WClientFlutterPlugin", "解析结果失败: ${e.message}", e)
        pendingResult?.error("RESULT_PARSE_ERROR", "解析认证结果失败: ${e.message}", null)
      }
      pendingResult = null
      return true
    }
    return false
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  // 判断包是否安装
  private fun isAppInstalled(packageName: String): Boolean {
    return try {
      activity?.packageManager?.getPackageInfo(packageName, 0)
      true
    } catch (e: Exception) {
      false
    }
  }

  // 跳转下载页
  private fun openDownloadPage() {
    val intent = Intent(Intent.ACTION_VIEW)
    intent.data = android.net.Uri.parse("https://cdnrefresh.ctdidcii.cn/w1/WHClient_H5/Install/UL.html")
    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
    activity?.startActivity(intent)
  }
}
