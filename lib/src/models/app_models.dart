import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum AppMode { buyer, seller, admin }

enum SellerEntryType { paket, item }

class Vendor {
  const Vendor({
    required this.id,
    required this.brandId,
    required this.brandName,
    required this.name,
    required this.locationLabel,
    required this.rating,
    required this.reviewCount,
    required this.chatHint,
    required this.description,
    required this.areaGroup,
    required this.position,
    required this.gallery,
    required this.packages,
    required this.foods,
    required this.drinks,
    required this.others,
    this.contactLabel = '0812-3456-7890',
    this.minimumOrderLabel = 'Mulai sewa 1 bulan',
    this.serviceAreaSummary = 'Depok dan sekitarnya',
    this.addressDetail = 'Alamat properti belum diperbarui.',
    this.isOpen = true,
  });

  final String id;
  final String brandId;
  final String brandName;
  final String name;
  final String locationLabel;
  final double rating;
  final int reviewCount;
  final String chatHint;
  final String description;
  final String areaGroup;
  final LatLng position;
  final List<StoreMedia> gallery;
  final List<MenuItemData> packages;
  final List<MenuItemData> foods;
  final List<MenuItemData> drinks;
  final List<MenuItemData> others;
  final String contactLabel;
  final String minimumOrderLabel;
  final String serviceAreaSummary;
  final String addressDetail;
  final bool isOpen;
}

class StoreMedia {
  const StoreMedia({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.imagePath,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final String? imagePath;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'title': title,
      'subtitle': subtitle,
      'imagePath': imagePath,
    };
  }

  factory StoreMedia.fromJson(
    Map<String, dynamic> json, {
    required Color fallbackColor,
    required IconData fallbackIcon,
  }) {
    return StoreMedia(
      title: json['title'] as String? ?? 'Foto Properti',
      subtitle: json['subtitle'] as String? ?? 'Dokumentasi kos',
      color: fallbackColor,
      icon: fallbackIcon,
      imagePath: json['imagePath'] as String?,
    );
  }
}

class MenuItemData {
  const MenuItemData({
    required this.name,
    required this.price,
    required this.description,
    this.components = const <String>[],
  });

  final String name;
  final int price;
  final String description;
  final List<String> components;
}

class SellerMenuEntry {
  const SellerMenuEntry({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.price,
    required this.category,
    required this.type,
    required this.items,
  });

  final String id;
  final String vendorId;
  final String name;
  final int price;
  final String category;
  final SellerEntryType type;
  final List<String> items;

  Map<String, Object> toJson() {
    return <String, Object>{
      'id': id,
      'vendorId': vendorId,
      'name': name,
      'price': price,
      'category': category,
      'type': type.name,
      'items': items,
    };
  }

  factory SellerMenuEntry.fromJson(Map<String, dynamic> json) {
    return SellerMenuEntry(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      vendorId: json['vendorId'] as String? ?? 'vendor-1',
      name: json['name'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      category: json['category'] as String? ?? 'Lainnya',
      type: (json['type'] as String?) == SellerEntryType.item.name
          ? SellerEntryType.item
          : SellerEntryType.paket,
      items: ((json['items'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(),
    );
  }
}
