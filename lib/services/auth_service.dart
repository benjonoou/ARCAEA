import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'music_player_service.dart';

/// 認證服務 - 封裝所有 Supabase Auth 功能
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== 取得使用者資訊 ====================
  
  /// 取得當前登入的使用者
  User? get currentUser => _supabase.auth.currentUser;

  /// 檢查是否已登入
  bool get isSignedIn => currentUser != null;

  /// 取得使用者 ID
  String? get userId => currentUser?.id;

  /// 取得使用者 Email
  String? get userEmail => currentUser?.email;

  /// 取得使用者顯示名稱
  /// 優先順序：
  /// 1. username (Sign up 時設定的)
  /// 2. display_name (Sign up 時設定的)
  /// 3. full_name (Google OAuth)
  /// 4. name (Google OAuth)
  /// 5. email 前綴
  String get displayName {
    final user = currentUser;
    if (user == null) return '使用者';
    
    final metadata = user.userMetadata;
    
    // 1. 優先使用註冊時的 username
    if (metadata?['username'] != null && metadata!['username'].toString().isNotEmpty) {
      return metadata['username'];
    }
    
    // 2. 使用註冊時的 display_name
    if (metadata?['display_name'] != null && metadata!['display_name'].toString().isNotEmpty) {
      return metadata['display_name'];
    }
    
    // 3. Google OAuth 的 full_name
    if (metadata?['full_name'] != null && metadata!['full_name'].toString().isNotEmpty) {
      return metadata['full_name'];
    }
    
    // 4. Google OAuth 的 name
    if (metadata?['name'] != null && metadata!['name'].toString().isNotEmpty) {
      return metadata['name'];
    }
    
    // 5. 最後使用 email 的前綴（@ 之前的部分）
    if (user.email != null) {
      return user.email!.split('@').first;
    }
    
    return '使用者';
  }

  /// 取得使用者頭像 URL（從 Google 或其他 OAuth provider）
  String? get avatarUrl {
    final user = currentUser;
    if (user == null) return null;
    
    // 從 user_metadata 取得 avatar_url 或 picture
    final metadata = user.userMetadata;
    return metadata?['avatar_url'] ?? metadata?['picture'];
  }

  /// 取得登入提供者（email, google, apple 等）
  String get authProvider {
    final user = currentUser;
    if (user == null) return 'unknown';
    
    // 檢查 app_metadata 中的 provider
    final appMetadata = user.appMetadata;
    final provider = appMetadata['provider'];
    
    if (provider != null) {
      return provider.toString();
    }
    
    return 'email';
  }

  // ==================== 監聽認證狀態 ====================
  
  /// 監聽認證狀態變化（登入、登出、token 更新等）
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ==================== Email/Password 認證 ====================
  
  /// 使用 Email 和密碼登入
  /// 
  /// 拋出 [AuthException] 如果登入失敗
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      
      debugPrint('✅ 登入成功: ${response.user?.email}');
      return response;
    } on AuthException catch (e) {
      debugPrint('❌ 登入失敗: ${e.message}');
      rethrow;
    }
  }

  /// 使用 Email 和密碼註冊新帳號
  /// 
  /// [metadata] 可以儲存額外的使用者資料（如暱稱、頭像等）
  /// 拋出 [AuthException] 如果註冊失敗
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: metadata, // 儲存到 auth.users.raw_user_meta_data
      );
      
      debugPrint('✅ 註冊成功: ${response.user?.email}');
      return response;
    } on AuthException catch (e) {
      debugPrint('❌ 註冊失敗: ${e.message}');
      rethrow;
    }
  }

  // ==================== 登出 ====================
  
  /// 登出當前使用者（徹底清除所有 session）
  Future<void> signOut() async {
    try {
      // 1. 停止音樂播放服務
      try {
        final musicService = MusicPlayerService();
        await musicService.stop();
        debugPrint('🎵 已停止音樂播放');
      } catch (e) {
        debugPrint('⚠️ 停止音樂播放失敗: $e');
      }
      
      // 2. 登出 Google 帳號（如果有的話）
      try {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
          debugPrint('🔓 已登出 Google 帳號');
        }
      } catch (e) {
        debugPrint('⚠️ Google 登出失敗（可能未登入）: $e');
      }
      
      // 3. 登出 Supabase（清除所有裝置的 session）
      await _supabase.auth.signOut(scope: SignOutScope.global);
      debugPrint('✅ Supabase 登出成功（已清除所有裝置 session）');
    } catch (e) {
      debugPrint('❌ 登出失敗: $e');
      rethrow;
    }
  }

  // ==================== 密碼管理 ====================
  
  /// 發送重設密碼的 Email
  /// 
  /// [redirectTo] 重設密碼後要導向的 URL（可選）
  Future<void> resetPasswordForEmail(
    String email, {
    String? redirectTo,
  }) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: redirectTo,
      );
      debugPrint('✅ 密碼重設郵件已發送到: $email');
    } catch (e) {
      debugPrint('❌ 發送密碼重設郵件失敗: $e');
      rethrow;
    }
  }

  /// 更新當前使用者的密碼
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      debugPrint('✅ 密碼更新成功');
      return response;
    } catch (e) {
      debugPrint('❌ 密碼更新失敗: $e');
      rethrow;
    }
  }

  // ==================== OAuth 第三方登入 ====================
  
  /// 使用 Google 原生登入（Native Google Sign-In）
  /// 
  /// 使用 Android/iOS 原生 Google 服務登入，避免瀏覽器重新導向問題
  /// 需要在 Supabase Dashboard 啟用 Google Provider
  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('🔑 啟動原生 Google 登入...');
      
      // 1. 初始化 GoogleSignIn（使用 Web Client ID）
      final googleSignIn = GoogleSignIn(
        serverClientId: '377945784399-iu65lqiv84n7avd4jgcm2g4n8dkl085k.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      // 先登出之前的 Google 帳號（確保每次都顯示帳號選擇器）
      try {
        if (await googleSignIn.isSignedIn()) {
          debugPrint('🔓 登出之前的 Google 帳號');
          await googleSignIn.signOut();
        }
      } catch (e) {
        debugPrint('⚠️ 檢查登入狀態時出錯（繼續執行）: $e');
      }

      // 2. 觸發 Google 登入流程（顯示帳號選擇器）
      debugPrint('📱 正在打開 Google 帳號選擇器...');
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('⚠️ 使用者取消 Google 登入 (googleUser is null)');
        return false; // 使用者取消登入
      }

      debugPrint('✅ Google 帳號選擇成功');
      debugPrint('📧 Email: ${googleUser.email}');
      debugPrint('👤 Display Name: ${googleUser.displayName}');
      debugPrint('🆔 ID: ${googleUser.id}');

      // 3. 取得 Google 驗證資訊（ID Token 和 Access Token）
      debugPrint('🔐 正在取得 Google 驗證 Token...');
      final googleAuth = await googleUser.authentication;
      
      debugPrint('🎫 ID Token 長度: ${googleAuth.idToken?.length ?? 0}');
      debugPrint('🎫 Access Token 長度: ${googleAuth.accessToken?.length ?? 0}');
      
      if (googleAuth.idToken == null) {
        debugPrint('❌ 無法取得 Google ID Token');
        return false;
      }

      debugPrint('✅ Google Token 取得成功，正在登入 Supabase...');

      // 4. 使用 Google Token 登入 Supabase
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      debugPrint('✅ Supabase 登入成功!');
      debugPrint('📧 User Email: ${response.user?.email}');
      debugPrint('🆔 User ID: ${response.user?.id}');
      return true;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Google 登入失敗: $e');
      debugPrint('📍 Stack Trace: $stackTrace');
      return false;
    }
  }

  /// 使用其他 OAuth Provider 登入（Apple, GitHub, Facebook 等）
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    try {
      await _supabase.auth.signInWithOAuth(
        provider,
        // 移除 redirectTo，讓 Supabase 自動處理 callback
      );
      debugPrint('✅ ${provider.name} 登入流程已啟動');
      return true;
    } catch (e) {
      debugPrint('❌ ${provider.name} 登入失敗: $e');
      return false;
    }
  }

  // ==================== 更新使用者資料 ====================
  
  /// 更新使用者的 metadata
  /// 
  /// 例如：暱稱、頭像、生日等
  Future<UserResponse> updateUserMetadata(Map<String, dynamic> metadata) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(data: metadata),
      );
      debugPrint('✅ 使用者資料更新成功');
      return response;
    } catch (e) {
      debugPrint('❌ 使用者資料更新失敗: $e');
      rethrow;
    }
  }

  /// 更新使用者的 Email
  Future<UserResponse> updateEmail(String newEmail) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(email: newEmail.trim()),
      );
      debugPrint('✅ Email 更新成功');
      return response;
    } catch (e) {
      debugPrint('❌ Email 更新失敗: $e');
      rethrow;
    }
  }

  // ==================== Session 管理 ====================
  
  /// 取得當前 Session
  Session? get currentSession => _supabase.auth.currentSession;

  /// 檢查 Session 是否過期
  bool get isSessionExpired {
    final session = currentSession;
    if (session == null) return true;
    
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;
    
    return DateTime.now().millisecondsSinceEpoch >= expiresAt * 1000;
  }

  /// 手動刷新 Session
  Future<AuthResponse> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      debugPrint('✅ Session 刷新成功');
      return response;
    } catch (e) {
      debugPrint('❌ Session 刷新失敗: $e');
      rethrow;
    }
  }
}
