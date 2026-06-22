import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/icd_code.dart';

/// Offline ortopedi ICD subset arama servisi.
class IcdLookupService {
  IcdLookupService._();

  static final IcdLookupService instance = IcdLookupService._();

  static const String assetPath = 'assets/icd/orthopedic_common_icd.json';

  List<IcdCode>? _cache;
  Future<List<IcdCode>>? _loadFuture;

  Future<List<IcdCode>> _loadAll() {
    _loadFuture ??= _loadFromAsset();
    return _loadFuture!;
  }

  Future<List<IcdCode>> _loadFromAsset() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = json.decode(raw);
      if (decoded is! List) {
        _cache = [];
        return _cache!;
      }
      _cache = decoded
          .whereType<Map>()
          .map((e) => IcdCode.fromJson(Map<String, dynamic>.from(e)))
          .where((c) => c.code.isNotEmpty)
          .toList();
    } catch (_) {
      _cache = [];
    }
    return _cache!;
  }

  Future<List<IcdCode>> search(String query, {int limit = 20}) async {
    try {
      final all = await _loadAll();
      final q = query.trim();
      if (q.isEmpty) {
        final common = all.where((c) => c.isCommonOrthopedic).toList();
        if (common.length >= limit) return common.take(limit).toList();
        return all.take(limit).toList();
      }

      final qNorm = normalizeIcdSearchText(q);
      final matched = all.where((c) => c.matches(q)).toList();
      matched.sort((a, b) {
        final aCode = normalizeIcdSearchText(a.code);
        final bCode = normalizeIcdSearchText(b.code);
        final aPrefix = aCode.startsWith(qNorm);
        final bPrefix = bCode.startsWith(qNorm);
        if (aPrefix != bPrefix) return aPrefix ? -1 : 1;
        if (a.isCommonOrthopedic != b.isCommonOrthopedic) {
          return a.isCommonOrthopedic ? -1 : 1;
        }
        return a.code.compareTo(b.code);
      });
      return matched.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  Future<IcdCode?> getByCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    try {
      final all = await _loadAll();
      final norm = normalizeIcdSearchText(trimmed);
      for (final item in all) {
        if (normalizeIcdSearchText(item.code) == norm) return item;
      }
    } catch (_) {}
    return null;
  }
}
