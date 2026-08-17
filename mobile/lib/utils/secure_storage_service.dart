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

  /// Helpers con API similar a SharedPreferences
  static Future<void> setString(String key, String? value) async {
    if (value == null) {
      await delete(key);
    } else {
      await write(key, value);
    }
  }

  static Future<String?> getString(String key) async => read(key);

  static Future<void> setBool(String key, bool value) async {
    await write(key, value.toString());
  }

  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value = await read(key);
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true';
  }

  static Future<void> setInt(String key, int? value) async {
    if (value == null) {
      await delete(key);
    } else {
      await write(key, value.toString());
    }
  }

  static Future<int> getInt(String key, {int defaultValue = 0}) async {
    final value = await read(key);
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  static Future<void> setStringList(String key, List<String> value) async {
    await write(key, value.join(','));
  }

  static Future<List<String>> getStringList(String key) async {
    final value = await read(key);
    if (value == null || value.isEmpty) return [];
    return value.split(',');
  }

  static Future<void> remove(String key) async => delete(key);

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
