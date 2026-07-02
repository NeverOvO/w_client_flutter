package com.neverouo.w_client_flutter

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
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
  private var eventChannel: EventChannel? = null
  private var eventSink: EventChannel.EventSink? = null

  private var activity: Activity? = null
  private var activityBinding: ActivityPluginBinding? = null
  private var pendingResult: MethodChannel.Result? = null
  private val mainHandler = Handler(Looper.getMainLooper())
  private var timeoutRunnable: Runnable? = null
  private val requestCode = 10001
  private val authTimeoutMs = 120_000L

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "w_client_flutter")
    channel.setMethodCallHandler(this)

    // 初始化认证结果事件通道
    eventChannel = EventChannel(binding.binaryMessenger, "w_client_flutter/events")
    eventChannel?.setStreamHandler(this)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel?.setStreamHandler(null)
    eventChannel = null
    eventSink = null
    clearAuthTimeout()
    pendingResult = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activityBinding = binding
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activityBinding?.removeActivityResultListener(this)
    activityBinding = null
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
      "getPlatformVersion" -> {
        result.success("Android " + Build.VERSION.RELEASE)
      }

      "getVersion" -> {
        result.success("1.5.2") // SDK版本号，可以动态替换
      }

      "getAuthResult" -> {
        val args = call.arguments as? Map<*, *>
        if (args == null) {
          result.success(authResult("INVALID_ARGUMENT", "参数不能为空"))
          return
        }

        val currentActivity = activity
        if (currentActivity == null) {
          result.success(authResult("NO_ACTIVITY", "当前Activity为空"))
          return
        }

        if (pendingResult != null) {
          // 如果上一次调用还没返回，先返回错误避免重复
          result.success(authResult("AUTH_IN_PROGRESS", "已有认证请求正在处理中"))
          return
        }

        // 检查App是否安装
        val targetPackage = "cn.cyberIdentity.certification"//国家网络身份认证APP包名
        if (!isAppInstalled(targetPackage)) {
          // 未安装，打开下载页
          openDownloadPage()
          // 立即返回未安装结果给 Dart
          result.success(authResult("C0412002", "国家网络身份认证APP尚未安装"))
          return
        }

        try {

          val currentPackageName = currentActivity.packageName
          val intent = Intent()
          // 注意这里的包名和类名，确保与你实际的一致
          intent.setClassName(targetPackage, "cn.wh.project.view.v.authorization.WAuthActivity")

          args["orgID"]?.let { intent.putExtra("orgID", it.toString()) }
          args["appID"]?.let { intent.putExtra("appID", it.toString()) }
          args["bizSeq"]?.let { intent.putExtra("bizSeq", it.toString()) }
          args["type"]?.let { intent.putExtra("type", it.toString()) }
          args["miniProgramID"]?.let { intent.putExtra("miniProgramID", it.toString()) }
          args["miniProPgramPlatformID"]?.let { intent.putExtra("miniProPgramPlatformID", it.toString()) }
          intent.putExtra("clsT", currentActivity.javaClass.name)

          intent.putExtra("packageName", currentPackageName)

          pendingResult = result
          currentActivity.startActivityForResult(intent, requestCode)
          startAuthTimeout()
        } catch (e: Exception) {
          clearAuthTimeout()
          pendingResult = null
          result.success(authResult("C0412001", "认证启动失败: ${e.message}"))
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

        if (data == null) {
          resultMap["resultCode"] = if (resultCode == Activity.RESULT_CANCELED) "C0412004" else "C0412001"
          resultMap["resultDesc"] = if (resultCode == Activity.RESULT_CANCELED) "认证取消或未返回结果" else "认证未返回结果"
        } else {
          resultMap["resultCode"] = data.getStringExtra("resultCode") ?: ""
          resultMap["resultDesc"] = data.getStringExtra("resultDesc") ?: ""
          resultMap["idCardAuthData"] = data.getStringExtra("idCardAuthData") ?: ""
          resultMap["certPwdData"] = data.getStringExtra("certPwdData") ?: ""
        }

        finishAuth(resultMap)
      } catch (e: Exception) {
        Log.e("WClientFlutterPlugin", "解析结果失败: ${e.message}", e)
        finishAuth(authResult("RESULT_PARSE_ERROR", "解析认证结果失败: ${e.message}"))
      }
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
      val packageManager = activity?.packageManager ?: return false
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
      } else {
        @Suppress("DEPRECATION")
        packageManager.getPackageInfo(packageName, 0)
      }
      true
    } catch (e: Exception) {
      false
    }
  }

  // 跳转下载页
  private fun openDownloadPage() {
    try {
      val intent = Intent(Intent.ACTION_VIEW)
      intent.data = android.net.Uri.parse("https://cdnrefresh.ctdidcii.cn/w1/WHClient_H5/Install/UL.html")
      intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
      activity?.startActivity(intent)
    } catch (e: Exception) {
      Log.e("WClientFlutterPlugin", "打开下载页失败: ${e.message}", e)
    }
  }

  private fun authResult(resultCode: String, resultDesc: String): Map<String, Any?> {
    return mapOf(
      "resultCode" to resultCode,
      "resultDesc" to resultDesc
    )
  }

  private fun finishAuth(resultMap: Map<String, Any?>) {
    clearAuthTimeout()
    pendingResult?.success(resultMap)
    pendingResult = null
    eventSink?.success(resultMap)
  }

  private fun startAuthTimeout() {
    clearAuthTimeout()
    timeoutRunnable = Runnable {
      finishAuth(authResult("C0412003", "认证等待超时"))
    }
    mainHandler.postDelayed(timeoutRunnable!!, authTimeoutMs)
  }

  private fun clearAuthTimeout() {
    timeoutRunnable?.let { mainHandler.removeCallbacks(it) }
    timeoutRunnable = null
  }
}
