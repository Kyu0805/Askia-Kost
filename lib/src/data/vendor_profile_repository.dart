import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorProfileOverride {
  const VendorProfileOverride({
    required this.name,
    required this.description,
    required this.contactLabel,
    required this.minimumOrderLabel,
    required this.serviceAreaSummary,
    required this.addressDetail,
    required this.isOpen,
  });

  final String name;
  final String description;
  final String contactLabel;
  final String minimumOrderLabel;
  final String serviceAreaSummary;
  final String addressDetail;
  final bool isOpen;

  Map<String, Object> toJson() {
    return <String, Object>{
      'name': name,
      'description': description,
      'contactLabel': contactLabel,
      'minimumOrderLabel': minimumOrderLabel,
      'serviceAreaSummary': serviceAreaSummary,
      'addressDetail': addressDetail,
      'isOpen': isOpen,
    };
  }

  factory VendorProfileOverride.fromJson(Map<String, dynamic> json) {
    return VendorProfileOverride(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      contactLabel: json['contactLabel'] as String? ?? '',
      minimumOrderLabel: json['minimumOrderLabel'] as String? ?? '',
      serviceAreaSummary: json['serviceAreaSummary'] as String? ?? '',
      addressDetail: json['addressDetail'] as String? ?? '',
      isOpen: json['isOpen'] as bool? ?? true,
    );
  }
}

class VendorProfileRepository {
  const VendorProfileRepository._();

  static const String _storageKey = 'vendor_profile_overrides_v1';
  static Map<String, VendorProfileOverride>? _cache;
  static final ValueNotifier<int> updates = ValueNotifier<int>(0);

  static bool get isReady => Firebase.apps.isNotEmpty;

  static Future<void> ensureLoaded() async {
    if (_cache != null) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = <String, VendorProfileOverride>{};
      return;
    }
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>;
    _cache = decoded.map(
      (String key, dynamic value) => MapEntry<String, VendorProfileOverride>(
        key,
        VendorProfileOverride.fromJson(
          Map<String, dynamic>.from(value as Map),
        ),
      ),
    );
  }

  static VendorProfileOverride? localOverride(String vendorId) {
    final Map<String, VendorProfileOverride>? cache = _cache;
    if (cache == null) {
      return null;
    }
    return cache[vendorId];
  }

  static Future<void> saveOverride({
    required String vendorId,
    required VendorProfileOverride value,
  }) async {
    await ensureLoaded();
    _cache![vendorId] = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(
        _cache!.map(
          (String key, VendorProfileOverride item) =>
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
