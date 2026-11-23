import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';

/// A single PSGC location option returned by the public address API.
class PsgcOption {
  const PsgcOption({required this.code, required this.name});

  final String code;
  final String name;

  /// Finds the option whose name matches [name], ignoring case and padding.
  static PsgcOption? matchByName(List<PsgcOption> options, String name) {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final option in options) {
      if (option.name.toLowerCase() == needle) return option;
    }
    return null;
  }

  /// Returns the display name for [code], or an empty string when unknown.
  static String nameFor(List<PsgcOption> options, String? code) {
    if (code == null) return '';
    for (final option in options) {
      if (option.code == code) return option.name;
    }
    return '';
  }
}

/// A safe, user-facing PSGC lookup failure.
class PsgcFailure implements Exception {
  const PsgcFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Loads Philippine provinces, cities, and barangays with in-memory caching.
class PsgcService {
  PsgcService({http.Client? client}) : _client = client ?? http.Client();

  static const String metroManilaCode = '130000000';
  static const String _metroManilaName = 'Metro Manila';
  static const Duration _timeout = Duration(seconds: 20);

  final http.Client _client;
  final Map<String, List<PsgcOption>> _cache = <String, List<PsgcOption>>{};

  Future<List<PsgcOption>> fetchProvinces() {
    return _cached('provinces', () async {
      final raw = await _getList('/provinces/');
      final options = raw.map(_toOption).whereType<PsgcOption>().toList();
      final hasMetroManila = options.any(
        (option) => option.name == _metroManilaName,
      );
      if (!hasMetroManila) {
        options.add(
          const PsgcOption(code: metroManilaCode, name: _metroManilaName),
        );
      }
      options.sort(_byName);
      return options;
    });
  }

  Future<List<PsgcOption>> fetchCities(String provinceCode) {
    return _cached('cities:$provinceCode', () async {
      final path = provinceCode == metroManilaCode
          ? '/regions/$provinceCode/cities-municipalities/'
          : '/provinces/$provinceCode/cities-municipalities/';
      final raw = await _getList(path);
      final options = raw.map(_toOption).whereType<PsgcOption>().toList();
      options.sort(_byName);
      return options;
    });
  }

  Future<List<PsgcOption>> fetchBarangays(String cityCode) {
    return _cached('barangays:$cityCode', () async {
      final raw = await _getList('/cities-municipalities/$cityCode/barangays/');
      final options = raw.map(_toOption).whereType<PsgcOption>().toList();
      options.sort(_byName);
      return options;
    });
  }

  Future<List<PsgcOption>> _cached(
    String key,
    Future<List<PsgcOption>> Function() loader,
  ) async {
    final cached = _cache[key];
    if (cached != null) return cached;
    final value = await loader();
    _cache[key] = value;
    return value;
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final uri = Uri.parse('${AppConstants.psgcBaseUrl}$path');
    try {
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        throw const PsgcFailure(
          'Address lookup is unavailable right now. Please try again.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const PsgcFailure('Address lookup returned unexpected data.');
      }
      return decoded.whereType<Map<String, dynamic>>().toList();
    } on PsgcFailure {
      rethrow;
    } catch (_) {
      throw const PsgcFailure(
        'Could not load address options. Check your connection and retry.',
      );
    }
  }

  PsgcOption? _toOption(Map<String, dynamic> item) {
    final code = item['code'];
    final name = item['name'];
    if (code is! String || name is! String) return null;
    if (code.trim().isEmpty || name.trim().isEmpty) return null;
    return PsgcOption(code: code.trim(), name: name.trim());
  }

  int _byName(PsgcOption a, PsgcOption b) {
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }
}
