import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_data.dart';
import '../data/vendor_menu_cloud_repository.dart';
import '../models/app_models.dart';

class SellerMenuController extends ChangeNotifier {
  SellerMenuController._();

  static final SellerMenuController instance = SellerMenuController._();

  static const String _storageKey = 'seller_menu_entries_v1';
  static const String _activeVendorStorageKey = 'seller_active_vendor_v1';
  static const String sellerBrandId = 'brand-askia';
  static const String sellerVendorId = 'vendor-1';

  final List<SellerMenuEntry> _entries = <SellerMenuEntry>[
    const SellerMenuEntry(
      id: 'seed-vendor-1-kamar-standard',
      vendorId: 'vendor-1',
      name: 'Kamar Standard',
      price: 850000,
      category: 'Tipe kamar',
      type: SellerEntryType.paket,
      items: <String>['Kasur', 'Lemari', 'Meja', 'Jendela'],
    ),
    const SellerMenuEntry(
      id: 'seed-vendor-1-wifi',
      vendorId: 'vendor-1',
      name: 'WiFi',
      price: 0,
      category: 'Fasilitas kamar',
      type: SellerEntryType.item,
      items: <String>['WiFi'],
    ),
    const SellerMenuEntry(
      id: 'seed-vendor-1-laundry',
      vendorId: 'vendor-1',
      name: 'Laundry',
      price: 50000,
      category: 'Fasilitas bersama',
      type: SellerEntryType.item,
      items: <String>['Laundry'],
    ),
  ];

  bool _isLoaded = false;
  String _activeVendorId = sellerVendorId;

  bool get isLoaded => _isLoaded;
  String get activeVendorId => _activeVendorId;
  List<String> get ownedVendorIds => sampleVendors
      .where((Vendor vendor) => vendor.brandId == sellerBrandId)
      .map((Vendor vendor) => vendor.id)
      .toList(growable: false);

  List<SellerMenuEntry> get entries => List<SellerMenuEntry>.unmodifiable(_entries);

  List<SellerMenuEntry> entriesForVendor(String vendorId) {
    return _entries.where((SellerMenuEntry entry) => entry.vendorId == vendorId).toList();
  }

  List<Vendor> ownedVendors(Iterable<Vendor> vendors) {
    final List<Vendor> owned = vendors
        .where((Vendor vendor) => vendor.brandId == sellerBrandId)
        .toList(growable: false);
    if (owned.isNotEmpty) {
      return owned;
    }
    return vendors.take(1).toList(growable: false);
  }

  Future<void> ensureLoaded() async {
    if (_isLoaded) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList(_storageKey);
    final String? storedActiveVendorId = prefs.getString(_activeVendorStorageKey);
    _activeVendorId = ownedVendorIds.contains(storedActiveVendorId)
        ? storedActiveVendorId!
        : sellerVendorId;
    if (stored != null && stored.isNotEmpty) {
      _entries
        ..clear()
        ..addAll(
          stored.map(
            (String raw) =>
                SellerMenuEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>),
          ),
        );
    }
    await _hydrateFromCloud();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> addEntry({
    required String vendorId,
    required String name,
    required int price,
    required String category,
    required SellerEntryType type,
    required List<String> items,
  }) async {
    _entries.insert(
      0,
      SellerMenuEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        vendorId: vendorId,
        name: name,
        price: price,
        category: category,
        type: type,
        items: items,
      ),
    );
    await _persist();
    await _upsertEntryToCloud(_entries.first);
    await VendorMenuCloudRepository.upsertVendorMenu(_entries.first);
    notifyListeners();
  }

  Future<void> updateEntry({
    required String id,
    required String vendorId,
    required String name,
    required int price,
    required String category,
    required SellerEntryType type,
    required List<String> items,
  }) async {
    final int index = _entries.indexWhere((SellerMenuEntry entry) => entry.id == id);
    if (index == -1) {
      return;
    }
    _entries[index] = SellerMenuEntry(
      id: id,
      vendorId: vendorId,
      name: name,
      price: price,
      category: category,
      type: type,
      items: items,
    );
    await _persist();
    await _upsertEntryToCloud(_entries[index]);
    await VendorMenuCloudRepository.upsertVendorMenu(_entries[index]);
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    SellerMenuEntry? removedEntry;
    for (final SellerMenuEntry entry in _entries) {
      if (entry.id == id) {
        removedEntry = entry;
        break;
      }
    }
    _entries.removeWhere((SellerMenuEntry entry) => entry.id == id);
    await _persist();
    await _deleteEntryFromCloud(id);
    if (removedEntry != null) {
      await VendorMenuCloudRepository.deleteVendorMenu(
        vendorId: removedEntry.vendorId,
        entryId: removedEntry.id,
      );
    }
    notifyListeners();
  }

  Future<void> setActiveVendor(String vendorId) async {
    if (_activeVendorId == vendorId || !ownedVendorIds.contains(vendorId)) {
      return;
    }
    _activeVendorId = vendorId;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeVendorStorageKey, vendorId);
    notifyListeners();
  }

  Future<void> _persist() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _entries.map((SellerMenuEntry entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  bool get _canUseCloud =>
      Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;

  Future<void> _hydrateFromCloud() async {
    if (!_canUseCloud) {
      return;
    }

    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('sellerMenus')
              .get();
      if (snapshot.docs.isEmpty) {
        return;
      }

      _entries
        ..clear()
        ..addAll(
          snapshot.docs.map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                SellerMenuEntry.fromJson(<String, dynamic>{
                  'id': doc.id,
                  ...doc.data(),
                }),
          ),
        );
      await _persist();
    } catch (_) {}
  }

  Future<void> _upsertEntryToCloud(SellerMenuEntry entry) async {
    if (!_canUseCloud) {
      return;
    }

    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sellerMenus')
          .doc(entry.id)
          .set(entry.toJson());
    } catch (_) {}
  }

  Future<void> _deleteEntryFromCloud(String entryId) async {
    if (!_canUseCloud) {
      return;
    }

    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('sellerMenus')
          .doc(entryId)
          .delete();
    } catch (_) {}
  }
}
