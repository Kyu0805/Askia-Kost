import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SellerNotesRepository {
  const SellerNotesRepository._();

  static const String _storageKey = 'seller_notes_v1';
  static Map<String, List<String>>? _cache;

  static Future<void> ensureLoaded() async {
    if (_cache != null) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = <String, List<String>>{};
      return;
    }
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>;
    _cache = decoded.map(
      (String key, dynamic value) => MapEntry<String, List<String>>(
        key,
        ((value as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic item) => item.toString())
            .toList(),
      ),
    );
  }

  static List<String> notesForVendor(String vendorId) {
    final Map<String, List<String>>? cache = _cache;
    if (cache == null) {
      return <String>[];
    }
    return List<String>.from(cache[vendorId] ?? <String>[]);
  }

  static Future<void> saveNotes(String vendorId, List<String> notes) async {
    await ensureLoaded();
    _cache![vendorId] = List<String>.from(notes);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_cache));
  }
}
