import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

class KosRecommendation {
  const KosRecommendation({
    required this.rank,
    required this.kosId,
    required this.name,
    required this.location,
    required this.city,
    required this.monthlyPrice,
    required this.currency,
    required this.roomType,
    required this.facilities,
    required this.cosineSimilarity,
    required this.reasons,
    this.isDemo = false,
  });

  final int rank;
  final String kosId;
  final String name;
  final String location;
  final String city;
  final int monthlyPrice;
  final String currency;
  final String roomType;
  final List<String> facilities;
  final double cosineSimilarity;
  final List<String> reasons;
  final bool isDemo;

  factory KosRecommendation.fromJson(
    Map<String, dynamic> json, {
    bool isDemo = false,
  }) {
    return KosRecommendation(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      kosId: json['kosId'] as String? ?? '',
      name: json['namaKos'] as String? ?? 'Kos',
      location: json['lokasi'] as String? ?? '',
      city: json['kota'] as String? ?? '',
      monthlyPrice: (json['hargaSewa'] as num?)?.toInt() ?? 0,
      currency: json['mataUang'] as String? ?? 'IDR',
      roomType: json['tipeKos'] as String? ?? '',
      facilities: _stringList(json['fasilitas']),
      cosineSimilarity: (json['cosineSimilarity'] as num?)?.toDouble() ?? 0,
      reasons: _stringList(json['reasons']),
      isDemo: isDemo,
    );
  }

  static List<String> _stringList(dynamic value) {
    return (value as List<dynamic>? ?? <dynamic>[])
        .map((dynamic item) => item.toString())
        .toList();
  }
}

/// Preferensi pencarian yang dikirim ke endpoint POST /recommendations.
class KosSearchPreferences {
  const KosSearchPreferences({
    this.kota = KosRecommendationRepository.defaultKota,
    this.kecamatan,
    required this.budgetMin,
    required this.budgetMax,
    this.jenisKos,
    this.fasilitas = const <String>[],
  });

  final String kota;
  final String? kecamatan;
  final int budgetMin;
  final int budgetMax;
  final String? jenisKos;
  final List<String> fasilitas;
}

class KosRecommendationException implements Exception {
  const KosRecommendationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class KosRecommendationRepository {
  const KosRecommendationRepository._();

  /// URL backend FastAPI (TF-IDF + Cosine Similarity).
  /// 10.0.2.2 = alamat komputer host dari sudut pandang emulator Android.
  /// Ganti ke URL production saat backend sudah di-deploy, atau ke IP LAN
  /// komputer kalau testing pakai HP fisik (bukan emulator).
  static const String baseUrl = 'http://10.0.2.2:8000';

  static const List<String> facilityOptions = <String>[
    'wifi',
    'ac',
    'kipas',
    'kasur',
    'lemari',
    'meja',
    'kamar_mandi_dalam',
    'parkir_motor',
    'parkir_mobil',
    'dapur',
    'cctv',
    'keamanan',
    'dekat_transportasi',
  ];

  static const Map<String, String> facilityLabels = <String, String>{
    'wifi': 'WiFi',
    'ac': 'AC',
    'kipas': 'Kipas Angin',
    'kasur': 'Kasur',
    'lemari': 'Lemari',
    'meja': 'Meja',
    'kamar_mandi_dalam': 'Kamar Mandi Dalam',
    'parkir_motor': 'Parkir Motor',
    'parkir_mobil': 'Parkir Mobil',
    'dapur': 'Dapur',
    'cctv': 'CCTV',
    'keamanan': 'Keamanan 24 Jam',
    'dekat_transportasi': 'Dekat Transportasi Umum',
  };

  static const List<String> roomTypeOptions = <String>['Putra', 'Putri', 'Campur'];

  /// Dataset saat ini cuma mencakup kota Depok, jadi kota dikunci di sini
  /// dan tidak perlu diinput manual oleh user.
  static const String defaultKota = 'Depok';

  /// Kecamatan yang tersedia di dataset Depok saat ini.
  static const List<String> kecamatanOptions = <String>[
    'Beji',
    'Cimanggis',
    'Tapos',
    'Pancoran Mas',
    'Sukmajaya',
  ];

  static const String demoProfileId = 'demo-mahasiswa-depok';
  static const List<KosRecommendation> demoRecommendations =
      <KosRecommendation>[
        KosRecommendation(
          rank: 1,
          kosId: 'demo-kos-1',
          name: 'Kos Melati Asri',
          location: 'Beji, Depok',
          city: 'Depok',
          monthlyPrice: 2100000,
          currency: 'IDR',
          roomType: 'Putri',
          facilities: <String>['wifi', 'ac', 'kamar_mandi_dalam', 'parkir_motor'],
          cosineSimilarity: 0.8942,
          reasons: <String>[
            'Cocok dengan fasilitas: WiFi, AC, Kamar Mandi Dalam',
            'Harga Rp2.100.000 sesuai rentang anggaran',
          ],
          isDemo: true,
        ),
        KosRecommendation(
          rank: 2,
          kosId: 'demo-kos-2',
          name: 'Kos Sukmajaya Residence',
          location: 'Sukmajaya, Depok',
          city: 'Depok',
          monthlyPrice: 2450000,
          currency: 'IDR',
          roomType: 'Campur',
          facilities: <String>['wifi', 'ac', 'dekat_transportasi'],
          cosineSimilarity: 0.8417,
          reasons: <String>[
            'Cocok dengan fasilitas: WiFi, AC, Dekat Transportasi Umum',
            'Harga Rp2.450.000 sesuai rentang anggaran',
          ],
          isDemo: true,
        ),
        KosRecommendation(
          rank: 3,
          kosId: 'demo-kos-3',
          name: 'Kos Cimanggis Sejahtera',
          location: 'Cimanggis, Depok',
          city: 'Depok',
          monthlyPrice: 1950000,
          currency: 'IDR',
          roomType: 'Putra',
          facilities: <String>['wifi', 'kasur', 'lemari', 'meja', 'cctv'],
          cosineSimilarity: 0.8025,
          reasons: <String>[
            'Cocok dengan fasilitas: WiFi, Kasur, Lemari',
            'Keamanan CCTV 24 jam',
          ],
          isDemo: true,
        ),
        KosRecommendation(
          rank: 4,
          kosId: 'demo-kos-4',
          name: 'Kos Tapos Hijau',
          location: 'Tapos, Depok',
          city: 'Depok',
          monthlyPrice: 2650000,
          currency: 'IDR',
          roomType: 'Putri',
          facilities: <String>['wifi', 'ac', 'kamar_mandi_dalam', 'dapur', 'keamanan'],
          cosineSimilarity: 0.7791,
          reasons: <String>[
            'Cocok dengan fasilitas: WiFi, AC, Kamar Mandi Dalam',
            'Dekat transportasi umum',
          ],
          isDemo: true,
        ),
        KosRecommendation(
          rank: 5,
          kosId: 'demo-kos-5',
          name: 'Kos Pancoran Mas Asri',
          location: 'Pancoran Mas, Depok',
          city: 'Depok',
          monthlyPrice: 1750000,
          currency: 'IDR',
          roomType: 'Campur',
          facilities: <String>['wifi', 'kipas', 'parkir_motor'],
          cosineSimilarity: 0.7408,
          reasons: <String>[
            'Cocok dengan fasilitas: WiFi, Kipas Angin, Parkir Motor',
            'Harga Rp1.750.000 sesuai rentang anggaran',
          ],
          isDemo: true,
        ),
      ];

  static bool get isReady => Firebase.apps.isNotEmpty;

  /// Rekomendasi awal (fallback) sebelum user mengisi form preferensi.
  static Future<List<KosRecommendation>> fetchForCurrentUser() async {
    if (!isReady) {
      return demoRecommendations;
    }

    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    final List<String> documentIds = <String>[
      if (userId != null) userId,
      demoProfileId,
    ];

    for (final String documentId in documentIds) {
      try {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await FirebaseFirestore.instance
                .collection('recommendations')
                .doc(documentId)
                .get()
                .timeout(const Duration(seconds: 8));
        final Map<String, dynamic>? data = snapshot.data();
        final List<dynamic> items =
            data?['items'] as List<dynamic>? ?? <dynamic>[];
        if (items.isEmpty) {
          continue;
        }

        final List<KosRecommendation> recommendations =
            items
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (Map<dynamic, dynamic> item) => KosRecommendation.fromJson(
                    Map<String, dynamic>.from(item),
                    isDemo: data?['isDummy'] == true,
                  ),
                )
                .toList()
              ..sort(
                (KosRecommendation a, KosRecommendation b) =>
                    a.rank.compareTo(b.rank),
              );
        return recommendations;
      } catch (_) {
        // Try the demo document if a user-specific document is unavailable.
      }
    }
    return demoRecommendations;
  }

  /// Memanggil backend FastAPI: filter kota+budget+jenis kos, lalu
  /// Content-Based Filtering (TF-IDF fasilitas) + Cosine Similarity.
  /// Melempar [KosRecommendationException] jika backend tidak bisa dihubungi.
  static Future<List<KosRecommendation>> searchRecommendations(
    KosSearchPreferences preferences,
  ) async {
    final Uri uri = Uri.parse('$baseUrl/recommendations');
    final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, Object?>{
              'kota': preferences.kota,
              if (preferences.kecamatan != null &&
                  preferences.kecamatan!.isNotEmpty)
                'kecamatan': preferences.kecamatan,
              'budget_min': preferences.budgetMin,
              'budget_max': preferences.budgetMax,
              if (preferences.jenisKos != null &&
                  preferences.jenisKos!.isNotEmpty)
                'jenis_kos': preferences.jenisKos,
              'fasilitas': preferences.fasilitas,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const KosRecommendationException(
        'Server rekomendasi tidak merespons. Pastikan backend aktif di $baseUrl.',
      );
    } catch (_) {
      throw const KosRecommendationException(
        'Tidak bisa terhubung ke server rekomendasi. Pastikan backend berjalan di $baseUrl.',
      );
    }

    if (response.statusCode != 200) {
      String detail = 'Server merespons dengan status ${response.statusCode}.';
      try {
        final Map<String, dynamic> decoded =
            jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['detail'] is String) {
          detail = decoded['detail'] as String;
        }
      } catch (_) {}
      throw KosRecommendationException(detail);
    }

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> results =
        decoded['results'] as List<dynamic>? ?? <dynamic>[];
    return results
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (Map<dynamic, dynamic> item) =>
              KosRecommendation.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}
