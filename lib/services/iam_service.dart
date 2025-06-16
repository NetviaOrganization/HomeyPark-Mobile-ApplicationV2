import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homeypark_mobile_application/model/user_model.dart'; // Ajusta la ruta si es necesario

/// Helper class to store user data along with the password hash.
class _StoredUser {
  final UserModel user;
  final String passwordHash;

  _StoredUser({required this.user, required this.passwordHash});

  factory _StoredUser.fromJson(Map<String, dynamic> json) {
    return _StoredUser(
      user: UserModel.fromJson(json['user']),
      passwordHash: json['passwordHash'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'passwordHash': passwordHash,
    };
  }
}

class IAMService extends ChangeNotifier {
  IAMService();

  late final SharedPreferences _prefs;
  final Map<String, _StoredUser> _userDatabase = {};

  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _sessionTimer;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static const String _userDatabaseKey = 'user_data_store';
  static const String _sessionUserKey = 'session_active_user_email';
  static const String _sessionExpiryKey = 'session_expiry';
  static const Duration _sessionDuration = Duration(hours: 24);
  
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadUserDatabase();
    await _tryResumeSession();
    _isLoading = false;
    notifyListeners();
  }

  /// Verifies the reCAPTCHA token by simulating a backend call.
  Future<bool> _verifyRecaptchaToken(String token) async {
    // IN A REAL APP:
    // This is where you would make an HTTP POST request to:
    // https://www.google.com/recaptcha/api/siteverify
    // with your 'secret' key and the 'response' (the token).
    // final response = await http.post(Uri.parse('...'), body: {'secret': secretKey, 'response': token});
    // final data = json.decode(response.body);
    // return data['success'] == true;

    // MOCK IMPLEMENTATION:
    // For this example, we just ensure the token is not empty
    // and simulate a short network delay.
    await Future.delayed(const Duration(milliseconds: 400));
    final secretKey = dotenv.env['RECAPTCHA_SECRET_KEY'];
    
    debugPrint('Verifying reCAPTCHA token (simulated)... Secret: $secretKey, Token: $token');
    
    // Simple simulation: if the token is not empty, it's considered valid.
    return token.isNotEmpty;
  }

  Future<bool> signUp(SignUpData data) => _performAuthOperation(
    () async {
      // First, verify reCAPTCHA
      final isHuman = await _verifyRecaptchaToken(data.recaptchaToken);
      if (!isHuman) {
        throw 'reCAPTCHA verification failed. Please try again.';
      }
      
      final email = data.email.toLowerCase();
      if (_userDatabase.containsKey(email)) {
        throw 'This email is already registered.';
      }

      final newUser = UserModel(
        id: _generateId(),
        email: email,
        name: data.name.trim(),
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      final storedUser = _StoredUser(
        user: newUser,
        passwordHash: _hashPassword(data.password),
      );
      
      _userDatabase[email] = storedUser;
      await _saveUserDatabase();
      
      _setCurrentUser(newUser);
      await _createSession();
    },
    errorContext: 'Sign-up failed',
  );

  Future<bool> signIn(SignInData data) => _performAuthOperation(
    () async {
      // First, verify reCAPTCHA
      final isHuman = await _verifyRecaptchaToken(data.recaptchaToken);
      if (!isHuman) {
        throw 'reCAPTCHA verification failed. Please try again.';
      }
      
      final email = data.email.toLowerCase();
      final storedUser = _userDatabase[email];

      if (storedUser == null || storedUser.passwordHash != _hashPassword(data.password)) {
        throw 'Incorrect email or password.';
      }

      final updatedUser = storedUser.user.copyWith(lastLoginAt: DateTime.now());
      _userDatabase[email] = _StoredUser(user: updatedUser, passwordHash: storedUser.passwordHash);
      await _saveUserDatabase();

      _setCurrentUser(updatedUser);
      await _createSession();
    },
    errorContext: 'Sign-in failed',
  );
  
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    _currentUser = null;
    _sessionTimer?.cancel();
    await _prefs.remove(_sessionUserKey);
    await _prefs.remove(_sessionExpiryKey);
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
  
  Future<bool> updateProfile({String? name, ValueGetter<String?>? profileImageUrl}) => _performAuthOperation(
    () async {
      if (!isAuthenticated) throw 'User not authenticated.';
      final updatedUser = _currentUser!.copyWith(name: name, profileImageUrl: profileImageUrl);
      _userDatabase[_currentUser!.email] = _StoredUser(
        user: updatedUser,
        passwordHash: _userDatabase[_currentUser!.email]!.passwordHash,
      );
      await _saveUserDatabase();
      _setCurrentUser(updatedUser);
    },
    errorContext: 'Profile update failed',
  );

  Future<bool> _performAuthOperation(Future<void> Function() operation, {required String errorContext}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await operation();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '$errorContext: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _setCurrentUser(UserModel user) {
    _currentUser = user;
  }

  Future<void> _tryResumeSession() async {
    final expiryString = _prefs.getString(_sessionExpiryKey);
    final userEmail = _prefs.getString(_sessionUserKey);
    if (expiryString == null || userEmail == null) return;
    final expiryDate = DateTime.parse(expiryString);
    if (expiryDate.isBefore(DateTime.now())) {
      await signOut();
      return;
    }
    final storedUser = _userDatabase[userEmail];
    if (storedUser != null) {
      _setCurrentUser(storedUser.user);
      _setupSessionTimer(expiryDate);
    }
  }
  
  Future<void> _createSession() async {
    if (_currentUser == null) return;
    final expiryDate = DateTime.now().add(_sessionDuration);
    await _prefs.setString(_sessionExpiryKey, expiryDate.toIso8601String());
    await _prefs.setString(_sessionUserKey, _currentUser!.email);
    _setupSessionTimer(expiryDate);
  }

  void _loadUserDatabase() {
    final jsonString = _prefs.getString(_userDatabaseKey);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> decodedMap = json.decode(jsonString);
        _userDatabase.clear();
        _userDatabase.addAll(
          decodedMap.map((key, value) => MapEntry(key, _StoredUser.fromJson(value)))
        );
      } catch (e) {
        debugPrint('Failed to load user database, could be corrupt: $e');
        _prefs.remove(_userDatabaseKey);
      }
    }
  }

  Future<void> _saveUserDatabase() async {
    final jsonString = json.encode(
      _userDatabase.map((key, value) => MapEntry(key, value.toJson()))
    );
    await _prefs.setString(_userDatabaseKey, jsonString);
  }

  void _setupSessionTimer(DateTime expiryDate) {
    _sessionTimer?.cancel();
    final timeUntilExpiry = expiryDate.difference(DateTime.now());
    if (!timeUntilExpiry.isNegative) {
      _sessionTimer = Timer(timeUntilExpiry, signOut);
    }
  }
  
  String _hashPassword(String password) {
    const String staticSalt = 'a_more_secure_static_salt_for_mock_2024'; 
    final bytes = utf8.encode(password + staticSalt);
    return sha256.convert(bytes).toString();
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}