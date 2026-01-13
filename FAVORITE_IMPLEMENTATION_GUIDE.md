# 按讚功能實作指南

## 已完成的功能

### ✅ 1. Session 清除修復
- **位置**: `lib/services/auth_service.dart` - `signOut()` 方法
- **改進**:
  - 登出時同時清除 Google 帳號
  - 使用 `SignOutScope.global` 清除所有裝置的 session
  - 已刪除的帳號將無法再登入

### ✅ 2. 統計數據顯示
- **位置**: `lib/main.dart` - `HomePage`
- **功能**:
  - 載入真實的使用者統計數據
  - 顯示播放次數、總時長、喜愛的歌曲/歌手/專輯數量
  - 自動從 Supabase 資料庫讀取

### ✅ 3. 聽歌記錄自動追蹤
- **位置**: `lib/services/music_player_service.dart`
- **功能**:
  - 當歌曲開始播放時記錄開始時間
  - 當歌曲播放完成或切換時記錄播放歷史
  - 自動更新資料庫中的 `listening_history` 表

## 🔄 待實作：按讚功能

### 如何在歌曲卡片添加愛心按鈕

#### 步驟 1: 更新 ForYouPage 的歌曲卡片

在 `lib/pages/for_you_page.dart` 中找到歌曲卡片的地方，添加愛心按鈕：

```dart
// 在歌曲標題和藝人名稱旁邊添加愛心圖示
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(song.title, style: TextStyle(...)),
          Text(song.artist, style: TextStyle(...)),
        ],
      ),
    ),
    // 添加愛心按鈕
    FavoriteButton(song: song),
  ],
)
```

#### 步驟 2: 創建 FavoriteButton Widget

創建新檔案 `lib/widgets/favorite_button.dart`：

```dart
import 'package:flutter/material.dart';
import '../models.dart';
import '../services/user_data_service.dart';

class FavoriteButton extends StatefulWidget {
  final MusicItem song;
  
  const FavoriteButton({Key? key, required this.song}) : super(key: key);
  
  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final UserDataService _userDataService = UserDataService();
  bool _isFavorite = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }
  
  Future<void> _checkFavoriteStatus() async {
    try {
      final isFav = await _userDataService.isFavoriteSong(widget.song.title);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ 檢查收藏狀態失敗: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _toggleFavorite() async {
    try {
      setState(() => _isLoading = true);
      
      if (_isFavorite) {
        // 取消收藏
        await _userDataService.removeFavoriteSong(widget.song.title);
        if (mounted) {
          setState(() => _isFavorite = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ 已從喜愛的歌曲移除')),
          );
        }
      } else {
        // 添加收藏
        await _userDataService.addFavoriteSong(
          songTitle: widget.song.title,
          artist: widget.song.artist,
          album: widget.song.albumName,
        );
        if (mounted) {
          setState(() => _isFavorite = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❤️ 已加入喜愛的歌曲')),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ 切換收藏失敗: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失敗，請稍後再試')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    
    return IconButton(
      icon: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite ? Colors.red : Colors.white70,
      ),
      onPressed: _toggleFavorite,
    );
  }
}
```

#### 步驟 3: 在需要的地方使用

在 `lib/pages/for_you_page.dart` 頂部導入：

```dart
import '../widgets/favorite_button.dart';
```

然後在歌曲卡片中使用：

```dart
// 範例：在歌曲列表中
ListView.builder(
  itemCount: songs.length,
  itemBuilder: (context, index) {
    final song = songs[index];
    return ListTile(
      leading: // 專輯封面
      title: Text(song.title),
      subtitle: Text(song.artist),
      trailing: FavoriteButton(song: song), // 添加按讚按鈕
      onTap: () {
        // 播放歌曲
        musicPlayerService.playSong(song);
      },
    );
  },
)
```

## 測試建議

### 測試 Session 清除
1. 使用測試帳號登入
2. 在 Supabase Dashboard 刪除該帳號
3. 點擊 Settings → "清除 Session (開發用)"
4. 確認無法再次登入該帳號 ✅

### 測試統計數據
1. 登入後查看 HomePage 的 Statistics 區塊
2. 應該看到 "0 Times, 0 Duration, 0 Songs..." （新帳號）
3. 播放幾首歌
4. 重新載入頁面，數字應該更新

### 測試聽歌記錄
1. 播放一首歌
2. 在 Supabase Dashboard → `listening_history` 表中查看
3. 應該看到新的記錄包含：
   - 歌曲名稱
   - 藝人
   - 播放時長
   - 完成狀態

### 測試按讚功能（實作後）
1. 在歌曲卡片點擊愛心圖示
2. 圖示應該從空心變成實心紅色
3. 再次點擊應該取消收藏
4. 在 Supabase Dashboard → `favorite_songs` 表中確認記錄

## 資料庫查詢範例

### 查看所有聽歌記錄
```sql
SELECT * FROM listening_history 
WHERE user_id = 'your-user-id' 
ORDER BY played_at DESC 
LIMIT 20;
```

### 查看使用者統計
```sql
SELECT * FROM user_stats 
WHERE user_id = 'your-user-id';
```

### 查看喜愛的歌曲
```sql
SELECT * FROM favorite_songs 
WHERE user_id = 'your-user-id' 
ORDER BY added_at DESC;
```

## 注意事項

1. **權限檢查**: 所有資料庫操作都會自動檢查 RLS (Row Level Security)
2. **錯誤處理**: 所有方法都有 try-catch，失敗不會影響 App 運行
3. **效能考量**: 按讚狀態查詢有緩存，避免頻繁查詢資料庫
4. **自動更新**: 統計數據在每次播放完成後自動更新（透過 Trigger）

## 下一步

- [ ] 實作按讚功能到所有歌曲卡片
- [ ] 添加「最近播放」頁面顯示聽歌歷史
- [ ] 添加「我的收藏」頁面顯示喜愛的歌曲
- [ ] 優化統計數據顯示（圖表、趨勢等）
