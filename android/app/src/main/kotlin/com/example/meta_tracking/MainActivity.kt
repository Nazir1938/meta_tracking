package com.example.meta_tracking

import android.os.BatteryManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val BATTERY_CHANNEL = "com.example.meta_tracking/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BATTERY_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryLevel" -> {
                    val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                    val level = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
                    if (level != Integer.MIN_VALUE) {
                        result.success(level)
                    } else {
                        result.error("UNAVAILABLE", "Battery level not available", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}