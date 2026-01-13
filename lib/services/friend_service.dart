import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// 好友服務 - 處理好友相關功能
class FriendService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 取得當前用戶 ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ==================== 搜尋用戶 ====================

  /// 根據 username、display_name、email 或 UUID 搜尋用戶
  Future<Map<String, dynamic>?> searchUserByUsername(String searchText) async {
    try {
      debugPrint('🔍 搜尋用戶: $searchText');
      
      // 先查詢所有 profiles 來 debug（包含目前登入的用戶）
      final currentUser = currentUserId;
      debugPrint('🆔 當前用戶 ID: $currentUser');
      
      final allProfiles = await _supabase
          .from('profiles')
          .select('id, username, display_name, email')
          .limit(20);
      debugPrint('📋 數據庫中的用戶列表:');
      for (var p in allProfiles) {
        debugPrint('  - ID: ${p['id']?.toString().substring(0, 8)}..., username: ${p['username']}, display_name: ${p['display_name']}, email: ${p['email']}');
      }
      
      // 檢查是否為 UUID 格式（包含 8-4-4-4-12 的連字符格式）
      final isUuidFormat = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(searchText);
      
      Map<String, dynamic>? response;
      
      if (isUuidFormat) {
        // 如果是 UUID 格式，直接用 id 搜尋
        debugPrint('🔑 檢測到 UUID 格式，使用 ID 搜尋');
        response = await _supabase
            .from('profiles')
            .select('id, username, display_name, avatar_url, bio, email')
            .eq('id', searchText)
            .maybeSingle();
      } else {
        // 否則使用 OR 條件同時搜尋 username、display_name 和 email
        response = await _supabase
            .from('profiles')
            .select('id, username, display_name, avatar_url, bio, email')
            .or('username.eq.$searchText,display_name.eq.$searchText,email.eq.$searchText')
            .maybeSingle();
      }

      if (response == null) {
        debugPrint('❌ 找不到用戶: $searchText');
        debugPrint('💡 提示：請檢查上方列表中的 username、display_name、email 或 UUID');
        debugPrint('💡 建議：如果要搜尋 Google 用戶，請使用他們的 email');
        return null;
      }

      debugPrint('✅ 找到用戶: ${response['display_name']} (@${response['username']}) (${response['id']})');
      return response;
    } catch (e) {
      debugPrint('❌ 搜尋用戶失敗: $e');
      rethrow;
    }
  }

  // ==================== 好友請求 ====================

  /// 發送好友請求
  Future<void> sendFriendRequest(String friendId) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not logged in');

      debugPrint('📤 發送好友請求: $userId -> $friendId');

      // 檢查是否已經是好友或已發送請求
      final existing = await _supabase
          .from('friendships')
          .select('id, status')
          .or('and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId)')
          .maybeSingle();

      if (existing != null) {
        if (existing['status'] == 'accepted') {
          throw Exception('已經是好友了');
        } else if (existing['status'] == 'pending') {
          throw Exception('已經發送過好友請求了');
        }
      }

      // 插入好友請求
      await _supabase.from('friendships').insert({
        'user_id': userId,
        'friend_id': friendId,
        'status': 'pending',
      });

      debugPrint('✅ 好友請求已發送');
    } catch (e) {
      debugPrint('❌ 發送好友請求失敗: $e');
      rethrow;
    }
  }

  // ==================== 取得好友列表 ====================

  /// 取得所有已接受的好友
  Future<List<Map<String, dynamic>>> getFriends() async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      debugPrint('📋 取得好友列表...');

      // 取得所有好友關係
      final friendships = await _supabase
          .from('friendships')
          .select('user_id, friend_id, status, created_at')
          .eq('status', 'accepted')
          .or('user_id.eq.$userId,friend_id.eq.$userId');

      debugPrint('✅ 找到 ${friendships.length} 個好友關係');

      // 提取好友的 ID 列表
      final friendIds = <String>[];
      for (final friendship in friendships) {
        final friendId = friendship['user_id'] == userId
            ? friendship['friend_id']
            : friendship['user_id'];
        friendIds.add(friendId);
      }

      if (friendIds.isEmpty) {
        debugPrint('📋 沒有好友');
        return [];
      }

      debugPrint('📋 好友 ID: $friendIds');

      // 取得好友的詳細資料
      final friends = await _supabase
          .from('profiles')
          .select('id, username, display_name, avatar_url, bio, email')
          .inFilter('id', friendIds);

      debugPrint('✅ 取得 ${friends.length} 個好友資料');
      return friends;
    } catch (e) {
      debugPrint('❌ 取得好友列表失敗: $e');
      rethrow;
    }
  }

  /// 取得待處理的好友請求（收到的）
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      debugPrint('📥 取得待處理好友請求...');

      // 取得所有發送給我的待處理請求
      final requests = await _supabase
          .from('friendships')
          .select('id, user_id, status, created_at')
          .eq('friend_id', userId)
          .eq('status', 'pending');

      if (requests.isEmpty) {
        debugPrint('📥 沒有待處理請求');
        return [];
      }

      // 提取請求者的 ID
      final requestUserIds = requests.map((r) => r['user_id'] as String).toList();

      // 取得請求者的詳細資料
      final users = await _supabase
          .from('profiles')
          .select('id, username, display_name, avatar_url, bio, email')
          .inFilter('id', requestUserIds);

      // 合併資料
      final result = <Map<String, dynamic>>[];
      for (final request in requests) {
        final user = users.firstWhere((u) => u['id'] == request['user_id']);
        result.add({
          'friendship_id': request['id'],
          ...user,
        });
      }

      debugPrint('✅ 找到 ${result.length} 個待處理請求');
      return result;
    } catch (e) {
      debugPrint('❌ 取得待處理請求失敗: $e');
      rethrow;
    }
  }

  // ==================== 接受/拒絕好友請求 ====================

  /// 接受好友請求
  Future<void> acceptFriendRequest(int friendshipId) async {
    try {
      debugPrint('✅ 接受好友請求: $friendshipId');

      await _supabase
          .from('friendships')
          .update({'status': 'accepted'})
          .eq('id', friendshipId);

      debugPrint('✅ 好友請求已接受');
    } catch (e) {
      debugPrint('❌ 接受好友請求失敗: $e');
      rethrow;
    }
  }

  /// 拒絕好友請求
  Future<void> rejectFriendRequest(int friendshipId) async {
    try {
      debugPrint('❌ 拒絕好友請求: $friendshipId');

      await _supabase
          .from('friendships')
          .update({'status': 'rejected'})
          .eq('id', friendshipId);

      debugPrint('✅ 好友請求已拒絕');
    } catch (e) {
      debugPrint('❌ 拒絕好友請求失敗: $e');
      rethrow;
    }
  }

  // ==================== 刪除好友 ====================

  /// 刪除好友
  Future<void> removeFriend(String friendId) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not logged in');

      debugPrint('🗑️ 刪除好友: $friendId');

      // 刪除好友關係（雙向都刪除）
      await _supabase
          .from('friendships')
          .delete()
          .or('and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId)');

      debugPrint('✅ 好友已刪除');
    } catch (e) {
      debugPrint('❌ 刪除好友失敗: $e');
      rethrow;
    }
  }
}
