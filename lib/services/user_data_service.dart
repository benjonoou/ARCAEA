import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// 用戶數據服務 - 管理用戶的聽歌記錄、喜好和統計數據
class UserDataService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== 用戶統計數據 ====================

  /// 取得用戶統計數據
  Future<Map<String, dynamic>?> getUserStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('user_stats')
          .select()
          .eq('id', userId)
          .maybeSingle();

      debugPrint('📊 取得用戶統計: $response');
      return response;
    } catch (e) {
      debugPrint('❌ 取得統計數據失敗: $e');
      return null;
    }
  }

  /// 更新用戶統計數據
  Future<void> updateUserStats({
    int? totalPlayCount,
    int? totalPlayDuration,
    int? favoriteSongCount,
    int? favoriteArtistCount,
    int? favoriteAlbumCount,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final updates = <String, dynamic>{};
      if (totalPlayCount != null) updates['total_play_count'] = totalPlayCount;
      if (totalPlayDuration != null) {
        updates['total_play_duration'] = totalPlayDuration;
      }
      if (favoriteSongCount != null) {
        updates['favorite_song_count'] = favoriteSongCount;
      }
      if (favoriteArtistCount != null) {
        updates['favorite_artist_count'] = favoriteArtistCount;
      }
      if (favoriteAlbumCount != null) {
        updates['favorite_album_count'] = favoriteAlbumCount;
      }

      await _supabase.from('user_stats').update(updates).eq('id', userId);

      debugPrint('✅ 統計數據已更新');
    } catch (e) {
      debugPrint('❌ 更新統計數據失敗: $e');
    }
  }

  /// 增加播放次數
  Future<void> incrementPlayCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // 使用 SQL 原子操作增加計數
      await _supabase.rpc('increment_play_count', params: {'user_id': userId});

      debugPrint('✅ 播放次數 +1');
    } catch (e) {
      // 如果 RPC 不存在，使用普通更新
      final stats = await getUserStats();
      if (stats != null) {
        final currentCount = stats['total_play_count'] ?? 0;
        await updateUserStats(totalPlayCount: currentCount + 1);
      }
    }
  }

  // ==================== 聽歌記錄 ====================

  /// 新增聽歌記錄
  Future<void> addListeningHistory({
    required String songTitle,
    String? artist,
    String? album,
    int? duration,
    int? playDuration,
    bool completed = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('listening_history').insert({
        'user_id': userId,
        'song_title': songTitle,
        'artist': artist,
        'album': album,
        'duration': duration,
        'play_duration': playDuration,
        'completed': completed,
      });

      debugPrint('✅ 已記錄播放: $songTitle - $artist');

      // 自動增加播放次數
      await incrementPlayCount();
    } catch (e) {
      debugPrint('❌ 記錄播放失敗: $e');
    }
  }

  /// 取得最近播放記錄
  Future<List<Map<String, dynamic>>> getRecentListeningHistory({
    int limit = 20,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('listening_history')
          .select()
          .eq('user_id', userId)
          .order('played_at', ascending: false)
          .limit(limit);

      debugPrint('📜 取得播放記錄: ${response.length} 筆');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ 取得播放記錄失敗: $e');
      return [];
    }
  }

  /// 取得最常播放的歌曲
  Future<List<Map<String, dynamic>>> getMostPlayedSongs({
    int limit = 10,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // 使用聚合查詢統計播放次數
      final response = await _supabase
          .rpc('get_most_played_songs', params: {
            'user_id_param': userId,
            'limit_param': limit,
          })
          .select();

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ 取得最常播放歌曲失敗: $e');
      // 如果 RPC 不存在，返回空列表
      return [];
    }
  }

  // ==================== 喜愛的歌曲 ====================

  /// 新增喜愛的歌曲
  Future<bool> addFavoriteSong({
    required String songTitle,
    String? artist,
    String? album,
    String? albumCoverUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('favorite_songs').insert({
        'user_id': userId,
        'song_title': songTitle,
        'artist': artist,
        'album': album,
        'album_cover_url': albumCoverUrl,
      });

      debugPrint('✅ 已加入喜愛: $songTitle');

      // 更新統計
      final favorites = await getFavoriteSongs();
      await updateUserStats(favoriteSongCount: favorites.length);

      return true;
    } catch (e) {
      debugPrint('❌ 加入喜愛失敗: $e');
      return false;
    }
  }

  /// 移除喜愛的歌曲
  Future<bool> removeFavoriteSong({
    required String songTitle,
    String? artist,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      var query = _supabase
          .from('favorite_songs')
          .delete()
          .eq('user_id', userId)
          .eq('song_title', songTitle);

      if (artist != null) {
        query = query.eq('artist', artist);
      }

      await query;

      debugPrint('✅ 已移除喜愛: $songTitle');

      // 更新統計
      final favorites = await getFavoriteSongs();
      await updateUserStats(favoriteSongCount: favorites.length);

      return true;
    } catch (e) {
      debugPrint('❌ 移除喜愛失敗: $e');
      return false;
    }
  }

  /// 檢查是否為喜愛的歌曲
  Future<bool> isFavoriteSong({
    required String songTitle,
    String? artist,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      var query = _supabase
          .from('favorite_songs')
          .select('id')
          .eq('user_id', userId)
          .eq('song_title', songTitle);

      if (artist != null) {
        query = query.eq('artist', artist);
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('❌ 檢查喜愛狀態失敗: $e');
      return false;
    }
  }

  /// 取得所有喜愛的歌曲
  Future<List<Map<String, dynamic>>> getFavoriteSongs() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('favorite_songs')
          .select()
          .eq('user_id', userId)
          .order('added_at', ascending: false);

      debugPrint('❤️ 喜愛的歌曲: ${response.length} 首');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ 取得喜愛歌曲失敗: $e');
      return [];
    }
  }

  // ==================== 喜愛的歌手 ====================

  /// 新增喜愛的歌手
  Future<bool> addFavoriteArtist(String artistName) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('favorite_artists').insert({
        'user_id': userId,
        'artist_name': artistName,
      });

      debugPrint('✅ 已加入喜愛歌手: $artistName');

      // 更新統計
      final artists = await getFavoriteArtists();
      await updateUserStats(favoriteArtistCount: artists.length);

      return true;
    } catch (e) {
      debugPrint('❌ 加入喜愛歌手失敗: $e');
      return false;
    }
  }

  /// 取得所有喜愛的歌手
  Future<List<Map<String, dynamic>>> getFavoriteArtists() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('favorite_artists')
          .select()
          .eq('user_id', userId)
          .order('added_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ 取得喜愛歌手失敗: $e');
      return [];
    }
  }

  // ==================== 喜愛的專輯 ====================

  /// 新增喜愛的專輯
  Future<bool> addFavoriteAlbum({
    required String albumName,
    String? artist,
    String? albumCoverUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('favorite_albums').insert({
        'user_id': userId,
        'album_name': albumName,
        'artist': artist,
        'album_cover_url': albumCoverUrl,
      });

      debugPrint('✅ 已加入喜愛專輯: $albumName');

      // 更新統計
      final albums = await getFavoriteAlbums();
      await updateUserStats(favoriteAlbumCount: albums.length);

      return true;
    } catch (e) {
      debugPrint('❌ 加入喜愛專輯失敗: $e');
      return false;
    }
  }

  /// 取得所有喜愛的專輯
  Future<List<Map<String, dynamic>>> getFavoriteAlbums() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('favorite_albums')
          .select()
          .eq('user_id', userId)
          .order('added_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ 取得喜愛專輯失敗: $e');
      return [];
    }
  }

  // ==================== 用戶 Profile ====================

  /// 更新用戶 Profile
  Future<bool> updateProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;

      await _supabase.from('profiles').update(updates).eq('id', userId);

      debugPrint('✅ Profile 已更新');
      return true;
    } catch (e) {
      debugPrint('❌ 更新 Profile 失敗: $e');
      return false;
    }
  }

  /// 取得用戶 Profile
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('❌ 取得 Profile 失敗: $e');
      return null;
    }
  }
}
