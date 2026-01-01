import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 地理位置信息
class GeoInfo {
  final String countryCode;
  final String country;
  final bool isChina;
  final DateTime fetchedAt;

  const GeoInfo({
    required this.countryCode,
    required this.country,
    required this.isChina,
    required this.fetchedAt,
  });

  factory GeoInfo.fromJson(Map<String, dynamic> json) {
    final countryCode = json['countryCode'] as String? ?? '';
    return GeoInfo(
      countryCode: countryCode,
      country: json['country'] as String? ?? '',
      isChina: countryCode == 'CN',
      fetchedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'countryCode': countryCode,
    'country': country,
    'isChina': isChina,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory GeoInfo.fromCache(Map<String, dynamic> json) {
    return GeoInfo(
      countryCode: json['countryCode'] as String? ?? '',
      country: json['country'] as String? ?? '',
      isChina: json['isChina'] as bool? ?? false,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );
  }

  /// 默认值（非中国）
  factory GeoInfo.defaultValue() {
    return GeoInfo(
      countryCode: 'US',
      country: 'United States',
      isChina: false,
      fetchedAt: DateTime.now(),
    );
  }
}

/// 地理位置服务
/// 使用 ip-api.com 获取用户地理位置
class GeoService {
  static const String _cacheKey = 'geo_info_cache';
  static const Duration _cacheValidDuration = Duration(days: 7);
  static const Duration _requestTimeout = Duration(seconds: 3);

  GeoInfo? _cachedInfo;

  /// 获取地理位置信息
  /// 优先使用缓存，缓存过期或不存在时从 API 获取
  Future<GeoInfo> getGeoInfo() async {
    // 1. 检查内存缓存
    if (_cachedInfo != null && _isCacheValid(_cachedInfo!)) {
      return _cachedInfo!;
    }

    // 2. 检查本地存储缓存
    final localCache = await _loadFromLocal();
    if (localCache != null && _isCacheValid(localCache)) {
      _cachedInfo = localCache;
      return localCache;
    }

    // 3. 从 API 获取
    try {
      final info = await _fetchFromApi();
      _cachedInfo = info;
      await _saveToLocal(info);
      return info;
    } catch (e) {
      print('Failed to fetch geo info: $e');
      // 如果有过期缓存，仍然使用
      if (localCache != null) {
        _cachedInfo = localCache;
        return localCache;
      }
      // 返回默认值
      return GeoInfo.defaultValue();
    }
  }

  /// 强制刷新地理位置信息
  Future<GeoInfo> refreshGeoInfo() async {
    try {
      final info = await _fetchFromApi();
      _cachedInfo = info;
      await _saveToLocal(info);
      return info;
    } catch (e) {
      print('Failed to refresh geo info: $e');
      return _cachedInfo ?? GeoInfo.defaultValue();
    }
  }

  /// 检查是否在中国
  Future<bool> isInChina() async {
    final info = await getGeoInfo();
    return info.isChina;
  }

  /// 从 ip-api.com 获取地理位置
  Future<GeoInfo> _fetchFromApi() async {
    final response = await http.get(
      Uri.parse('http://ip-api.com/json/?fields=status,country,countryCode'),
    ).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('API returned ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    
    if (json['status'] != 'success') {
      throw Exception('API returned status: ${json['status']}');
    }

    return GeoInfo.fromJson(json);
  }

  /// 检查缓存是否有效
  bool _isCacheValid(GeoInfo info) {
    return DateTime.now().difference(info.fetchedAt) < _cacheValidDuration;
  }

  /// 从本地存储加载缓存
  Future<GeoInfo?> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr == null) return null;
      
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return GeoInfo.fromCache(json);
    } catch (e) {
      print('Failed to load geo cache: $e');
      return null;
    }
  }

  /// 保存到本地存储
  Future<void> _saveToLocal(GeoInfo info) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(info.toJson()));
    } catch (e) {
      print('Failed to save geo cache: $e');
    }
  }

  /// 清除缓存
  Future<void> clearCache() async {
    _cachedInfo = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      print('Failed to clear geo cache: $e');
    }
  }
}
