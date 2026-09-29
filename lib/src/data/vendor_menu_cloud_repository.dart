import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_models.dart';

class VendorMenuCloudRepository {
  const VendorMenuCloudRepository._();

  static bool get isReady => Firebase.apps.isNotEmpty;

  static Future<List<SellerMenuEntry>> fetchVendorMenus(String vendorId) async {
    if (!isReady) {
      return const <SellerMenuEntry>[];
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('vendors')
              .doc(vendorId)
              .collection('menus')
              .get();
      return snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                SellerMenuEntry.fromJson(<String, dynamic>{
                  'id': doc.id,
                  ...doc.data(),
                }),
          )
          .toList();
    } catch (_) {
      return const <SellerMenuEntry>[];
    }
  }

  static Future<void> upsertVendorMenu(SellerMenuEntry entry) async {
    if (!isReady) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(entry.vendorId)
          .collection('menus')
          .doc(entry.id)
          .set(entry.toJson());
    } catch (_) {}
  }

  static Future<void> deleteVendorMenu({
    required String vendorId,
    required String entryId,
  }) async {
    if (!isReady) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .collection('menus')
          .doc(entryId)
          .delete();
    } catch (_) {}
  }
}
