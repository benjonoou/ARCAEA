import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../main.dart'; // 導入 MainScreen

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ==================== Controllers & State ====================
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService(); // 使用 AuthService
  
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSignUpMode = false; // 切換登入/註冊模式

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==================== 登入邏輯 ====================
  
  Future<void> _signIn() async {
    // 驗證表單
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      debugPrint('🔐 嘗試登入 - Email: ${_emailController.text.trim()}');
      debugPrint('🔐 密碼長度: ${_passwordController.text.length}');
      
      final response = await _authService.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      
      if (response.user != null) {
        // 登入成功
        debugPrint('✅ 登入成功 - User ID: ${response.user!.id}');
        
        // 取得使用者名稱（優先使用 username，否則用 email）
        final metadata = response.user!.userMetadata;
        final displayName = metadata?['username'] ?? 
                           metadata?['display_name'] ?? 
                           metadata?['full_name'] ?? 
                           metadata?['name'] ?? 
                           response.user!.email?.split('@').first ?? 
                           '使用者';
        
        _showSnackBar(
          '歡迎回來，$displayName！',
          Colors.green,
        );
        
        // 手動導航到主畫面
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainScreen(),
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      debugPrint('❌ 登入失敗 - Error Code: ${e.statusCode}');
      debugPrint('❌ Error Message: ${e.message}');
      _showAuthError(e);
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ 未預期錯誤: $e');
      _showSnackBar('發生未預期的錯誤：$e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== 註冊邏輯 ====================
  
  Future<void> _signUp() async {
    // 驗證表單
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      debugPrint('📝 嘗試註冊 - Email: ${_emailController.text.trim()}');
      debugPrint('📝 Username: ${_usernameController.text.trim()}');
      debugPrint('📝 密碼長度: ${_passwordController.text.length}');
      
      final response = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        metadata: {
          'username': _usernameController.text.trim(),
          'display_name': _usernameController.text.trim(),
        },
      );

      if (!mounted) return;
      
      if (response.user != null) {
        // 註冊成功
        debugPrint('✅ 註冊成功 - User ID: ${response.user!.id}');
        debugPrint('✅ Email: ${response.user!.email}');
        debugPrint('✅ Email Confirmed: ${response.user!.emailConfirmedAt}');
        
        _showSnackBar(
          '註冊成功！現在可以登入了',
          Colors.green,
          duration: 3,
        );
        
        // 切回登入模式但保留 Email（方便直接登入）
        setState(() {
          _isSignUpMode = false;
          _usernameController.clear();
          // 保留 email 和 password 方便測試
          // _emailController.clear();
          // _passwordController.clear();
        });
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      debugPrint('❌ 註冊失敗 - Error Code: ${e.statusCode}');
      debugPrint('❌ Error Message: ${e.message}');
      _showAuthError(e);
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ 未預期錯誤: $e');
      _showSnackBar('發生未預期的錯誤：$e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== Google 登入 ====================
  
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final success = await _authService.signInWithGoogle();
      
      if (!mounted) return;
      
      if (success) {
        // Google 登入成功，導航到主畫面
        debugPrint('✅ Google 登入成功');
        _showSnackBar('Google 登入成功！', Colors.green);
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainScreen(),
          ),
        );
      } else {
        _showSnackBar('Google 登入已取消', Colors.orange);
      }
      
    } on AuthException catch (e) {
      if (!mounted) return;
      _showGoogleAuthError(e);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Google 登入失敗：$e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== 開發者登入（測試用）====================
  
  Future<void> _devLogin() async {
    setState(() => _isLoading = true);
    
    // 短暫延遲以顯示載入動畫
    await Future.delayed(Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    // 顯示開發者模式提示
    _showSnackBar(
      '🔧 開發者模式：略過認證直接進入',
      Colors.orange,
      duration: 2,
    );
    
    // 導航到主畫面
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainScreen(),
      ),
    );
    
    setState(() => _isLoading = false);
  }

  // ==================== Helper Methods ====================
  
  /// 切換登入/註冊模式
  void _toggleMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode;
      _usernameController.clear();
      _emailController.clear();
      _passwordController.clear();
    });
  }

  /// 顯示 SnackBar 訊息
  void _showSnackBar(String message, Color backgroundColor, {int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: duration),
      ),
    );
  }

  /// 顯示認證錯誤訊息（中文化）
  void _showAuthError(AuthException e) {
    String message;
    
    switch (e.message.toLowerCase()) {
      case 'invalid login credentials':
        message = '帳號或密碼錯誤';
        break;
      case 'user already registered':
        message = '此 Email 已被註冊';
        break;
      case 'email not confirmed':
        message = '請先驗證您的 Email';
        break;
      case 'invalid email':
        message = 'Email 格式不正確';
        break;
      case 'password is too weak':
        message = '密碼強度不足（至少 6 個字元）';
        break;
      default:
        message = e.message;
    }
    
    _showSnackBar(message, Colors.red, duration: 5);
  }

  /// 顯示 Google 登入錯誤訊息
  void _showGoogleAuthError(AuthException e) {
    String message = e.message;
    bool showDetail = false;
    
    if (e.message.contains('provider is not enabled')) {
      message = '請先在 Supabase Dashboard 啟用 Google 登入\n'
                'Authentication → Providers → Google';
      showDetail = true;
    } else if (e.message.contains('redirect')) {
      message = 'Redirect URI 設定錯誤\n請檢查 Google Cloud Console';
      showDetail = true;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
        action: showDetail ? SnackBarAction(
          label: '詳情',
          textColor: Colors.white,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('錯誤詳情'),
                content: Text('錯誤碼: ${e.statusCode}\n訊息: ${e.message}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('確定'),
                  ),
                ],
              ),
            );
          },
        ) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6B4E9B), // Purple
              Color(0xFF4A3A7A), // Darker purple
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title - 根據模式切換
                    Text(
                      _isSignUpMode ? 'Sign up' : 'Login or DI',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 60),

                    // Username Field - 只在註冊模式顯示
                    if (_isSignUpMode) ...[
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _usernameController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'User name',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                    ],

                    // Email Field
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'E-mail',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),

                    // Password Field
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 60),

                    // Sign In / Sign Up Button - 根據模式切換
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : (_isSignUpMode ? _signUp : _signIn),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                _isSignUpMode ? 'Sign up' : 'Sign in',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 4),

                    // Toggle Sign Up/Sign In Link
                    TextButton(
                      onPressed: _isLoading ? null : _toggleMode,
                      child: Text(
                        _isSignUpMode 
                            ? 'Already have an account? Sign in'
                            : 'Don\'t have an account? Create one now',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Divider with "OR"
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.3),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.3),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Google Sign In Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF1F1F1F),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google logo
                            Image.asset(
                              'assets/icons/Google__G__logo.svg.webp',
                              height: 24,
                              width: 24,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to text "G" if image fails to load
                                return Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4285F4),
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 40),

                    // Developer Login Button (測試用)
                    TextButton.icon(
                      onPressed: _isLoading ? null : _devLogin,
                      icon: Icon(
                        Icons.code,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 18,
                      ),
                      label: Text(
                        '🔧 開發者登入（測試用）',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
