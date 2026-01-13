package com.example.flutter_application_1

import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.records.TotalCaloriesBurnedRecord
import androidx.health.connect.client.records.DistanceRecord
import androidx.health.connect.client.records.SleepSessionRecord
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "samsung_health_channel"
    private val TAG = "MainActivity"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestHealthConnectPermissionsNative" -> {
                    requestHealthConnectPermissionsNative(result)
                }
                "initializeSamsungHealth" -> {
                    // Samsung Health SDK 無法使用，返回失敗讓 WatchDataService 使用 Health Connect
                    Log.i(TAG, "Samsung Health SDK 不可用，使用 Health Connect")
                    result.success(mapOf(
                        "success" to false,
                        "message" to "請使用 Health Connect"
                    ))
                }
                "requestPermissions" -> {
                    Log.i(TAG, "請透過 Health Connect 請求權限")
                    result.success(mapOf(
                        "success" to false,
                        "message" to "使用 health 套件的 requestAuthorization"
                    ))
                }
                "getSteps", "getHeartRate" -> {
                    result.success(mapOf(
                        "success" to false,
                        "message" to "請使用 Flutter health 套件讀取數據"
                    ))
                }
                "openHealthConnectSettings" -> {
                    try {
                        openHealthConnectSettings()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "無法打開設置: ${e.message}", null)
                    }
                }
                "checkSamsungHealth" -> {
                    val isInstalled = isSamsungHealthInstalled()
                    result.success(isInstalled)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun requestHealthConnectPermissionsNative(result: MethodChannel.Result) {
        try {
            Log.i(TAG, "🔐 使用原生 Health Connect API 請求權限")
            
            // 建立權限集合
            val permissions = setOf(
                HealthPermission.getReadPermission(HeartRateRecord::class),
                HealthPermission.getReadPermission(StepsRecord::class),
                HealthPermission.getReadPermission(TotalCaloriesBurnedRecord::class),
                HealthPermission.getReadPermission(DistanceRecord::class),
                HealthPermission.getReadPermission(SleepSessionRecord::class)
            )
            
            // 建立權限請求 Intent
            val intent = PermissionController.createRequestPermissionResultContract()
                .createIntent(this, permissions)
            
            Log.i(TAG, "✅ 啟動 Health Connect 權限對話框")
            startActivityForResult(intent, HEALTH_CONNECT_PERMISSION_REQUEST)
            
            result.success(mapOf(
                "success" to true,
                "message" to "Health Connect 權限對話框已啟動"
            ))
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ 請求權限失敗: ${e.message}", e)
            result.error("PERMISSION_ERROR", "請求失敗: ${e.message}", null)
        }
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == HEALTH_CONNECT_PERMISSION_REQUEST) {
            Log.i(TAG, "✅ Health Connect 權限對話框已關閉，resultCode=$resultCode")
            // 權限已經處理完畢，Flutter 端可以再次檢查權限狀態
        }
    }
    
    companion object {
        private const val HEALTH_CONNECT_PERMISSION_REQUEST = 1001
    }
    
    private fun openHealthConnectSettings() {
        try {
            val intent = Intent().apply {
                action = "android.intent.action.VIEW_PERMISSION_USAGE"
                putExtra("android.intent.extra.PACKAGE_NAME", packageName)
                setPackage("com.google.android.apps.healthdata")
            }
            startActivity(intent)
        } catch (e: Exception) {
            try {
                val intent = packageManager.getLaunchIntentForPackage("com.google.android.apps.healthdata")
                if (intent != null) {
                    startActivity(intent)
                } else {
                    throw Exception("Health Connect 未安裝")
                }
            } catch (e2: Exception) {
                throw Exception("無法打開 Health Connect: ${e2.message}")
            }
        }
    }
    
    private fun isSamsungHealthInstalled(): Boolean {
        return try {
            packageManager.getPackageInfo("com.sec.android.app.shealth", 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
}
