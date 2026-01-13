// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'pages/for_you_page.dart';
import 'pages/llm_chat_page.dart';
import 'pages/friend_page.dart';
import 'pages/music_player_page.dart';
import 'pages/login_page.dart';
import 'services/music_player_service.dart';
import 'services/auth_service.dart';
import 'services/watch_data_service.dart';
import 'services/user_data_service.dart';
import 'widgets/glassmorphism.dart';
import 'theme/glass_theme.dart';
import 'theme/scroll_behavior.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  
  if (supabaseUrl != null && supabaseAnonKey != null && 
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color.fromARGB(255, 13, 1, 26),
      ),
      scrollBehavior: NoGlowScrollBehavior(),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Auth wrapper to check authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return StreamBuilder<AuthState>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        debugPrint('🔍 AuthWrapper - ConnectionState: ${snapshot.connectionState}');
        debugPrint('🔍 AuthWrapper - Has data: ${snapshot.hasData}');
        debugPrint('🔍 AuthWrapper - Session: ${snapshot.data?.session != null}');
        debugPrint('🔍 AuthWrapper - User: ${snapshot.data?.session?.user?.email}');
        
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Check if user is signed in
        if (snapshot.hasData && snapshot.data?.session != null) {
          debugPrint('✅ AuthWrapper - 使用者已登入，顯示主畫面');
          return MainScreen();
        }
        
        // Show login page if not signed in
        debugPrint('❌ AuthWrapper - 使用者未登入，顯示登入頁面');
        return LoginPage();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final MusicPlayerService _playerService = MusicPlayerService();

  final List<Widget> _pages = [
    HomePage(),
    ForYouPage(),
    LLMChatPage(),
    FriendPage(),
  ];

  @override
  void initState() {
    super.initState();
    _playerService.addListener(_onPlayerStateChanged);
  }

  @override
  void dispose() {
    _playerService.removeListener(_onPlayerStateChanged);
    super.dispose();
  }

  void _onPlayerStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          _pages[_currentIndex],
          // Music player overlay (fullscreen when maximized)
          if (_playerService.hasSong && !_playerService.isMinimized)
            Positioned.fill(
              child: MusicPlayer(),
            ),
          // Minimized music player at bottom (above nav bar)
          if (_playerService.hasSong && _playerService.isMinimized)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0, // Directly above nav bar
              child: MusicPlayer(),
            ),
        ],
      ),
      bottomNavigationBar: (_playerService.hasSong && !_playerService.isMinimized)
          ? null // Hide nav bar when player is maximized
          : Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                ),
                child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey.shade600,
          elevation: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.home, 0),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.music_note, 1),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.chat_bubble_outline, 2),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.people, 3),
              label: '',
            ),
          ],
        ),
              ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Glow.purple.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Glow.purple.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: 26,
        color: isSelected ? Colors.white : Colors.grey.shade600,
      ),
    );
  }
}
// Home Page
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true; // 保持頁面狀態
  
  bool _isAdvancedExpanded = false;
  final WatchDataService _watchService = WatchDataService();
  final AuthService _authService = AuthService();
  final UserDataService _userDataService = UserDataService();
  
  // 使用者統計數據
  int _totalPlayCount = 0;
  int _totalDuration = 0; // 分鐘
  int _favoriteSongsCount = 0;
  int _favoriteArtistsCount = 0;
  int _favoriteAlbumsCount = 0;
  bool _isLoadingStats = true;
  
  // 實時手錶數據 - 只保留心率（專題重點）和步數（方便檢查）
  int _heartRate = 0;
  int _steps = 0;
  
  // 連接狀態
  bool _isWatchConnected = false;
  bool _isHealthAuthorized = false;
  DateTime? _lastUpdateTime;
  
  // Stream 訂閱 - 只保留心率和步數
  StreamSubscription<int>? _heartRateSubscription;
  StreamSubscription<int>? _stepsSubscription;

  @override
  void initState() {
    super.initState();
    // 註冊生命週期監聽器
    WidgetsBinding.instance.addObserver(this);
    // 載入使用者統計數據
    _loadUserStats();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 當 App 從背景回到前景時，重新載入統計數據
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 App resumed - 重新載入統計數據');
      _loadUserStats();
    }
  }
  
  /// 載入使用者統計數據
  Future<void> _loadUserStats() async {
    try {
      setState(() => _isLoadingStats = true);
      
      // 從資料庫獲取統計數據
      final stats = await _userDataService.getUserStats();
      final favSongs = await _userDataService.getFavoriteSongs();
      final favArtists = await _userDataService.getFavoriteArtists();
      final favAlbums = await _userDataService.getFavoriteAlbums();
      
      if (mounted) {
        setState(() {
          // 更新統計數據
          _totalPlayCount = stats?['total_play_count'] ?? 0;
          _totalDuration = ((stats?['total_duration'] ?? 0) / 60).round(); // 秒轉分鐘
          _favoriteSongsCount = favSongs.length;
          _favoriteArtistsCount = favArtists.length;
          _favoriteAlbumsCount = favAlbums.length;
          _isLoadingStats = false;
        });
        debugPrint('✅ 使用者統計已載入：播放 $_totalPlayCount 次，共 $_totalDuration 分鐘');
      }
    } catch (e) {
      debugPrint('❌ 載入統計數據失敗: $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }
  
  @override
  void dispose() {
    // 取消生命週期監聽器
    WidgetsBinding.instance.removeObserver(this);
    // 取消健康數據訂閱 - 只保留心率和步數
    _heartRateSubscription?.cancel();
    _stepsSubscription?.cancel();
    super.dispose();
  }

  // 上傳頭像
  Future<void> _uploadAvatar() async {
    try {
      // 使用 ImagePicker 選擇圖片
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (image == null) {
        debugPrint('❌ 使用者取消選擇圖片');
        return;
      }
      
      // 顯示載入對話框
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('使用者未登入');
      }
      
      // 讀取圖片檔案
      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;
      
      // 上傳到 Supabase Storage
      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: true,
            ),
          );
      
      // 獲取公開 URL
      final avatarUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);
      
      debugPrint('✅ 頭像已上傳: $avatarUrl');
      
      // 更新 profiles 資料表
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': avatarUrl})
          .eq('id', userId);
      
      debugPrint('✅ Profile 已更新頭像');
      
      // 關閉載入對話框
      if (mounted) {
        Navigator.of(context).pop();
        
        // 顯示成功訊息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('頭像上傳成功！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 重新載入頁面以顯示新頭像
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ 上傳頭像失敗: $e');
      
      // 關閉載入對話框（如果有開啟）
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // 顯示錯誤訊息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上傳失敗: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 請求 Health Connect 權限（使用 WatchDataService）
  Future<void> _requestHealthConnectPermissions() async {
    try {
      debugPrint('🔐 使用 WatchDataService 請求權限');
      
      // 使用 WatchDataService 初始化
      bool authorized = await _watchService.initialize();
      
      if (authorized) {
        debugPrint('✅ Health Connect 權限已授予！');
        setState(() {
          _isHealthAuthorized = true;
        });
        setState(() {
          _isWatchConnected = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ 權限已授予！正在讀取數據...'),
              backgroundColor: Colors.green.shade700,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // 開始讀取數據
        _startReadingHealthData();
      } else {
        debugPrint('⚠️ 權限未授予');
        if (mounted) {
          _showManualSettingsDialog();
        }
      }
      
    } catch (e) {
      debugPrint('❌ 權限請求失敗: $e');
      
      if (mounted) {
        _showManualSettingsDialog();
      }
    }
  }
  
  // 顯示手動設定對話框
  void _showManualSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.blue),
            SizedBox(width: 8),
            Text('需要手動授權'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠️ Android 15 的 Health Connect 權限需要手動設定\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('請依照以下步驟操作：\n'),
              _buildStep('1', '打開 系統設定 (Settings)'),
              _buildStep('2', '進入 安全與隱私 (Security & Privacy)'),
              _buildStep('3', '選擇 隱私 (Privacy)'),
              _buildStep('4', '找到 Health Connect'),
              _buildStep('5', '選擇 "此應用程式" (flutter_application_1)'),
              _buildStep('6', '授予以下權限：'),
              Padding(
                padding: EdgeInsets.only(left: 32, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• 心率 (Heart rate)'),
                    Text('• 步數 (Steps)'),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💡 提示：Health Connect 會自動從 Samsung Health 讀取 Watch 7 同步的數據',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('稍後設定'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              
              if (!mounted) return;
              navigator.pop();
              
              // 嘗試打開系統設定
              try {
                final platform = MethodChannel('samsung_health_channel');
                await platform.invokeMethod('openHealthConnectSettings');
              } catch (e) {
                debugPrint('無法打開設定: $e');
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('請手動打開 設定 → 隱私 → Health Connect'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            child: Text('打開設定'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              
              // 檢查權限並讀取數據
              debugPrint('🔍 檢查 Health Connect 權限...');
              
              // 使用 WatchDataService 初始化
              bool authorized = await _watchService.initialize();
              
              if (!mounted) return;
              
              if (authorized) {
                navigator.pop();
                setState(() {
                  _isWatchConnected = true;
                });
                
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('✅ 權限已授予！'),
                    backgroundColor: Colors.green.shade700,
                  ),
                );
                
                _startReadingHealthData();
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('❌ 尚未授權\n請先到設定中授予權限'),
                    backgroundColor: Colors.orange.shade700,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: Icon(Icons.check_circle),
            label: Text('我已授權'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
  
  // 開始讀取真實健康數據（訂閱 WatchDataService 的 Streams）
  void _startReadingHealthData() {
    debugPrint('🔄 訂閱 WatchDataService 的 Stream 讀取數據');
    
    // 訂閱心率
    _heartRateSubscription?.cancel();
    _heartRateSubscription = _watchService.getRealtimeHeartRate().listen((heartRate) {
      if (mounted) {
        setState(() {
          _heartRate = heartRate;
          _lastUpdateTime = DateTime.now();
        });
        debugPrint('💓 UI 更新心率: $heartRate bpm');
      }
    });
    
    // 訂閱步數
    _stepsSubscription?.cancel();
    _stepsSubscription = _watchService.getRealtimeSteps().listen((steps) {
      if (mounted) {
        setState(() {
          _steps = steps;
          _lastUpdateTime = DateTime.now();
        });
        debugPrint('📊 UI 更新步數: $steps');
      }
    });
    
    debugPrint('✅ 已訂閱心率和步數數據 Stream');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必須調用以支持 AutomaticKeepAliveClientMixin
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Home',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
            actions: [
              // 添加重新整理按鈕
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  debugPrint('🔄 手動重新載入統計數據');
                  _loadUserStats();
                },
              ),
              PopupMenuButton<String>(
            icon: Icon(Icons.settings),
            onSelected: (value) async {
              if (value == 'upload_avatar') {
                await _uploadAvatar();
              } else if (value == 'logout') {
                // 顯示確認對話框
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('確認登出'),
                    content: Text('確定要登出嗎？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('登出', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true && context.mounted) {
                  final authService = AuthService();
                  await authService.signOut();
                  
                  // 確保返回登入頁面
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                    );
                  }
                }
              } else if (value == 'clear_session') {
                // 開發者選項：強制清除 session
                final shouldClear = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('清除 Session'),
                      ],
                    ),
                    content: Text('這會強制清除本地登入狀態，需要重新登入。\n\n用於測試或帳號在後端被刪除時使用。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('清除', style: TextStyle(color: Colors.orange)),
                      ),
                    ],
                  ),
                );

                if (shouldClear == true && context.mounted) {
                  try {
                    // 強制登出並清除所有本地數據
                    final authService = AuthService();
                    await authService.signOut();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Session 已清除'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => LoginPage()),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ 清除失敗: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'upload_avatar',
                child: Row(
                  children: [
                    Icon(Icons.account_circle, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('上傳頭像'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_session',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('清除 Session (開發用)'),
                  ],
                ),
              ),
            ],
          ),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // User Bio
            GlassWithGlow(
              borderRadius: BorderRadius.circular(16),
              padding: EdgeInsets.all(16),
              glowBlur: Glow.cardBlur,
              glowSpread: Glow.cardSpread,
              glowAlpha: Glow.cardAlpha,
              child: Row(
                children: [
                  // 頭像 - 優先顯示 Google 頭像，否則顯示預設圖示
                  _authService.avatarUrl != null
                      ? CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(_authService.avatarUrl!),
                          backgroundColor: Colors.purple,
                        )
                      : CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.purple,
                          child: Icon(Icons.person, size: 30, color: Colors.white),
                        ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 顯示名稱（Google 名稱或 Email 前綴）
                        Text(
                          _authService.displayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Email
                        Text(
                          _authService.userEmail ?? '',
                          style: TextStyle(color: Colors.grey),
                        ),
                        // 登入方式
                        Row(
                          children: [
                            Icon(
                              _authService.authProvider == 'google'
                                  ? Icons.g_mobiledata
                                  : Icons.email,
                              size: 16,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Signed in with ${_authService.authProvider}',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Statistics
            GlassWithGlow(
              borderRadius: BorderRadius.circular(16),
              padding: EdgeInsets.all(16),
              glowBlur: Glow.cardBlur,
              glowSpread: Glow.cardSpread,
              glowAlpha: Glow.cardAlpha,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Statistics',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      if (_isLoadingStats)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white70),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem('$_totalPlayCount', 'Times'),
                      _StatItem('$_totalDuration', 'Duration'),
                      _StatItem('$_favoriteSongsCount', 'Songs'),
                      _StatItem('$_favoriteArtistsCount', 'Artist'),
                      _StatItem('$_favoriteAlbumsCount', 'Album'),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Top Albums
            Text('User\'s top albums',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            SizedBox(
              height: 140, // 增加高度以容納發光效果
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none, // 不裁剪，讓發光效果顯示
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(
                      right: 10,
                      top: 10,
                      bottom: 10,
                    ),
                    child: GlassWithGlow(
                      borderRadius: BorderRadius.circular(8),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      glowBlur: Glow.albumBlur,
                      glowSpread: Glow.albumSpread,
                      glowAlpha: Glow.albumAlpha,
                      onTap: () {
                        debugPrint('🎵 點擊了 Album ${index + 1}');
                      },
                      child: Container(
                        width: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.album, size: 40, color: Colors.white),
                            SizedBox(height: 5),
                            Text('Album ${index + 1}',
                                style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),

            // Smartwatch
            GlassWithGlow(
              borderRadius: BorderRadius.circular(16),
              padding: EdgeInsets.all(16),
              glowBlur: Glow.cardBlur,
              glowSpread: Glow.cardSpread,
              glowAlpha: Glow.cardAlpha,
              child: Column(
                children: [
                  // 基本資訊區
                  Row(
                    children: [
                      Icon(Icons.watch, size: 40, color: Colors.white),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User\'s Smartwatch',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                Icon(
                                  Icons.circle, 
                                  color: _isWatchConnected ? Colors.green : Colors.orange, 
                                  size: 12
                                ),
                                SizedBox(width: 5),
                                Text(
                                  _isWatchConnected ? 'Connected (Real-time)' : 'Simulated Data',
                                  style: TextStyle(
                                    color: _isWatchConnected ? Colors.green : Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                                if (_isWatchConnected && _lastUpdateTime != null) ...[
                                  SizedBox(width: 8),
                                  Text(
                                    '• ${_formatTimeDiff(_lastUpdateTime!)}',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 展開/收起按鈕
                      IconButton(
                        icon: Icon(
                          _isAdvancedExpanded 
                            ? Icons.keyboard_arrow_up 
                            : Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isAdvancedExpanded = !_isAdvancedExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                  
                  // 進階選項 - 可展開區域
                  AnimatedCrossFade(
                    firstChild: SizedBox.shrink(),
                    secondChild: Column(
                      children: [
                        SizedBox(height: 16),
                        Divider(color: Colors.white.withValues(alpha: 0.2)),
                        SizedBox(height: 12),
                        
                        // Health Connect 說明和授權
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          child: GlassWithGlow(
                          borderRadius: BorderRadius.circular(12),
                          padding: EdgeInsets.all(16),
                          glowColor: Colors.green.shade600,
                          glowBlur: Glow.cardBlur,
                          glowSpread: Glow.cardSpread,
                          glowAlpha: Glow.cardAlpha,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.health_and_safety, color: Colors.green.shade300, size: 24),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Health Connect',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                '需要請求 Health Connect 的權限以讀取健康數據',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: 16),
                              
                              // 授權狀態顯示
                              GlassWithGlow(
                                borderRadius: BorderRadius.circular(8),
                                padding: EdgeInsets.all(12),
                                glowColor: _isHealthAuthorized 
                                    ? Colors.green.shade400
                                    : Colors.orange.shade400,
                                glowBlur: Glow.cardBlur * 0.7,
                                glowSpread: Glow.cardSpread * 0.7,
                                glowAlpha: (Glow.cardAlpha * 0.7),
                                opacity: 0.05,
                                child: Row(
                                  children: [
                                    Icon(
                                      _isHealthAuthorized ? Icons.check_circle : Icons.warning,
                                      color: _isHealthAuthorized 
                                          ? Colors.green.shade300
                                          : Colors.orange.shade300,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _isHealthAuthorized 
                                            ? '✅ 已授權 Health Connect'
                                            : '⚠️ 尚未授權',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: 12),
                              
                              // 按鈕組
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _requestHealthConnectPermissions,
                                      icon: Icon(Icons.security, size: 18),
                                      label: Text('授權'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 10),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        
                                        try {
                                          // 使用 Android Intent 打開 Health Connect 設定
                                          const platform = MethodChannel('samsung_health_channel');
                                          await platform.invokeMethod('openHealthConnectSettings');
                                          
                                          if (mounted) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text('已打開 Health Connect 設定'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          debugPrint('⚠️ 無法打開設定: $e');
                                          if (mounted) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text('請手動打開 設定 → 應用程式 → Health Connect'),
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      icon: Icon(Icons.settings, size: 18),
                                      label: Text('設定'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade700,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 8),
                              
                              // 診斷按鈕
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final currentContext = context;
                                  final navigator = Navigator.of(currentContext);
                                  final messenger = ScaffoldMessenger.of(currentContext);
                                  
                                  try {
                                    showDialog(
                                      context: currentContext,
                                      barrierDismissible: false,
                                      builder: (context) => AlertDialog(
                                        title: Text('🔍 診斷中...'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(height: 16),
                                            Text('正在檢查數據可用性...'),
                                          ],
                                        ),
                                      ),
                                    );
                                    
                                    final result = await _watchService.diagnoseDataAvailability();
                                    
                                    if (!mounted) return;
                                    
                                    navigator.pop(); // 關閉載入對話框
                                    
                                    // 顯示診斷結果
                                    showDialog(
                                      context: currentContext,
                                      builder: (context) => AlertDialog(
                                        title: Text('📊 數據可用性診斷'),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '授權狀態: ${result['authorized'] ? '✅ 已授權' : '❌ 未授權'}',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Divider(),
                                              ...result.entries.where((e) => e.key != 'authorized' && e.key != 'timestamp').map((entry) {
                                                final data = entry.value as Map<String, dynamic>;
                                                final available = data['available'] ?? false;
                                                final count = data['count'] ?? 0;
                                                
                                                return Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 4),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        available ? Icons.check_circle : Icons.cancel,
                                                        color: available ? Colors.green : Colors.red,
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          '${entry.key}: ${available ? '$count 筆' : '無數據'}',
                                                          style: TextStyle(fontSize: 13),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                              SizedBox(height: 16),
                                              Text(
                                                '💡 提示：',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                '• 如果顯示「無數據」，請確認 Samsung Health 已同步手錶數據\n'
                                                '• 在手錶上測量後，需要等待數據同步（約 1-5 分鐘）\n'
                                                '• 可以在 Health Connect 設定中查看已同步的數據',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text('關閉'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    
                                    navigator.pop(); // 關閉載入對話框
                                    messenger.showSnackBar(
                                      SnackBar(content: Text('診斷失敗: $e')),
                                    );
                                  }
                                },
                                icon: Icon(Icons.bug_report, size: 18),
                                label: Text('診斷數據'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade600,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ),
                        
                        // 標題
                        Row(
                          children: [
                            Icon(Icons.analytics_outlined, 
                                color: Colors.white70, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '進階數據 (實時)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        // 實時數據網格 - 只顯示心率（專題重點）和步數（方便檢查）
                        GridView.count(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.4,
                          children: [
                            _buildRealtimeDataCard(
                              icon: Icons.favorite,
                              label: '心率',
                              value: _heartRate > 0 ? '$_heartRate' : '--',
                              unit: 'bpm',
                              color: Colors.red,
                            ),
                            _buildRealtimeDataCard(
                              icon: Icons.directions_walk,
                              label: '步數',
                              value: _steps > 0 ? '$_steps' : '--',
                              unit: 'steps',
                              color: Colors.blue,
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 8),
                        
                        // 最後更新時間
                        Text(
                          '最後更新: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    crossFadeState: _isAdvancedExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ], // Column children 結束
        ), // Column 結束
              ]), // SliverChildListDelegate 結束
            ), // SliverList 結束
          ), // SliverPadding 結束
        ], // slivers 結束
      ), // CustomScrollView 結束
    ); // Scaffold 結束
  }

  // 格式化時間差
  String _formatTimeDiff(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}秒前';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分鐘前';
    } else {
      return '${diff.inHours}小時前';
    }
  }

  // 建立實時數據卡片
  Widget _buildRealtimeDataCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return GlassWithGlow(
      borderRadius: BorderRadius.circular(12),
      padding: EdgeInsets.all(8),
      glowColor: color,
      opacity: 0.05,
      glowBlur: Glow.healthDataBlur,
      glowSpread: Glow.healthDataSpread,
      glowAlpha: Glow.healthDataAlpha,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
