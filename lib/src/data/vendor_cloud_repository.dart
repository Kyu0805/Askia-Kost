import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/app_models.dart';
import 'sample_data.dart';
import 'vendor_location_repository.dart';
import 'vendor_media_repository.dart';
import 'vendor_profile_repository.dart';

class VendorCloudRepository {
  const VendorCloudRepository._();

  static bool get isReady => Firebase.apps.isNotEmpty;

  static Future<List<Vendor>> fetchVendors() async {
    await VendorMediaRepository.ensureLoaded();
    await VendorLocationRepository.ensureLoaded();
    await VendorProfileRepository.ensureLoaded();
    if (!isReady) {
      return sampleVendors
          .map(
            (Vendor vendor) => _applyLocalOverrides(vendor),
          )
          .toList();
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('vendors').get();
      if (snapshot.docs.isEmpty) {
        return sampleVendors;
      }

      final Map<String, Vendor> sampleMap = <String, Vendor>{
        for (final Vendor vendor in sampleVendors) vendor.id: vendor,
      };
      final List<Vendor> merged = <Vendor>[];

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Vendor? baseVendor = sampleMap[doc.id];
        merged.add(_vendorFromDoc(doc.id, doc.data(), baseVendor));
      }

      for (final Vendor vendor in sampleVendors) {
        final bool alreadyIncluded = merged.any(
          (Vendor current) => current.id == vendor.id,
        );
        if (!alreadyIncluded) {
          merged.add(_applyLocalOverrides(vendor));
        }
      }

      return merged;
    } catch (_) {
      return sampleVendors.map(_applyLocalOverrides).toList();
    }
  }

  static Future<void> seedSampleVendors() async {
    if (!isReady) {
      return;
    }

    try {
      final WriteBatch batch = FirebaseFirestore.instance.batch();
      for (final Vendor vendor in sampleVendors) {
        final DocumentReference<Map<String, dynamic>> ref = FirebaseFirestore
            .instance
            .collection('vendors')
            .doc(vendor.id);
        batch.set(ref, _vendorToJson(vendor), SetOptions(merge: true));
      }
      await batch.commit();
    } catch (_) {}
  }

  static Vendor _vendorFromDoc(
    String id,
    Map<String, dynamic> json,
    Vendor? base,
  ) {
    final Vendor fallback = base ?? sampleVendors.first;

    return _applyLocalOverrides(
      Vendor(
        id: id,
        brandId: json['brandId'] as String? ?? fallback.brandId,
        brandName: json['brandName'] as String? ?? fallback.brandName,
        name: json['name'] as String? ?? fallback.name,
        locationLabel: json['locationLabel'] as String? ?? fallback.locationLabel,
        rating: (json['rating'] as num?)?.toDouble() ?? fallback.rating,
        reviewCount: json['reviewCount'] as int? ?? fallback.reviewCount,
        chatHint: json['chatHint'] as String? ?? fallback.chatHint,
        description: json['description'] as String? ?? fallback.description,
        areaGroup: json['areaGroup'] as String? ?? fallback.areaGroup,
        position: LatLng(
          (json['latitude'] as num?)?.toDouble() ?? fallback.position.latitude,
          (json['longitude'] as num?)?.toDouble() ?? fallback.position.longitude,
        ),
        gallery: _applyLocalGallery(
          id,
          _galleryFromJson(json['gallery'], fallback.gallery),
        ),
        packages: _menuListFromJson(json['packages'], fallback.packages),
        foods: _menuListFromJson(json['foods'], fallback.foods),
        drinks: _menuListFromJson(json['drinks'], fallback.drinks),
        others: _menuListFromJson(json['others'], fallback.others),
        contactLabel:
            json['contactLabel'] as String? ?? fallback.contactLabel,
        minimumOrderLabel:
            json['minimumOrderLabel'] as String? ?? fallback.minimumOrderLabel,
        serviceAreaSummary:
            json['serviceAreaSummary'] as String? ?? fallback.serviceAreaSummary,
        addressDetail:
            json['addressDetail'] as String? ?? fallback.addressDetail,
        isOpen: json['isOpen'] as bool? ?? fallback.isOpen,
      ),
    );
  }

  static Map<String, Object> _vendorToJson(Vendor vendor) {
    return <String, Object>{
      'name': vendor.name,
      'brandId': vendor.brandId,
      'brandName': vendor.brandName,
      'locationLabel': vendor.locationLabel,
      'rating': vendor.rating,
      'reviewCount': vendor.reviewCount,
      'chatHint': vendor.chatHint,
      'description': vendor.description,
      'areaGroup': vendor.areaGroup,
      'latitude': vendor.position.latitude,
      'longitude': vendor.position.longitude,
      'gallery': vendor.gallery.map(_storeMediaToJson).toList(),
      'packages': vendor.packages.map(_menuItemToJson).toList(),
      'foods': vendor.foods.map(_menuItemToJson).toList(),
      'drinks': vendor.drinks.map(_menuItemToJson).toList(),
      'others': vendor.others.map(_menuItemToJson).toList(),
      'contactLabel': vendor.contactLabel,
      'minimumOrderLabel': vendor.minimumOrderLabel,
      'serviceAreaSummary': vendor.serviceAreaSummary,
      'addressDetail': vendor.addressDetail,
      'isOpen': vendor.isOpen,
    };
  }

  static List<MenuItemData> _menuListFromJson(
    dynamic raw,
    List<MenuItemData> fallback,
  ) {
    final List<dynamic>? entries = raw as List<dynamic>?;
    if (entries == null || entries.isEmpty) {
      return fallback;
    }

    return entries
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (Map<dynamic, dynamic> item) => MenuItemData(
            name: item['name'] as String? ?? '',
            price: item['price'] as int? ?? 0,
            description: item['description'] as String? ?? '',
            components: ((item['components'] as List<dynamic>?) ?? <dynamic>[])
                .map((dynamic component) => component.toString())
                .toList(),
          ),
        )
        .toList();
  }

  static List<StoreMedia> _galleryFromJson(
    dynamic raw,
    List<StoreMedia> fallback,
  ) {
    final List<dynamic>? entries = raw as List<dynamic>?;
    if (entries == null || entries.isEmpty) {
      return fallback;
    }

    return entries.map((dynamic item) {
      final Map<dynamic, dynamic> media =
          item as Map<dynamic, dynamic>? ?? <dynamic, dynamic>{};
      return StoreMedia.fromJson(
        Map<String, dynamic>.from(media),
        fallbackColor:
            fallback.isNotEmpty ? fallback.first.color : const Color(0xFFD7F3E2),
        fallbackIcon:
            fallback.isNotEmpty ? fallback.first.icon : Icons.storefront_rounded,
      );
    }).toList();
  }

  static Map<String, Object> _storeMediaToJson(StoreMedia media) {
    return <String, Object>{
      'title': media.title,
      'subtitle': media.subtitle,
      if (media.imagePath != null) 'imagePath': media.imagePath!,
    };
  }

  static Map<String, Object> _menuItemToJson(MenuItemData item) {
    return <String, Object>{
      'name': item.name,
      'price': item.price,
      'description': item.description,
      'components': item.components,
    };
  }

  static List<StoreMedia> _applyLocalGallery(
    String vendorId,
    List<StoreMedia> fallback,
  ) {
    final List<StoreMedia>? local = VendorMediaRepository.localGallery(vendorId);
    return (local != null && local.isNotEmpty) ? local : fallback;
  }

  static Vendor _applyLocalOverrides(Vendor vendor) {
    final VendorLocationOverride? locationOverride =
        VendorLocationRepository.localOverride(vendor.id);
    final VendorProfileOverride? profileOverride =
        VendorProfileRepository.localOverride(vendor.id);
    return Vendor(
      id: vendor.id,
      brandId: vendor.brandId,
      brandName: vendor.brandName,
      name: profileOverride?.name.isNotEmpty == true
          ? profileOverride!.name
          : vendor.name,
      locationLabel: locationOverride?.locationLabel ?? vendor.locationLabel,
      rating: vendor.rating,
      reviewCount: vendor.reviewCount,
      chatHint: vendor.chatHint,
      description: profileOverride?.description.isNotEmpty == true
          ? profileOverride!.description
          : vendor.description,
      areaGroup: locationOverride?.areaGroup ?? vendor.areaGroup,
      position: locationOverride?.position ?? vendor.position,
      gallery: _applyLocalGallery(vendor.id, vendor.gallery),
      packages: vendor.packages,
      foods: vendor.foods,
      drinks: vendor.drinks,
      others: vendor.others,
      contactLabel:
          profileOverride?.contactLabel.isNotEmpty == true
              ? profileOverride!.contactLabel
              : vendor.contactLabel,
      minimumOrderLabel:
          profileOverride?.minimumOrderLabel.isNotEmpty == true
              ? profileOverride!.minimumOrderLabel
              : vendor.minimumOrderLabel,
      serviceAreaSummary:
          profileOverride?.serviceAreaSummary.isNotEmpty == true
              ? profileOverride!.serviceAreaSummary
              : vendor.serviceAreaSummary,
      addressDetail: profileOverride?.addressDetail.isNotEmpty == true
          ? profileOverride!.addressDetail
          : vendor.addressDetail,
      isOpen: profileOverride?.isOpen ?? vendor.isOpen,
    );
  }
}
