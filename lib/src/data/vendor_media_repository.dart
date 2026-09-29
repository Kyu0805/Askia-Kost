import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

class VendorMediaRepository {
  const VendorMediaRepository._();

  static const String _storageKey = 'vendor_media_gallery_v1';
  static bool _isLoaded = false;
  static final ValueNotifier<int> updates = ValueNotifier<int>(0);
  static final Map<String, List<StoreMedia>> _galleryByVendor =
      <String, List<StoreMedia>>{};

  static Future<void> ensureLoaded() async {
    if (_isLoaded) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((String vendorId, dynamic value) {
        final List<dynamic> entries = value as List<dynamic>? ?? <dynamic>[];
        _galleryByVendor[vendorId] = entries
            .whereType<Map<dynamic, dynamic>>()
            .map(
              (Map<dynamic, dynamic> item) => StoreMedia.fromJson(
                Map<String, dynamic>.from(item),
                fallbackColor: const Color(0xFFD7F3E2),
                fallbackIcon: Icons.storefront_rounded,
              ),
            )
            .toList();
      });
    }
    _isLoaded = true;
  }

  static Future<List<StoreMedia>> galleryForVendor(
    String vendorId,
    List<StoreMedia> fallback,
  ) async {
    await ensureLoaded();
    return _galleryByVendor[vendorId] ?? fallback;
  }

  static List<StoreMedia>? localGallery(String vendorId) {
    return _galleryByVendor[vendorId];
  }

  static Future<void> addMedia({
    required String vendorId,
    required StoreMedia media,
  }) async {
    await ensureLoaded();
    final List<StoreMedia> current = List<StoreMedia>.from(
      _galleryByVendor[vendorId] ?? <StoreMedia>[],
    );
    current.add(media);
    _galleryByVendor[vendorId] = current;
    await _persist();
    await _syncGalleryToCloud(vendorId, current);
    updates.value++;
  }

  static Future<void> removeMedia({
    required String vendorId,
    required int index,
  }) async {
    await ensureLoaded();
    final List<StoreMedia> current = List<StoreMedia>.from(
      _galleryByVendor[vendorId] ?? <StoreMedia>[],
    );
    if (index < 0 || index >= current.length) {
      return;
    }
    current.removeAt(index);
    _galleryByVendor[vendorId] = current;
    await _persist();
    await _syncGalleryToCloud(vendorId, current);
    updates.value++;
  }

  static Future<void> setCover({
    required String vendorId,
    required int index,
  }) async {
    await ensureLoaded();
    final List<StoreMedia> current = List<StoreMedia>.from(
      _galleryByVendor[vendorId] ?? <StoreMedia>[],
    );
    if (index <= 0 || index >= current.length) {
      return;
    }
    final StoreMedia selected = current.removeAt(index);
    current.insert(0, selected);
    _galleryByVendor[vendorId] = current;
    await _persist();
    await _syncGalleryToCloud(vendorId, current);
    updates.value++;
  }

  static Future<void> moveMedia({
    required String vendorId,
    required int fromIndex,
    required int toIndex,
  }) async {
    await ensureLoaded();
    final List<StoreMedia> current = List<StoreMedia>.from(
      _galleryByVendor[vendorId] ?? <StoreMedia>[],
    );
    if (fromIndex < 0 ||
        fromIndex >= current.length ||
        toIndex < 0 ||
        toIndex >= current.length ||
        fromIndex == toIndex) {
      return;
    }
    final StoreMedia moved = current.removeAt(fromIndex);
    current.insert(toIndex, moved);
    _galleryByVendor[vendorId] = current;
    await _persist();
    await _syncGalleryToCloud(vendorId, current);
    updates.value++;
  }

  static Future<void> updateMedia({
    required String vendorId,
    required int index,
    required String title,
    required String subtitle,
  }) async {
    await ensureLoaded();
    final List<StoreMedia> current = List<StoreMedia>.from(
      _galleryByVendor[vendorId] ?? <StoreMedia>[],
    );
    if (index < 0 || index >= current.length) {
      return;
    }
    final StoreMedia previous = current[index];
    current[index] = StoreMedia(
      title: title,
      subtitle: subtitle,
      color: previous.color,
      icon: previous.icon,
      imagePath: previous.imagePath,
    );
    _galleryByVendor[vendorId] = current;
    await _persist();
    await _syncGalleryToCloud(vendorId, current);
    updates.value++;
  }

  static Future<void> _persist() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, Object?> payload = <String, Object?>{
      for (final MapEntry<String, List<StoreMedia>> entry in _galleryByVendor.entries)
        entry.key: entry.value.map((StoreMedia media) => media.toJson()).toList(),
    };
    await prefs.setString(_storageKey, jsonEncode(payload));
  }

  static Future<void> _syncGalleryToCloud(
    String vendorId,
    List<StoreMedia> gallery,
  ) async {
    if (Firebase.apps.isEmpty) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .set(<String, Object?>{
            'gallery': gallery.map((StoreMedia media) => media.toJson()).toList(),
          }, SetOptions(merge: true));
    } catch (_) {}
  }
}
