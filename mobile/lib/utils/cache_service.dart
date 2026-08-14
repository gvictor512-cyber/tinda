import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/secure_logger.dart';

class CacheService {
  static const String _prefix = 'cache_';
  static const int _defaultTTL = 300; // 5 minutes in seconds

  /// Cache a value with optional TTL
  Future<void> set(
    String key,
    dynamic value, {
    int? ttl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_prefix$key';
      
      final cacheItem = CacheItem(
        value: value,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        ttl: ttl ?? _defaultTTL,
      );

      await prefs.setString(cacheKey, jsonEncode(cacheItem.toJson()));
      
      SecureLogger.debug('Cached value', data: {
        'key': key,
        'ttl': ttl ?? _defaultTTL,
      });
    } catch (e) {
      SecureLogger.error('Failed to cache value', error: e, data: {
        'key': key,
      });
    }
  }

  /// Get a cached value if it exists and hasn't expired
  Future<T?> get<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_prefix$key';
      
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson == null) {
        return null;
      }

      final cacheItem = CacheItem.fromJson(jsonDecode(cachedJson));
      
      // Check if expired
      if (_isExpired(cacheItem)) {
        await remove(key);
        SecureLogger.debug('Cache expired', data: {
          'key': key,
        });
        return null;
      }

      SecureLogger.debug('Cache hit', data: {
        'key': key,
        'age': DateTime.now().millisecondsSinceEpoch - cacheItem.timestamp,
      });

      return cacheItem.value as T?;
    } catch (e) {
      SecureLogger.error('Failed to get cached value', error: e, data: {
        'key': key,
      });
      return null;
    }
  }

  /// Check if a key exists in cache and is not expired
  Future<bool> has(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_prefix$key';
      
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson == null) {
        return false;
      }

      final cacheItem = CacheItem.fromJson(jsonDecode(cachedJson));
      
      if (_isExpired(cacheItem)) {
        await remove(key);
        return false;
      }

      return true;
    } catch (e) {
      SecureLogger.error('Failed to check cache', error: e);
      return false;
    }
  }

  /// Remove a specific key from cache
  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_prefix$key';
      
      await prefs.remove(cacheKey);
      
      SecureLogger.debug('Cache removed', data: {
        'key': key,
      });
    } catch (e) {
      SecureLogger.error('Failed to remove cache', error: e);
    }
  }

  /// Clear all cache
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_prefix)) {
          await prefs.remove(key);
        }
      }
      
      SecureLogger.info('Cache cleared');
    } catch (e) {
      SecureLogger.error('Failed to clear cache', error: e);
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int clearedCount = 0;
      
      for (final key in keys) {
        if (key.startsWith(_prefix)) {
          final cachedJson = prefs.getString(key);
          if (cachedJson != null) {
            try {
              final cacheItem = CacheItem.fromJson(jsonDecode(cachedJson));
              if (_isExpired(cacheItem)) {
                await prefs.remove(key);
                clearedCount++;
              }
            } catch (e) {
              // Invalid cache entry, remove it
              await prefs.remove(key);
              clearedCount++;
            }
          }
        }
      }
      
      SecureLogger.info('Expired cache cleared', data: {
        'count': clearedCount,
      });
    } catch (e) {
      SecureLogger.error('Failed to clear expired cache', error: e);
    }
  }

  /// Get or set pattern - fetch from cache if available, otherwise use the provided function
  Future<T> getOrSet<T>(
    String key,
    Future<T> Function() fetcher, {
    int? ttl,
  }) async {
    final cached = await get<T>(key);
    if (cached != null) {
      return cached;
    }

    final value = await fetcher();
    await set(key, value, ttl: ttl);
    return value;
  }

  /// Cache a list with individual item tracking
  Future<void> setList<T>(
    String key,
    List<T> list, {
    int? ttl,
  }) async {
    await set(key, list, ttl: ttl);
  }

  /// Get a cached list
  Future<List<T>?> getList<T>(String key) async {
    return await get<List<T>>(key);
  }

  /// Invalidate cache by pattern
  Future<void> invalidatePattern(String pattern) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final regex = RegExp(pattern, caseSensitive: false);
      
      for (final key in keys) {
        if (key.startsWith(_prefix) && regex.hasMatch(key)) {
          await prefs.remove(key);
        }
      }
      
      SecureLogger.info('Cache pattern invalidated', data: {
        'pattern': pattern,
      });
    } catch (e) {
      SecureLogger.error('Failed to invalidate cache pattern', error: e);
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int totalEntries = 0;
      int expiredEntries = 0;
      int totalSize = 0;
      
      for (final key in keys) {
        if (key.startsWith(_prefix)) {
          totalEntries++;
          final cachedJson = prefs.getString(key);
          if (cachedJson != null) {
            totalSize += cachedJson.length;
            try {
              final cacheItem = CacheItem.fromJson(jsonDecode(cachedJson));
              if (_isExpired(cacheItem)) {
                expiredEntries++;
              }
            } catch (e) {
              expiredEntries++;
            }
          }
        }
      }
      
      return {
        'totalEntries': totalEntries,
        'expiredEntries': expiredEntries,
        'validEntries': totalEntries - expiredEntries,
        'totalSize': totalSize,
        'totalSizeKB': (totalSize / 1024).toStringAsFixed(2),
      };
    } catch (e) {
      SecureLogger.error('Failed to get cache stats', error: e);
      return {};
    }
  }

  /// Check if cache item is expired
  bool _isExpired(CacheItem item) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - item.timestamp) > (item.ttl * 1000);
  }
}

class CacheItem {
  final dynamic value;
  final int timestamp;
  final int ttl;

  CacheItem({
    required this.value,
    required this.timestamp,
    required this.ttl,
  });

  factory CacheItem.fromJson(Map<String, dynamic> json) {
    return CacheItem(
      value: json['value'],
      timestamp: json['timestamp'],
      ttl: json['ttl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'timestamp': timestamp,
      'ttl': ttl,
    };
  }
}

/// Specialized cache for user data
class UserDataCache {
  final CacheService _cache = CacheService();
  static const int _userTTL = 600; // 10 minutes

  Future<void> cacheUser(String userId, Map<String, dynamic> userData) async {
    await _cache.set('user_$userId', userData, ttl: _userTTL);
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    return await _cache.get<Map<String, dynamic>>('user_$userId');
  }

  Future<void> invalidateUser(String userId) async {
    await _cache.remove('user_$userId');
  }
}

/// Specialized cache for matches
class MatchesCache {
  final CacheService _cache = CacheService();
  static const int _matchesTTL = 180; // 3 minutes

  Future<void> cacheMatches(String userId, List<Map<String, dynamic>> matches) async {
    await _cache.set('matches_$userId', matches, ttl: _matchesTTL);
  }

  Future<List<Map<String, dynamic>>?> getMatches(String userId) async {
    return await _cache.get<List<Map<String, dynamic>>>('matches_$userId');
  }

  Future<void> invalidateMatches(String userId) async {
    await _cache.remove('matches_$userId');
  }
}

/// Specialized cache for chats
class ChatsCache {
  final CacheService _cache = CacheService();
  static const int _chatsTTL = 120; // 2 minutes

  Future<void> cacheChats(String userId, List<Map<String, dynamic>> chats) async {
    await _cache.set('chats_$userId', chats, ttl: _chatsTTL);
  }

  Future<List<Map<String, dynamic>>?> getChats(String userId) async {
    return await _cache.get<List<Map<String, dynamic>>>('chats_$userId');
  }

  Future<void> invalidateChats(String userId) async {
    await _cache.remove('chats_$userId');
  }

  Future<void> cacheMessages(String chatId, List<Map<String, dynamic>> messages) async {
    await _cache.set('messages_$chatId', messages, ttl: _chatsTTL);
  }

  Future<List<Map<String, dynamic>>?> getMessages(String chatId) async {
    return await _cache.get<List<Map<String, dynamic>>>('messages_$chatId');
  }

  Future<void> invalidateMessages(String chatId) async {
    await _cache.remove('messages_$chatId');
  }
}

/// Specialized cache for potential matches
class PotentialMatchesCache {
  final CacheService _cache = CacheService();
  static const int _potentialMatchesTTL = 300; // 5 minutes

  Future<void> cachePotentialMatches(String userId, List<Map<String, dynamic>> matches) async {
    await _cache.set('potential_matches_$userId', matches, ttl: _potentialMatchesTTL);
  }

  Future<List<Map<String, dynamic>>?> getPotentialMatches(String userId) async {
    return await _cache.get<List<Map<String, dynamic>>>('potential_matches_$userId');
  }

  Future<void> invalidatePotentialMatches(String userId) async {
    await _cache.remove('potential_matches_$userId');
  }
}
