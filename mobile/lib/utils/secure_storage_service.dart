import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio de almacenamiento seguro para datos sensibles del usuario.
/// Usa el keychain/keystore nativo en iOS/Android.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accountName: 'roommatematch_secure_storage',
    ),
  );

  /// Guardar un dato cifrado
  static Future<void> write(String key, String value) async {
    await _storage.write(key: _sanitizeKey(key), value: value);
  }

  /// Leer un dato cifrado
  static Future<String?> read(String key) async {
    return _storage.read(key: _sanitizeKey(key));
  }

  /// Eliminar un dato cifrado
  static Future<void> delete(String key) async {
    await _storage.delete(key: _sanitizeKey(key));
  }

  /// Eliminar todos los datos cifrados
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Almacenar credenciales de sesión (no guardar password en texto plano)
  static Future<void> saveSessionToken(String token) async {
    await write('session_token', token);
  }

  static Future<String?> getSessionToken() async {
    return read('session_token');
  }

  static Future<void> clearSession() async {
    await delete('session_token');
    await delete('refresh_token');
  }

  static String _sanitizeKey(String key) {
    return 'roommatematch_${key.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}';
  }
}
