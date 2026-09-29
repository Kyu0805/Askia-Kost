import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../data/buyer_profile_repository.dart';
import '../data/seller_verification_repository.dart';
import '../data/vendor_cloud_repository.dart';
import '../models/app_models.dart';

class AppSessionController extends ChangeNotifier {
  AppMode? _activeMode;
  String? _activeEmail;
  bool _isBusy = false;
  bool _firebaseReady = false;
  String _authStatus =
      'Mode demo aktif. Tambahkan konfigurasi Firebase supaya login online bisa dipakai.';
  String? _lastProfileSyncError;

  AppMode? get activeMode => _activeMode;
  String? get activeEmail => _activeEmail;
  bool get isBusy => _isBusy;
  bool get firebaseReady => _firebaseReady;
  String get authStatus => _authStatus;
  String? get lastProfileSyncError => _lastProfileSyncError;

  bool get isAuthenticated => _activeMode != null;

  Future<void> initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _firebaseReady = true;
      _authStatus = 'Firebase aktif. Login akan tersimpan ke Auth dan Firestore.';
      await VendorCloudRepository.seedSampleVendors();
    } catch (error, stackTrace) {
      debugPrint('Askia Firebase init error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _firebaseReady = false;
      _authStatus =
          'Mode demo aktif. Firebase belum siap: $error';
    }
    notifyListeners();
  }

  Future<void> loginAs({
    required AppMode mode,
    required String email,
    required String password,
  }) async {
    _isBusy = true;
    notifyListeners();

    final String normalizedEmail = email.trim().isEmpty
        ? (mode == AppMode.buyer
              ? 'buyer.demo@askia.app'
              : mode == AppMode.seller
              ? 'seller.demo@askia.app'
              : 'admin.demo@askia.app')
        : email.trim();
    final String normalizedPassword =
        password.isEmpty ? 'askia12345' : password;

    _lastProfileSyncError = null;

    try {
      if (!_firebaseReady) {
        // Firebase belum aktif sama sekali (mis. offline) — mode demo lokal
        // murni, sengaja tidak divalidasi ke server karena memang tidak ada
        // server yang bisa dihubungi.
        if (mode == AppMode.buyer) {
          BuyerProfileRepository.configureIdentity(
            buyerId: normalizedEmail,
            email: normalizedEmail,
          );
        }
        _activeMode = mode;
        _activeEmail = normalizedEmail;
        _authStatus =
            'Mode demo aktif (Firebase belum siap). Login tidak divalidasi ke server.';
        return;
      }

      final FirebaseAuth auth = FirebaseAuth.instance;
      final UserCredential credential;
      try {
        credential = await auth
            .signInWithEmailAndPassword(
              email: normalizedEmail,
              password: normalizedPassword,
            )
            .timeout(const Duration(seconds: 25));
      } on FirebaseAuthException catch (error) {
        // Login gagal: JANGAN anggap berhasil dan JANGAN diam-diam bikin
        // akun baru di sini — itu tugas registerAccount(), bukan loginAs().
        debugPrint('Askia Firebase login error: ${error.code}');
        _authStatus = _friendlyAuthError(error);
        return;
      }

      if (mode == AppMode.buyer) {
        BuyerProfileRepository.configureIdentity(
          buyerId: credential.user?.uid ?? normalizedEmail,
          email: normalizedEmail,
          displayName: credential.user?.displayName,
        );
      }

      _activeMode = mode;
      _activeEmail = normalizedEmail;
      _isBusy = false;
      notifyListeners();

      try {
        await _syncFirebaseSessionData(
          mode: mode,
          email: normalizedEmail,
          userId: credential.user?.uid ?? normalizedEmail,
        );
        _authStatus = 'Login Firebase aktif untuk $normalizedEmail.';
      } catch (error) {
        _lastProfileSyncError =
            'Login berhasil, tapi profil belum tersimpan ke Firestore: $error';
        _authStatus = _lastProfileSyncError!;
      }
      notifyListeners();
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('Askia Firebase login timeout: $error');
      debugPrintStack(stackTrace: stackTrace);
      _authStatus =
          'Firebase aktif, tapi login di emulator masih timeout. Coba ulang, cek internet emulator, atau pakai emulator Google Play.';
    } catch (error, stackTrace) {
      debugPrint('Askia Firebase login error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _authStatus = _friendlyAuthError(error);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> registerAccount({
    required AppMode mode,
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isBusy = true;
    notifyListeners();

    final String normalizedName = name.trim();
    final String normalizedEmail = email.trim();
    final String normalizedPhone = phone.trim();
    final String normalizedPassword =
        password.trim().isEmpty ? 'askia12345' : password.trim();

    _lastProfileSyncError = null;

    try {
      if (mode == AppMode.buyer) {
        BuyerProfileRepository.configureIdentity(
          buyerId: normalizedEmail,
          email: normalizedEmail,
          displayName: normalizedName,
        );
        // Akun baru harus mulai dari data kosong ("-"), bukan mewarisi
        // alamat/preferensi dari akun buyer lain yang pernah tersimpan di
        // perangkat ini.
        await BuyerProfileRepository.save(
          BuyerProfileData(
            name: normalizedName,
            email: normalizedEmail,
            phone: normalizedPhone,
            primaryAddress: '-',
            secondaryAddress: '-',
            preferenceSummary: '-',
          ),
        );
      } else if (mode == AppMode.seller) {
        await SellerVerificationRepository.saveAccountBasics(
          ownerName: normalizedName,
          ownerEmail: normalizedEmail,
          ownerPhone: normalizedPhone,
        );
      }

      if (_firebaseReady) {
        final FirebaseAuth auth = FirebaseAuth.instance;
        UserCredential credential;
        try {
          credential = await auth
              .createUserWithEmailAndPassword(
                email: normalizedEmail,
                password: normalizedPassword,
              )
              .timeout(const Duration(seconds: 25));
        } on FirebaseAuthException catch (error) {
          if (error.code == 'email-already-in-use') {
            credential = await auth
                .signInWithEmailAndPassword(
                  email: normalizedEmail,
                  password: normalizedPassword,
                )
                .timeout(const Duration(seconds: 25));
          } else {
            rethrow;
          }
        }

        if (credential.user != null && normalizedName.isNotEmpty) {
          await credential.user!.updateDisplayName(normalizedName);
        }

        if (mode == AppMode.buyer) {
          BuyerProfileRepository.configureIdentity(
            buyerId: credential.user?.uid ?? normalizedEmail,
            email: normalizedEmail,
            displayName: normalizedName,
          );
        }

        _activeMode = mode;
        _activeEmail = normalizedEmail;
        _isBusy = false;
        notifyListeners();

        try {
          await _syncFirebaseSessionData(
            mode: mode,
            email: normalizedEmail,
            userId: credential.user?.uid ?? normalizedEmail,
            displayName: normalizedName,
            phone: normalizedPhone,
          );
          _authStatus = 'Akun ${mode.name} berhasil dibuat untuk $normalizedEmail.';
        } catch (error) {
          _lastProfileSyncError =
              'Akun berhasil dibuat, tapi profil belum tersimpan ke Firestore: $error';
          _authStatus = _lastProfileSyncError!;
        }
        notifyListeners();
        return;
      }

      _activeMode = mode;
      _activeEmail = normalizedEmail;
      _authStatus =
          'Akun ${mode.name} tersimpan di mode lokal. Firebase akan dipakai saat sudah aktif penuh.';
    } catch (error, stackTrace) {
      debugPrint('Askia Firebase register error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _authStatus = _friendlyAuthError(error);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  String _friendlyAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Email ini sudah terdaftar. Coba masuk (bukan daftar) dengan password akun tersebut.';
        case 'invalid-credential':
        case 'wrong-password':
          return 'Email atau password salah, atau akun belum terdaftar. Periksa lagi atau daftar akun baru.';
        case 'user-not-found':
          return 'Akun dengan email ini belum terdaftar. Coba daftar akun baru dulu.';
        case 'weak-password':
          return 'Password terlalu lemah, gunakan minimal 6 karakter.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'network-request-failed':
          return 'Gagal terhubung ke internet. Cek koneksi lalu coba lagi.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
        default:
          return 'Terjadi kesalahan (${error.code}). Coba lagi.';
      }
    }
    return 'Terjadi kesalahan tak terduga. Coba lagi.';
  }

  void switchMode(AppMode mode) {
    _activeMode = mode;
    notifyListeners();
  }

  Future<void> logout() async {
    if (_firebaseReady && Firebase.apps.isNotEmpty) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    BuyerProfileRepository.resetToDemoIdentity();
    _activeMode = null;
    _activeEmail = null;
    notifyListeners();
  }

  Future<void> _syncFirebaseSessionData({
    required AppMode mode,
    required String email,
    required String userId,
    String? displayName,
    String? phone,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(<String, Object?>{
            'email': email,
            'mode': mode.name,
            'displayName': displayName,
            'phone': phone,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 25));
      await VendorCloudRepository.seedSampleVendors().timeout(
        const Duration(seconds: 25),
      );
    } catch (error, stackTrace) {
      debugPrint('Askia Firebase session sync error: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
