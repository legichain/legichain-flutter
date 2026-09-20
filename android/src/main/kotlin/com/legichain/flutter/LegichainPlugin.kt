package com.legichain.flutter

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import com.legichain.kyc.KycOptions
import com.legichain.kyc.LegichainKyc
import org.json.JSONObject

class LegichainPlugin: FlutterPlugin,ActivityAware,MethodChannel.MethodCallHandler,PluginRegistry.ActivityResultListener {
    private var activity: Activity?=null
    private var binding: ActivityPluginBinding?=null
    private var pending: MethodChannel.Result?=null
    private lateinit var channel: MethodChannel
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel=MethodChannel(binding.binaryMessenger,"legichain/kyc");channel.setMethodCallHandler(this)
    }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null);pending?.error("CANCELLED","Flutter engine closed",null);pending=null
    }
    override fun onAttachedToActivity(binding: ActivityPluginBinding) { this.binding=binding;activity=binding.activity;binding.addActivityResultListener(this) }
    override fun onDetachedFromActivityForConfigChanges() { binding?.removeActivityResultListener(this);binding=null;activity=null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { onAttachedToActivity(binding) }
    override fun onDetachedFromActivity() { onDetachedFromActivityForConfigChanges();pending?.error("CANCELLED","Activity closed",null);pending=null }
    override fun onMethodCall(call: MethodCall,result: MethodChannel.Result) {
        if(call.method!="start") { result.notImplemented();return }
        val host=activity ?: run { result.error("NO_ACTIVITY","Foreground activity required",null);return }
        if(pending!=null) { result.error("BUSY","A KYC flow is already running",null);return }
        try {
            val config=KycOptions(call.argument<String>("apiToken").orEmpty(),call.argument<String>("baseUrl") ?: "https://api.legichain.com",
                call.argument<String>("language") ?: "tr",JSONObject(call.argument<Map<String,Any>>("application") ?: emptyMap<String,Any>()))
            pending=result;host.startActivityForResult(LegichainKyc.intent(host,config),46722)
        } catch(e: Exception) { pending=null;result.error("INVALID_OPTIONS","Invalid KYC options",null) }
    }
    override fun onActivityResult(requestCode: Int,resultCode: Int,data: Intent?): Boolean {
        if(requestCode!=46722) return false
        val result=pending ?: return false;pending=null
        val value=JSONObject(LegichainKyc.result(data) ?: "{\"status\":\"cancelled\",\"application_id\":\"\"}")
        result.success(mapOf("status" to value.getString("status"),"application_id" to value.optString("application_id")));return true
    }
}
