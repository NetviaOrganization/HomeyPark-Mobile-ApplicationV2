import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:homeypark_mobile_application/model/user_model.dart';

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

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'passwordHash': passwordHash,
      };
}

class IAMService extends ChangeNotifier {
  // El constructor ahora está vacío. La inicialización se manejará explícitamente.
  IAMService();

  // Las propiedades son ahora 'late final', indicando que se inicializarán una vez.
  late final SharedPreferences _prefs;
  final Map<String, _StoredUser> _userDatabase = {};

  UserModel? _currentUser;
  // isLoading comienza en `false`. Solo se activa durante operaciones específicas.
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _sessionTimer;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Constantes para las claves de almacenamiento y duración de la sesión.
  static const String _userDatabaseKey = 'user_data_store';
  static const String _sessionUserKey = 'session_active_user_email';
  static const String _sessionExpiryKey = 'session_expiry';
  static const Duration _sessionDuration = Duration(hours: 24);

  /// --- MEJORA CLAVE: Inicialización Explícita ---
  /// Este método debe ser llamado desde `main.dart` ANTES de que la app se inicie.
  /// Esto asegura que el servicio esté listo sin bloquear la UI con un estado de carga inicial.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadUserDatabase();
    await _tryResumeSession();
    // No se necesita `notifyListeners()` aquí, ya que la UI aún no se ha construido.
  }

  /// Verifica el token de reCAPTCHA simulando una llamada de backend.
 Future<bool> _verifyRecaptchaToken(String token) async {
    final secretKey = dotenv.env['RECAPTCHA_SECRET_KEY'];

    // Comprobación de seguridad: asegúrate de que la clave secreta esté configurada.
    if (secretKey == null || secretKey.isEmpty) {
      debugPrint("Error: RECAPTCHA_SECRET_KEY no está configurada en el archivo .env.");
      return false;
    }

    try {
      final uri = Uri.parse('https://www.google.com/recaptcha/api/siteverify');
      
      // Hacemos la llamada POST a la API de Google.
      final response = await http.post(
        uri,
        body: {
          'secret': secretKey,
          'response': token,
          // Opcional: puedes enviar la IP del usuario para mayor seguridad.
          // 'remoteip': userIpAddress, 
        },
      );

      if (response.statusCode == 200) {
        // La llamada fue exitosa, ahora decodificamos la respuesta JSON.
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (kDebugMode) {
          print('Respuesta de verificación de reCAPTCHA: $data');
        }

        // La respuesta de Google contiene un campo 'success' que es true o false.
        return data['success'] == true;
      } else {
        // La llamada a la API de Google falló (ej: error 500, 404).
        debugPrint('Error al contactar el servidor de reCAPTCHA: ${response.statusCode}');
        debugPrint('Cuerpo de la respuesta: ${response.body}');
        return false;
      }
    } catch (e) {
      // Ocurrió un error de red (ej: sin conexión a internet).
      debugPrint('Excepción al verificar el token de reCAPTCHA: $e');
      return false;
    }
  }

  void clearErrorMessage() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> signUp(SignUpData data) => _performAuthOperation(() async {
    // 1. Verificación de reCAPTCHA
    final isHuman = await _verifyRecaptchaToken(data.recaptchaToken);
    if (!isHuman) {
      throw 'La verificación reCAPTCHA ha fallado. Por favor, inténtalo de nuevo.';
    }

    final email = data.email.toLowerCase();
    if (_userDatabase.containsKey(email)) {
      throw 'Este correo electrónico ya está registrado.';
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
  });

  Future<bool> signIn(SignInData data) => _performAuthOperation(() async {
    // 1. Verificación de reCAPTCHA
    final isHuman = await _verifyRecaptchaToken(data.recaptchaToken);
    if (!isHuman) {
      throw 'La verificación reCAPTCHA ha fallado. Por favor, inténtalo de nuevo.';
    }

    final email = data.email.toLowerCase();
    final storedUser = _userDatabase[email];

    if (storedUser == null || storedUser.passwordHash != _hashPassword(data.password)) {
      throw 'Correo electrónico o contraseña incorrectos.';
    }

    final updatedUser = storedUser.user.copyWith(lastLoginAt: DateTime.now());
    _userDatabase[email] = _StoredUser(user: updatedUser, passwordHash: storedUser.passwordHash);
    await _saveUserDatabase();

    _setCurrentUser(updatedUser);
    await _createSession();
  });

  Future<void> signOut() async {
    _setLoading(true);
    _currentUser = null;
    _sessionTimer?.cancel();
    await _prefs.remove(_sessionUserKey);
    await _prefs.remove(_sessionExpiryKey);
    _errorMessage = null;
    _setLoading(false);
  }

  Future<bool> updateProfile({String? name, ValueGetter<String?>? profileImageUrl}) => _performAuthOperation(() async {
    if (!isAuthenticated) throw 'Usuario no autenticado.';
    final updatedUser = _currentUser!.copyWith(name: name, profileImageUrl: profileImageUrl);
    _userDatabase[_currentUser!.email] = _StoredUser(
      user: updatedUser,
      passwordHash: _userDatabase[_currentUser!.email]!.passwordHash,
    );
    await _saveUserDatabase();
    _setCurrentUser(updatedUser);
  });
  
  // --- MEJORA: Wrapper de operación de autenticación más robusto ---
  Future<bool> _performAuthOperation(Future<void> Function() operation) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      await operation();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void _setCurrentUser(UserModel user) {
    _currentUser = user;
    // Notifica a los oyentes solo cuando el usuario cambia.
    notifyListeners();
  }

  // --- MEJORA: Método helper para gestionar el estado de carga ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _tryResumeSession() async {
    final expiryString = _prefs.getString(_sessionExpiryKey);
    final userEmail = _prefs.getString(_sessionUserKey);

    if (expiryString == null || userEmail == null) return;

    final expiryDate = DateTime.tryParse(expiryString);
    if (expiryDate == null || expiryDate.isBefore(DateTime.now())) {
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
            decodedMap.map((key, value) => MapEntry(key, _StoredUser.fromJson(value))));
      } catch (e) {
        debugPrint('Failed to load user database: $e');
        _prefs.remove(_userDatabaseKey);
      }
    }
  }

  Future<void> _saveUserDatabase() async {
    final jsonString = json.encode(
      _userDatabase.map((key, value) => MapEntry(key, value.toJson())),
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

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}