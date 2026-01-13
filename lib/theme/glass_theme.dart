import 'package:flutter/material.dart';

/// 全局 Glassmorphism 主題配置
/// 在這裡統一調整所有發光效果和玻璃質感參數
class GlassTheme {
  // ==================== 基礎發光參數 ====================
  
  /// 全局發光強度倍數 (0.0 - 2.0)
  /// 調整這個值可以統一增強或減弱所有發光效果
  /// 1.0 = 預設強度, 1.5 = 增強 50%, 0.5 = 減弱 50%
  static const double globalGlowIntensity = 0.6;
  
  /// 預設發光模糊半徑
  static const double defaultGlowBlur = 20.0;
  
  /// 預設發光擴散範圍
  static const double defaultGlowSpread = 20.0;
  
  /// 預設發光透明度 (0.0 - 1.0)
  static const double defaultGlowAlpha = 0.1;
  
  // ==================== 玻璃質感參數 ====================
  
  /// 預設玻璃模糊程度
  static const double defaultBlur = 10.0;
  
  /// 預設玻璃透明度
  static const double defaultOpacity = 0.9;
  
  // ==================== 不同元件的發光強度 ====================
  
  /// 按鈕發光強度
  static double get buttonGlowBlur => 25.0 * globalGlowIntensity;
  static double get buttonGlowSpread => 5.0 * globalGlowIntensity;
  static double get buttonGlowAlpha => 0.4 * globalGlowIntensity;
  
  /// 卡片發光強度
  static double get cardGlowBlur => 25.0 * globalGlowIntensity;
  static double get cardGlowSpread => 5.0 * globalGlowIntensity;
  static double get cardGlowAlpha => 0.4 * globalGlowIntensity;
  
  /// 音樂專輯發光強度（較強）
  static double get albumGlowBlur => 30.0 * globalGlowIntensity;
  static double get albumGlowSpread => 5.0 * globalGlowIntensity;
  static double get albumGlowAlpha => 0.4 * globalGlowIntensity;
  
  /// 輸入框發光強度
  static double get inputGlowBlur => 20.0 * globalGlowIntensity;
  static double get inputGlowSpread => 4.0 * globalGlowIntensity;
  static double get inputGlowAlpha => 0.35 * globalGlowIntensity;
  
  /// 導航欄發光強度
  static double get navBarGlowBlur => 20.0 * globalGlowIntensity;
  static double get navBarGlowSpread => 4.0 * globalGlowIntensity;
  static double get navBarGlowAlpha => 0.35 * globalGlowIntensity;
  
  /// 最小化播放器發光強度
  static double get miniPlayerGlowBlur => 25.0 * globalGlowIntensity;
  static double get miniPlayerGlowSpread => 5.0 * globalGlowIntensity;
  static double get miniPlayerGlowAlpha => 0.4 * globalGlowIntensity;
  
  /// 健康數據卡片發光強度（較弱）
  static double get healthDataGlowBlur => 15.0 * globalGlowIntensity;
  static double get healthDataGlowSpread => 3.0 * globalGlowIntensity;
  static double get healthDataGlowAlpha => 0.3 * globalGlowIntensity;
  
  // ==================== 預設顏色 ====================
  
  /// 預設紫色發光顏色
  static const Color defaultPurpleGlow = Color(0xFF9C27B0);
  
  /// 預設綠色發光顏色（Health Connect）
  static Color get defaultGreenGlow => Colors.green.shade600;
  
  /// 預設白色發光顏色
  static const Color defaultWhiteGlow = Colors.white;
  
  // ==================== 便捷方法 ====================
  
  /// 獲取調整後的發光透明度（確保在有效範圍內）
  static double getAdjustedAlpha(double baseAlpha) {
    final adjusted = baseAlpha * globalGlowIntensity;
    return adjusted.clamp(0.0, 1.0);
  }
  
  /// 獲取調整後的模糊半徑（如果全局強度為 0 則返回 0）
  static double getAdjustedBlur(double baseBlur) {
    if (globalGlowIntensity == 0) return 0;
    return baseBlur * globalGlowIntensity;
  }
  
  /// 獲取調整後的擴散範圍（如果全局強度為 0 則返回 0）
  static double getAdjustedSpread(double baseSpread) {
    if (globalGlowIntensity == 0) return 0;
    return baseSpread * globalGlowIntensity;
  }
}

/// 快速存取全局發光主題
class Glow {
  // 快速存取發光參數（自動應用全局倍數）
  static double get blur => GlassTheme.getAdjustedBlur(GlassTheme.defaultGlowBlur);
  static double get spread => GlassTheme.getAdjustedSpread(GlassTheme.defaultGlowSpread);
  static double get alpha => GlassTheme.getAdjustedAlpha(GlassTheme.defaultGlowAlpha);
  
  // 快速存取不同元件的發光參數（已包含全局倍數）
  static double get buttonBlur => GlassTheme.buttonGlowBlur;
  static double get buttonSpread => GlassTheme.buttonGlowSpread;
  static double get buttonAlpha => GlassTheme.buttonGlowAlpha;
  
  static double get cardBlur => GlassTheme.cardGlowBlur;
  static double get cardSpread => GlassTheme.cardGlowSpread;
  static double get cardAlpha => GlassTheme.cardGlowAlpha;
  
  static double get albumBlur => GlassTheme.albumGlowBlur;
  static double get albumSpread => GlassTheme.albumGlowSpread;
  static double get albumAlpha => GlassTheme.albumGlowAlpha;
  
  static double get inputBlur => GlassTheme.inputGlowBlur;
  static double get inputSpread => GlassTheme.inputGlowSpread;
  static double get inputAlpha => GlassTheme.inputGlowAlpha;
  
  static double get navBarBlur => GlassTheme.navBarGlowBlur;
  static double get navBarSpread => GlassTheme.navBarGlowSpread;
  static double get navBarAlpha => GlassTheme.navBarGlowAlpha;
  
  static double get miniPlayerBlur => GlassTheme.miniPlayerGlowBlur;
  static double get miniPlayerSpread => GlassTheme.miniPlayerGlowSpread;
  static double get miniPlayerAlpha => GlassTheme.miniPlayerGlowAlpha;
  
  static double get healthDataBlur => GlassTheme.healthDataGlowBlur;
  static double get healthDataSpread => GlassTheme.healthDataGlowSpread;
  static double get healthDataAlpha => GlassTheme.healthDataGlowAlpha;
  
  // 快速存取顏色
  static Color get purple => GlassTheme.defaultPurpleGlow;
  static Color get green => GlassTheme.defaultGreenGlow;
  static Color get white => GlassTheme.defaultWhiteGlow;
}
