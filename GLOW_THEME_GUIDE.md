# 🎨 發光效果調整指南

## 📍 統一調整所有發光效果

所有發光效果的參數都集中在一個文件中，方便統一管理：

**文件位置：** `lib/theme/glass_theme.dart`

## 🔧 快速調整

### 1. 調整全局發光強度（最簡單）

在 `glass_theme.dart` 第 9 行，修改 `globalGlowIntensity` 的值：

```dart
static const double globalGlowIntensity = 1.0;  // 預設值
```

**效果：**
- `1.0` = 預設強度
- `1.5` = 增強 50%（發光更明顯）
- `0.5` = 減弱 50%（發光更柔和）
- `2.0` = 增強 100%（發光非常明顯）
- `0.0` = 完全沒有發光

### 2. 調整個別元件的發光強度

如果你想針對特定元件調整，可以修改以下參數：

```dart
// 按鈕發光（登入按鈕、Google 按鈕等）
static double get buttonGlowBlur => 15.0 * globalGlowIntensity;

// 卡片發光（用戶資訊、統計數據等）
static double get cardGlowBlur => 15.0 * globalGlowIntensity;

// 音樂專輯發光（較強，讓專輯更突出）
static double get albumGlowBlur => 30.0 * globalGlowIntensity;

// 輸入框發光（聊天輸入框、登入表單等）
static double get inputGlowBlur => 15.0 * globalGlowIntensity;

// 導航欄發光（底部導航欄）
static double get navBarGlowBlur => 15.0 * globalGlowIntensity;

// 播放器發光（最小化音樂播放器）
static double get miniPlayerGlowBlur => 15.0 * globalGlowIntensity;

// 健康數據發光（手錶數據卡片，較弱）
static double get healthDataGlowBlur => 10.0 * globalGlowIntensity;
```

### 3. 調整發光顏色

預設紫色發光顏色定義在第 71 行：

```dart
static const Color defaultPurpleGlow = Color(0xFF9C27B0);
```

可以改成其他顏色，例如：
- `Color(0xFFBA68C8)` - 淺紫色
- `Color(0xFF7B1FA2)` - 深紫色
- `Color(0xFFE91E63)` - 粉紅色
- `Color(0xFF3F51B5)` - 藍色

### 4. 調整玻璃透明度

```dart
static const double defaultOpacity = 0.1;  // 玻璃透明度
```

- 數值越大，玻璃越不透明
- 建議範圍：`0.05` - `0.3`

## 📝 使用範例

### 在代碼中使用全局主題

已經應用的範例（你可以參考這個模式）：

```dart
// 使用預設發光參數
BoxShadow(
  color: Glow.purple.withValues(alpha: Glow.alpha),
  blurRadius: Glow.navBarBlur,
  spreadRadius: GlassTheme.navBarGlowSpread,
)

// 使用特定元件的發光參數
GlassWithGlow(
  glowBlur: GlassTheme.albumGlowBlur,
  glowSpread: GlassTheme.albumGlowSpread,
  glowColor: song.color,
  child: ...
)
```

## 🎯 建議設定值

### 柔和發光（適合長時間使用）
```dart
static const double globalGlowIntensity = 0.7;
```

### 標準發光（預設，平衡美觀與舒適）
```dart
static const double globalGlowIntensity = 1.0;
```

### 強烈發光（適合展示、截圖）
```dart
static const double globalGlowIntensity = 1.5;
```

### 極致發光（非常醒目）
```dart
static const double globalGlowIntensity = 2.0;
```

## 💡 提示

1. **修改後需要重新啟動應用** - Hot reload 可能無法完全反映變化
2. **建議先調整 `globalGlowIntensity`** - 這會影響所有發光效果
3. **如果想完全關閉發光** - 設定 `globalGlowIntensity = 0.0`
4. **在不同設備上測試** - 不同螢幕亮度可能影響發光視覺效果

## 🔄 如何應用到現有代碼

如果你想在其他文件中使用統一的發光主題，只需：

1. 導入主題：
```dart
import '../theme/glass_theme.dart';
```

2. 使用主題參數：
```dart
GlassWithGlow(
  glowBlur: Glow.blur,
  glowSpread: GlassTheme.defaultGlowSpread,
  glowColor: Glow.purple,
  // ...
)
```
