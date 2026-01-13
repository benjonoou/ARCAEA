# 🎵 聽歌記錄與統計功能說明

## ✅ 已實作的功能

### 1. 自動記錄播放歷史
**位置**: `lib/services/music_player_service.dart`

**功能說明**:
- ✅ 當歌曲開始播放時，自動記錄開始時間
- ✅ 當歌曲播放完成時，記錄到資料庫
- ✅ 當切換歌曲時，記錄上一首的播放時間
- ✅ 記錄內容包括：
  - 歌曲名稱
  - 藝人
  - 專輯
  - 播放時長（秒）
  - 是否完整播放

**程式碼邏輯**:
```dart
// 播放開始時
if (state == PlayerState.playing && _playStartTime == null) {
  _playStartTime = DateTime.now();
  debugPrint('🎵 開始播放：${_currentSong?.title}');
}

// 播放完成時
if (state == PlayerState.completed) {
  _recordListeningHistory(completed: true);
  playNext();
}

// 切換歌曲時
if (_currentSong != null && _playStartTime != null) {
  await _recordListeningHistory(completed: false);
}
```

### 2. 顯示真實統計數據
**位置**: `lib/main.dart` - `HomePage`

**顯示的統計**:
- **Times**: 總播放次數
- **Duration**: 總播放時長（分鐘）
- **Songs**: 喜愛的歌曲數量
- **Artist**: 喜愛的藝人數量
- **Album**: 喜愛的專輯數量

**資料來源**:
```dart
final stats = await _userDataService.getUserStats();
_totalPlayCount = stats?['total_play_count'] ?? 0;
_totalDuration = ((stats?['total_duration'] ?? 0) / 60).round();
```

### 3. 自動更新機制
**更新時機**:
1. **頁面載入時**: `initState()` 自動載入
2. **App 回到前景時**: 使用 `WidgetsBindingObserver` 監聽
3. **手動重新整理**: 點擊右上角的 🔄 按鈕

**程式碼**:
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    debugPrint('🔄 App resumed - 重新載入統計數據');
    _loadUserStats();
  }
}
```

## 📊 資料庫結構

### listening_history 表
記錄每次播放的詳細資訊：

| 欄位 | 類型 | 說明 |
|------|------|------|
| id | UUID | 主鍵 |
| user_id | UUID | 使用者 ID |
| song_title | TEXT | 歌曲名稱 |
| artist | TEXT | 藝人 |
| album | TEXT | 專輯 |
| duration | INTEGER | 播放時長（秒） |
| completed | BOOLEAN | 是否完整播放 |
| played_at | TIMESTAMPTZ | 播放時間 |

### user_stats 表
匯總統計資料（由 Trigger 自動更新）：

| 欄位 | 類型 | 說明 |
|------|------|------|
| user_id | UUID | 使用者 ID |
| total_play_count | INTEGER | 總播放次數 |
| total_duration | INTEGER | 總播放時長（秒） |
| favorite_songs_count | INTEGER | 喜愛歌曲數 |
| favorite_artists_count | INTEGER | 喜愛藝人數 |
| favorite_albums_count | INTEGER | 喜愛專輯數 |
| last_active_at | TIMESTAMPTZ | 最後活動時間 |

## 🧪 測試方法

### 1. 測試播放記錄
```
1. 登入 App
2. 播放一首歌（至少 5 秒）
3. 到 Supabase Dashboard → Database → listening_history
4. 應該看到新的記錄
```

### 2. 測試統計更新
```
1. 播放幾首歌
2. 回到 HomePage
3. 點擊右上角 🔄 重新整理按鈕
4. Statistics 區塊的數字應該更新
```

### 3. 查詢資料庫
在 Supabase SQL Editor 執行：

```sql
-- 查看自己的播放歷史（最近 20 筆）
SELECT 
  song_title, 
  artist, 
  duration, 
  completed, 
  played_at 
FROM listening_history 
WHERE user_id = auth.uid()
ORDER BY played_at DESC 
LIMIT 20;

-- 查看統計數據
SELECT * FROM user_stats WHERE user_id = auth.uid();

-- 查看總播放時長（分鐘）
SELECT 
  total_play_count AS "播放次數",
  ROUND(total_duration / 60.0, 2) AS "總時長(分鐘)"
FROM user_stats 
WHERE user_id = auth.uid();
```

## 🔍 Debug 日誌

### 播放記錄相關
```
🎵 開始播放：Song Name
✅ 已記錄播放：Song Name (45 秒, 完成: true)
❌ 記錄播放失敗: [錯誤訊息]
```

### 統計載入相關
```
✅ 使用者統計已載入：播放 5 次，共 12 分鐘
❌ 載入統計數據失敗: [錯誤訊息]
🔄 App resumed - 重新載入統計數據
🔄 手動重新載入統計數據
```

## ⚙️ 自動更新機制

### Database Trigger
當新增播放記錄時，自動更新 `user_stats`：

```sql
CREATE OR REPLACE FUNCTION update_user_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- 更新總播放次數和時長
    INSERT INTO user_stats (user_id, total_play_count, total_duration)
    VALUES (NEW.user_id, 1, NEW.duration)
    ON CONFLICT (user_id) DO UPDATE SET
        total_play_count = user_stats.total_play_count + 1,
        total_duration = user_stats.total_duration + NEW.duration,
        last_active_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## 🎯 下一步功能

### 已實作 ✅
- [x] 自動記錄播放歷史
- [x] 顯示統計數據
- [x] 自動更新機制
- [x] 手動重新整理按鈕

### 待實作 📋
- [ ] 按讚/收藏功能（參考 FAVORITE_IMPLEMENTATION_GUIDE.md）
- [ ] 最近播放頁面
- [ ] 播放歷史圖表
- [ ] 最常播放的歌曲排行
- [ ] 每日/每週聽歌報告

## 💡 使用提示

1. **播放完整歌曲**: 讓歌曲播放到結束，`completed` 會標記為 `true`
2. **切換歌曲**: 切換時會記錄目前歌曲的播放時長
3. **統計更新**: 
   - 播放記錄會立即寫入資料庫
   - HomePage 的統計會在重新進入或重新整理時更新
4. **檢查資料**: 可以到 Supabase Dashboard 查看原始資料

## ⚠️ 注意事項

1. **網路連線**: 需要網路才能寫入 Supabase
2. **權限**: 使用者必須登入才能記錄
3. **RLS**: Row Level Security 確保使用者只能看到自己的資料
4. **錯誤處理**: 記錄失敗不會影響播放功能

## 🐛 常見問題

**Q: 播放了歌但統計沒更新？**
A: 
1. 檢查是否已登入
2. 點擊 🔄 手動重新整理
3. 查看 Debug 日誌確認是否有錯誤

**Q: 播放時長為 0？**
A: 歌曲可能播放時間太短（少於 1 秒）

**Q: 資料庫看不到記錄？**
A: 
1. 確認 RLS 政策正確
2. 確認 Trigger 已創建
3. 檢查網路連線

## 📚 相關文件

- `FAVORITE_IMPLEMENTATION_GUIDE.md` - 按讚功能實作
- `SUPABASE_USER_DATA_GUIDE.md` - 資料庫架構說明
- `fix_registration_trigger.sql` - Trigger 和表結構
