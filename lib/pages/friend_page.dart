import 'package:flutter/material.dart';
import 'dart:ui';
import '../models.dart';
import '../widgets/glassmorphism.dart';
import '../theme/glass_theme.dart';
import '../services/friend_service.dart';

class FriendPage extends StatefulWidget {
  const FriendPage({super.key});

  @override
  State<FriendPage> createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> {
  final FriendService _friendService = FriendService();
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;
  bool _showAddFriendDialog = false;
  final TextEditingController _friendIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _friendIdController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);

    try {
      final friends = await _friendService.getFriends();
      final requests = await _friendService.getPendingRequests();

      debugPrint('📋 已載入 ${friends.length} 個好友');
      for (var friend in friends) {
        debugPrint('  👤 ${friend['display_name']} (@${friend['username']}) - 頭像: ${friend['avatar_url']}');
      }
      debugPrint('📥 已載入 ${requests.length} 個待處理請求');

      setState(() {
        _friends = friends;
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ 載入好友失敗: $e');
      setState(() => _isLoading = false);
      _showNotification('載入好友失敗: $e', isSuccess: false);
    }
  }

  void _showAddFriendOverlay() {
    setState(() {
      _showAddFriendDialog = true;
    });
  }

  void _hideAddFriendOverlay() {
    setState(() {
      _showAddFriendDialog = false;
      _friendIdController.clear();
    });
  }

  Future<void> _addFriend() async {
    final username = _friendIdController.text.trim();
    
    if (username.isEmpty) {
      _showNotification('請輸入好友的用戶名', isSuccess: false);
      return;
    }

    try {
      debugPrint('🔍 搜尋用戶: $username');
      
      // 搜尋用戶
      final user = await _friendService.searchUserByUsername(username);
      
      if (user == null) {
        _showNotification('找不到用戶 "$username"', isSuccess: false);
        return;
      }

      // 發送好友請求
      await _friendService.sendFriendRequest(user['id']);
      
      _showNotification('已發送好友請求給 ${user['display_name']}', isSuccess: true);
      _hideAddFriendOverlay();
      
      // 重新載入好友列表
      _loadFriends();
    } catch (e) {
      debugPrint('❌ 加入好友失敗: $e');
      _showNotification('$e', isSuccess: false);
    }
  }

  Future<void> _acceptRequest(int friendshipId) async {
    try {
      await _friendService.acceptFriendRequest(friendshipId);
      _showNotification('已接受好友請求', isSuccess: true);
      _loadFriends();
    } catch (e) {
      _showNotification('接受失敗: $e', isSuccess: false);
    }
  }

  Future<void> _rejectRequest(int friendshipId) async {
    try {
      await _friendService.rejectFriendRequest(friendshipId);
      _showNotification('已拒絕好友請求', isSuccess: true);
      _loadFriends();
    } catch (e) {
      _showNotification('拒絕失敗: $e', isSuccess: false);
    }
  }

  void _showRemoveFriendDialog(Map<String, dynamic> friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A0A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('移除好友'),
        content: Text(
          '確定要移除 ${friend['display_name'] ?? friend['username']} 嗎？',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFriend(friend['id']);
            },
            child: Text('移除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFriend(String friendId) async {
    try {
      await _friendService.removeFriend(friendId);
      _showNotification('已移除好友', isSuccess: true);
      _loadFriends();
    } catch (e) {
      _showNotification('移除失敗: $e', isSuccess: false);
    }
  }

  /// 取得頭像圖片（支援 Asset 和 Network）
  ImageProvider? _getAvatarImage(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      debugPrint('⚠️ 頭像 URL 為空');
      return null;
    }
    
    debugPrint('🖼️ 處理頭像 URL: $avatarUrl');
    
    // 如果是 assets 路徑，使用 AssetImage
    if (avatarUrl.startsWith('assets/')) {
      debugPrint('✅ 使用 AssetImage: $avatarUrl');
      return AssetImage(avatarUrl);
    }
    
    // 如果是網路 URL（http/https），使用 NetworkImage
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      debugPrint('✅ 使用 NetworkImage: $avatarUrl');
      return NetworkImage(avatarUrl);
    }
    
    debugPrint('❌ 無法識別的頭像格式: $avatarUrl');
    return null;
  }

  void _showNotification(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text('Friend', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.transparent,
                elevation: 0,
                floating: true,
                snap: true,
                pinned: false,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF0D0118).withValues(alpha: 0.7),
                            Color(0xFF0D0118).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 新增好友按鈕
                    GlassWithGlow(
                      borderRadius: BorderRadius.circular(12),
                      padding: EdgeInsets.all(16),
                      glowBlur: Glow.buttonBlur,
                      glowSpread: Glow.buttonSpread,
                      glowAlpha: Glow.buttonAlpha,
                      onTap: _showAddFriendOverlay,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add, size: 24),
                          SizedBox(width: 8),
                          Text(
                            '新增好友',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // 待處理請求
                    if (_pendingRequests.isNotEmpty) ...[
                      Text(
                        '待處理請求 (${_pendingRequests.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade300,
                        ),
                      ),
                      SizedBox(height: 12),
                      ..._pendingRequests.map((request) => Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: GlassWithGlow(
                          borderRadius: BorderRadius.circular(12),
                          padding: EdgeInsets.all(16),
                          glowBlur: Glow.cardBlur,
                          glowSpread: Glow.cardSpread,
                          glowAlpha: Glow.cardAlpha,
                          child: Row(
                            children: [
                              // 頭像
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Color(0xFF4A3A5A),
                                backgroundImage: _getAvatarImage(request['avatar_url']),
                                child: _getAvatarImage(request['avatar_url']) == null
                                    ? Text(
                                        request['display_name']?[0]?.toUpperCase() ?? 
                                        request['username']?[0]?.toUpperCase() ?? 
                                        '?',
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request['display_name'] ?? request['username'] ?? 'Unknown',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '@${request['username'] ?? 'unknown'}',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              // 接受按鈕
                              GestureDetector(
                                onTap: () => _acceptRequest(request['friendship_id']),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.check, color: Colors.green, size: 20),
                                ),
                              ),
                              SizedBox(width: 8),
                              // 拒絕按鈕
                              GestureDetector(
                                onTap: () => _rejectRequest(request['friendship_id']),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.close, color: Colors.red, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                      SizedBox(height: 20),
                      Divider(color: Colors.white24),
                      SizedBox(height: 20),
                    ],
                    
                    // 好友列表標題
                    Text(
                      '好友列表 (${_friends.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // 好友列表
                    if (_isLoading)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_friends.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.white38),
                              SizedBox(height: 16),
                              Text(
                                '還沒有好友',
                                style: TextStyle(color: Colors.white54, fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '點擊上方按鈕新增好友',
                                style: TextStyle(color: Colors.white38, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._friends.map((friend) => Container(
                        margin: EdgeInsets.only(bottom: 16),
                        child: GlassWithGlow(
                          borderRadius: BorderRadius.circular(12),
                          padding: EdgeInsets.all(16),
                          glowBlur: Glow.cardBlur,
                          glowSpread: Glow.cardSpread,
                          glowAlpha: Glow.cardAlpha,
                          child: Row(
                            children: [
                              // 頭像
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Color(0xFF4A3A5A),
                                backgroundImage: _getAvatarImage(friend['avatar_url']),
                                child: _getAvatarImage(friend['avatar_url']) == null
                                    ? Text(
                                        friend['display_name']?[0]?.toUpperCase() ?? 
                                        friend['username']?[0]?.toUpperCase() ?? 
                                        '?',
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      friend['display_name'] ?? friend['username'] ?? 'Unknown',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    if (friend['bio'] != null && friend['bio'].toString().isNotEmpty)
                                      Text(
                                        friend['bio'],
                                        style: TextStyle(color: Colors.grey, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              // 移除好友按鈕
                              GestureDetector(
                                onTap: () => _showRemoveFriendDialog(friend),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.person_remove, color: Colors.red, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                  ]),
                ),
              ),
            ],
          ),
          
          // 新增好友對話框遮罩
          if (_showAddFriendDialog)
            GestureDetector(
              onTap: _hideAddFriendOverlay,
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: GestureDetector(
                    onTap: () {}, // 防止點擊對話框時關閉
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 32),
                      child: GlassWithGlow(
                        borderRadius: BorderRadius.circular(20),
                        padding: EdgeInsets.all(24),
                        glowBlur: Glow.cardBlur * 1.5,
                        glowSpread: Glow.cardSpread * 1.5,
                        glowAlpha: Glow.cardAlpha,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 標題和關閉按鈕
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '新增好友',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _hideAddFriendOverlay,
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.close, size: 24),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            
                            // 輸入框
                            TextField(
                              controller: _friendIdController,
                              decoration: InputDecoration(
                                hintText: '輸入好友的用戶名或 ID',
                                hintStyle: TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.purple.withValues(alpha: 0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.purple.withValues(alpha: 0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.purple, width: 2),
                                ),
                              ),
                              style: TextStyle(color: Colors.white),
                              autofocus: true,
                              onSubmitted: (_) => _addFriend(),
                            ),
                            SizedBox(height: 20),
                            
                            // 確認按鈕
                            SizedBox(
                              width: double.infinity,
                              child: GlassWithGlow(
                                borderRadius: BorderRadius.circular(12),
                                padding: EdgeInsets.symmetric(vertical: 14),
                                glowBlur: Glow.buttonBlur,
                                glowSpread: Glow.buttonSpread,
                                glowAlpha: Glow.buttonAlpha,
                                onTap: _addFriend,
                                child: Center(
                                  child: Text(
                                    '發送好友請求',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
