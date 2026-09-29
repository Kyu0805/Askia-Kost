import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SellerVerificationData {
  const SellerVerificationData({
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    this.storeName = '',
    this.businessAddress = '',
    this.bankAccountName = '',
    this.bankAccountNumber = '',
    this.nik = '',
    this.ktpImagePath = '',
    this.hasSubmittedVerification = false,
  });

  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;
  final String storeName;
  final String businessAddress;
  final String bankAccountName;
  final String bankAccountNumber;
  final String nik;
  final String ktpImagePath;
  final bool hasSubmittedVerification;

  SellerVerificationData copyWith({
    String? ownerName,
    String? ownerEmail,
    String? ownerPhone,
    String? storeName,
    String? businessAddress,
    String? bankAccountName,
    String? bankAccountNumber,
    String? nik,
    String? ktpImagePath,
    bool? hasSubmittedVerification,
  }) {
    return SellerVerificationData(
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      storeName: storeName ?? this.storeName,
      businessAddress: businessAddress ?? this.businessAddress,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      nik: nik ?? this.nik,
      ktpImagePath: ktpImagePath ?? this.ktpImagePath,
      hasSubmittedVerification:
          hasSubmittedVerification ?? this.hasSubmittedVerification,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'ownerPhone': ownerPhone,
      'storeName': storeName,
      'businessAddress': businessAddress,
      'bankAccountName': bankAccountName,
      'bankAccountNumber': bankAccountNumber,
      'nik': nik,
      'ktpImagePath': ktpImagePath,
      'hasSubmittedVerification': hasSubmittedVerification,
    };
  }

  factory SellerVerificationData.fromJson(Map<String, dynamic> json) {
    return SellerVerificationData(
      ownerName: json['ownerName'] as String? ?? '',
      ownerEmail: json['ownerEmail'] as String? ?? '',
      ownerPhone: json['ownerPhone'] as String? ?? '',
      storeName: json['storeName'] as String? ?? '',
      businessAddress: json['businessAddress'] as String? ?? '',
      bankAccountName: json['bankAccountName'] as String? ?? '',
      bankAccountNumber: json['bankAccountNumber'] as String? ?? '',
      nik: json['nik'] as String? ?? '',
      ktpImagePath: json['ktpImagePath'] as String? ?? '',
      hasSubmittedVerification:
          json['hasSubmittedVerification'] as bool? ?? false,
    );
  }
}

class SellerVerificationRepository {
  const SellerVerificationRepository._();

  static const String _storageKey = 'askia_seller_verification_v1';
  static final ValueNotifier<int> updates = ValueNotifier<int>(0);
  static SellerVerificationData? _cache;

  static bool get isReady => Firebase.apps.isNotEmpty;

  static const SellerVerificationData fallback = SellerVerificationData(
    ownerName: 'Penjual Askia',
    ownerEmail: 'seller.demo@askia.app',
    ownerPhone: '0812-3456-7890',
  );

  static Future<void> ensureLoaded() async {
    if (_cache != null) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = fallback;
      return;
    }
    try {
      _cache = SellerVerificationData.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      _cache = fallback;
    }
  }

  static SellerVerificationData current() {
    return _cache ?? fallback;
  }

  static Future<void> saveAccountBasics({
    required String ownerName,
    required String ownerEmail,
    required String ownerPhone,
  }) async {
    await ensureLoaded();
    final SellerVerificationData currentData = current();
    final SellerVerificationData next = currentData.copyWith(
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      ownerPhone: ownerPhone,
    );
    await _save(next);
  }

  static Future<void> saveVerification(SellerVerificationData value) async {
    await ensureLoaded();
    await _save(value.copyWith(hasSubmittedVerification: true));
  }

  static bool get needsVerification => !current().hasSubmittedVerification;

  static Future<void> _save(SellerVerificationData value) async {
    _cache = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(value.toJson()));
    updates.value++;
    await _syncToCloud(value);
  }

  static Future<void> _syncToCloud(SellerVerificationData value) async {
    if (!isReady) {
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('sellerProfiles').doc('primary').set(
        <String, Object?>{
          ...value.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }
}
