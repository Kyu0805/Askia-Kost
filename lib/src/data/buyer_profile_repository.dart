import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BuyerProfileData {
  const BuyerProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.primaryAddress,
    required this.secondaryAddress,
    required this.preferenceSummary,
  });

  final String name;
  final String email;
  final String phone;
  final String primaryAddress;
  final String secondaryAddress;
  final String preferenceSummary;

  Map<String, Object> toJson() {
    return <String, Object>{
      'name': name,
      'email': email,
      'phone': phone,
      'primaryAddress': primaryAddress,
      'secondaryAddress': secondaryAddress,
      'preferenceSummary': preferenceSummary,
    };
  }

  factory BuyerProfileData.fromJson(Map<String, dynamic> json) {
    return BuyerProfileData(
      name: json['name'] as String? ?? BuyerProfileRepository.fallback.name,
      email: json['email'] as String? ?? BuyerProfileRepository.fallback.email,
      phone: json['phone'] as String? ?? BuyerProfileRepository.fallback.phone,
      primaryAddress: json['primaryAddress'] as String? ??
          BuyerProfileRepository.fallback.primaryAddress,
      secondaryAddress: json['secondaryAddress'] as String? ?? '',
      preferenceSummary: json['preferenceSummary'] as String? ??
          BuyerProfileRepository.fallback.preferenceSummary,
    );
  }
}

class BuyerProfileRepository {
  const BuyerProfileRepository._();

  static String _buyerId = 'buyer-demo';
  static const String _storageKey = 'buyer_profile_v1';
  static final ValueNotifier<int> updates = ValueNotifier<int>(0);

  static const BuyerProfileData fallback = BuyerProfileData(
    name: 'Halip',
    email: 'halip@askiakost.demo',
    phone: '0812-0000-1234',
    primaryAddress: '-',
    secondaryAddress: '-',
    preferenceSummary: '-',
  );

  static BuyerProfileData? _cache;
  static BuyerProfileData? _sessionOverride;

  static String get buyerId => _buyerId;

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
    _cache = BuyerProfileData.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  static BuyerProfileData current() {
    final BuyerProfileData base = _cache ?? fallback;
    final BuyerProfileData? override = _sessionOverride;
    if (override == null) {
      return base;
    }
    return BuyerProfileData(
      name: override.name,
      email: override.email,
      phone: base.phone,
      primaryAddress: base.primaryAddress,
      secondaryAddress: base.secondaryAddress,
      preferenceSummary: base.preferenceSummary,
    );
  }

  static Future<void> save(BuyerProfileData value) async {
    _cache = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(value.toJson()));
    updates.value++;
  }

  static void configureIdentity({
    required String buyerId,
    required String email,
    String? displayName,
  }) {
    _buyerId = buyerId;
    final BuyerProfileData base = _cache ?? fallback;
    _sessionOverride = BuyerProfileData(
      name: (displayName == null || displayName.trim().isEmpty)
          ? _nameFromEmail(email)
          : displayName.trim(),
      email: email,
      phone: base.phone,
      primaryAddress: base.primaryAddress,
      secondaryAddress: base.secondaryAddress,
      preferenceSummary: base.preferenceSummary,
    );
    updates.value++;
  }

  static void resetToDemoIdentity() {
    _buyerId = 'buyer-demo';
    _sessionOverride = null;
    updates.value++;
  }

  static String _nameFromEmail(String email) {
    final String localPart = email.split('@').first.trim();
    if (localPart.isEmpty) {
      return fallback.name;
    }
    return localPart
        .split(RegExp(r'[._-]+'))
        .where((String part) => part.isNotEmpty)
        .map(
          (String part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
