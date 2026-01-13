import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class WatchDataService {
  final Health _health = Health();
  static const platform = MethodChannel('samsung_health_channel');
  
  bool _isInitialized = false;
  bool _isAuthorized = false;
  bool _useSamsungSDK = false;
  
  // Health Connect 需要的數據類型 - 只保留心率和步數（專題重點）
  final List<HealthDataType> _healthDataTypes = [
    HealthDataType.HEART_RATE,  // 專題重點：心率
    HealthDataType.STEPS,       // 方便檢查：步數
  ];
  
  // 初始化並請求 Health Connect 權限
  Future<bool> initialize() async {
    if (_isInitialized) return _isAuthorized;
    
    try {
      debugPrint('🔄 嘗試初始化 Samsung Health SDK...');
      
      // 先嘗試 Samsung Health SDK
      try {
        final sdkResult = await platform.invokeMethod('initializeSamsungHealth');
        if (sdkResult is Map && sdkResult['success'] == true) {
          debugPrint('✅ Samsung Health SDK 連接成功');
          
          // 請求權限
          final permResult = await platform.invokeMethod('requestPermissions');
          if (permResult is Map && permResult['success'] == true) {
            debugPrint('✅ Samsung Health 權限已授予');
            _isAuthorized = true;
            _useSamsungSDK = true;
            _isInitialized = true;
            return true;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Samsung Health SDK 不可用: $e');
      }
      
      // 如果 SDK 失敗，嘗試 Health Connect
      debugPrint('🔄 嘗試 Health Connect...');
      
      // ⚠️ 必須先 configure() - 官方文件要求！
      debugPrint('🔧 配置 Health Connect...');
      await _health.configure();
      debugPrint('✅ Health Connect 配置完成');
      
      // 請求基本 Android 權限
      final activityStatus = await Permission.activityRecognition.request();
      final locationStatus = await Permission.location.request();
      
      debugPrint('✅ Activity Recognition: ${activityStatus.isGranted}');
      debugPrint('✅ Location: ${locationStatus.isGranted}');
      
      // 直接請求權限（不先檢查 hasPermissions，避免「需要更新」狀態）
      debugPrint('📋 直接請求 Health Connect 權限...');
      bool authorized = false;
      
      try {
        authorized = await _health.requestAuthorization(
          _healthDataTypes,
          permissions: List.generate(
            _healthDataTypes.length, 
            (_) => HealthDataAccess.READ,
          ),
        );
        debugPrint('✅ Health Connect 授權結果: $authorized');
      } catch (e) {
        debugPrint('⚠️ Health Connect 授權錯誤: $e');
        debugPrint('⚠️ 錯誤詳情: ${e.toString()}');
      }
      
      _isAuthorized = authorized;
      _isInitialized = true;
      
      if (authorized) {
        debugPrint('✅ Health Connect 連接成功');
      } else {
        debugPrint('⚠️ Health Connect 權限未授予');
      }
      
      return authorized;
    } catch (e) {
      debugPrint('❌ 初始化失敗: $e');
      _isInitialized = true;
      return false;
    }
  }
  
  // 獲取實時心率 - 只返回真實數據
  Stream<int> getRealtimeHeartRate() async* {
    if (!_isAuthorized) {
      debugPrint('⚠️ 未授權，無法讀取心率');
      yield 0;
      return;
    }
    
    while (true) {
      try {
        // 優先使用 Samsung Health SDK
        if (_useSamsungSDK) {
          final result = await platform.invokeMethod('getHeartRate');
          if (result is Map && result['success'] == true) {
            final heartRate = result['heartRate'] as int;
            if (heartRate > 0) {
              debugPrint('💓 心率: $heartRate bpm [samsung_sdk]');
              yield heartRate;
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }
          }
        }
        
        // 使用 Health Connect 獲取今天的心率數據（和步數邏輯一致）
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        
        debugPrint('🔍 [心率] 查詢時間範圍: $startOfDay ~ $now');
        
        final healthData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.HEART_RATE],
          startTime: startOfDay,
          endTime: now,
        );
        
        debugPrint('📊 [心率] 找到 ${healthData.length} 筆數據');
        
        if (healthData.isNotEmpty) {
          // 找最新的心率數據
          final latestData = healthData.last;
          final heartRate = (latestData.value as NumericHealthValue).numericValue.round();
          final dataTime = latestData.dateTo;
          final ageMinutes = now.difference(dataTime).inMinutes;
          
          debugPrint('💓 [心率] $heartRate bpm ($ageMinutes分鐘前: $dataTime)');
          
          // 如果數據太舊（超過30分鐘），也顯示但標記為舊數據
          if (ageMinutes > 30) {
            debugPrint('⚠️ [心率] 數據較舊，已超過 $ageMinutes 分鐘');
          }
          
          yield heartRate;
        } else {
          debugPrint('⚠️ [心率] 無數據 - 今天 ${startOfDay.hour}:${startOfDay.minute} 至今沒有心率記錄');
          yield 0;
        }
      } catch (e, stackTrace) {
        debugPrint('❌ [心率] 讀取錯誤: $e');
        debugPrint('Stack trace: $stackTrace');
        yield 0;
      }
      
      await Future.delayed(const Duration(seconds: 3));  // 3 秒更新一次
    }
  }
  
  // 獲取實時步數 - 只返回真實數據
  Stream<int> getRealtimeSteps() async* {
    if (!_isAuthorized) {
      debugPrint('⚠️ 未授權，無法讀取步數');
      yield 0;
      return;
    }
    
    while (true) {
      try {
        // 優先使用 Samsung Health SDK
        if (_useSamsungSDK) {
          final result = await platform.invokeMethod('getSteps');
          if (result is Map && result['success'] == true) {
            final steps = result['steps'] as int;
            if (steps > 0) {
              debugPrint('🚶 步數: $steps [samsung_sdk]');
              yield steps;
              await Future.delayed(const Duration(seconds: 5));
              continue;
            }
          }
        }
        
        // 使用 Health Connect 獲取今天的步數
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        
        debugPrint('🔍 [步數] 查詢時間範圍: $startOfDay ~ $now');
        
        final healthData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.STEPS],
          startTime: startOfDay,
          endTime: now,
        );
        
        debugPrint('📊 [步數] 找到 ${healthData.length} 筆數據');
        
        if (healthData.isNotEmpty) {
          int totalSteps = 0;
          for (var data in healthData) {
            totalSteps += (data.value as NumericHealthValue).numericValue.round();
          }
          debugPrint('🚶 [步數] $totalSteps steps (累計 ${healthData.length} 筆記錄)');
          yield totalSteps;
        } else {
          debugPrint('⚠️ [步數] 無數據');
          yield 0;
        }
      } catch (e) {
        debugPrint('❌ [步數] 讀取錯誤: $e');
        yield 0;
      }
      
      await Future.delayed(const Duration(seconds: 5));  // 步數 5 秒更新一次
    }
  }
  
  bool get isConnected => _isAuthorized;
  
  // ✨ 診斷方法 - 檢查心率和步數的可用性
  Future<Map<String, dynamic>> diagnoseDataAvailability() async {
    if (!_isAuthorized) {
      return {
        'authorized': false,
        'message': '未授權 Health Connect',
      };
    }
    
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final result = <String, dynamic>{
      'authorized': true,
      'timestamp': now.toIso8601String(),
    };
    
    // 只檢查心率和步數
    final dataTypes = {
      'heart_rate': HealthDataType.HEART_RATE,
      'steps': HealthDataType.STEPS,
    };
    
    for (final entry in dataTypes.entries) {
      try {
        final data = await _health.getHealthDataFromTypes(
          types: [entry.value],
          startTime: yesterday,
          endTime: now,
        );
        
        result[entry.key] = {
          'available': data.isNotEmpty,
          'count': data.length,
          'latest': data.isNotEmpty 
            ? data.last.dateTo.toIso8601String()
            : null,
        };
        
        debugPrint('📊 ${entry.key}: ${data.length} 筆數據');
      } catch (e) {
        result[entry.key] = {
          'available': false,
          'error': e.toString(),
        };
        debugPrint('❌ ${entry.key} 查詢失敗: $e');
      }
    }
    
    return result;
  }
}