import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorLocationOverride {
  const VendorLocationOverride({
    required this.locationLabel,
    required this.areaGroup,
    required this.position,
  });

  final String locationLabel;
  final String areaGroup;
  final LatLng position;

  Map<String, Object> toJson() {
    return <String, Object>{
      'locationLabel': locationLabel,
      'areaGroup': areaGroup,
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
  }

  factory VendorLocationOverride.fromJson(Map<String, dynamic> json) {
    return VendorLocationOverride(
      locationLabel: json['locationLabel'] as String? ?? '',
      areaGroup: json['areaGroup'] as String? ?? '',
      position: LatLng(
        (json['latitude'] as num?)?.toDouble() ?? 0,
        (json['longitude'] as num?)?.toDouble() ?? 0,
      ),
    );
  }
}

class VendorLocationRepository {
  const VendorLocationRepository._();

  static const String _storageKey = 'vendor_location_overrides_v1';
  static Map<String, VendorLocationOverride>? _cache;
  static final ValueNotifier<int> updates = ValueNotifier<int>(0);

  static bool get isReady => Firebase.apps.isNotEmpty;

  static Future<void> ensureLoaded() async {
    if (_cache != null) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = <String, VendorLocationOverride>{};
      return;
    }
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>;
    _cache = decoded.map(
      (String key, dynamic value) => MapEntry<String, VendorLocationOverride>(
        key,
        VendorLocationOverride.fromJson(
          Map<String, dynamic>.from(value as Map),
        ),
      ),
    );
  }

  static VendorLocationOverride? localOverride(String vendorId) {
    final Map<String, VendorLocationOverride>? cache = _cache;
    if (cache == null) {
      return null;
    }
    return cache[vendorId];
  }

  static Future<VendorLocationOverride?> overrideFor(String vendorId) async {
    await ensureLoaded();
    return _cache?[vendorId];
  }

  static Future<void> saveOverride({
    required String vendorId,
    required VendorLocationOverride value,
  }) async {
    await ensureLoaded();
    _cache![vendorId] = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(
        _cache!.map(
          (String key, VendorLocationOverride item) =>
              MapEntry<String, Object>(key, item.toJson()),
        ),
      ),
    );

    if (!isReady) {
      updates.value++;
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('vendors').doc(vendorId).set(
        value.toJson(),
        SetOptions(merge: true),
      );
    } catch (_) {}
    updates.value++;
  }
}
