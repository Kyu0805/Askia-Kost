import 'package:askia_kost_flutter/src/data/kos_recommendation_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses Firestore recommendation item', () {
    final KosRecommendation recommendation = KosRecommendation.fromJson(
      <String, dynamic>{
        'rank': 1,
        'kosId': 'kos-1',
        'namaKos': 'Kos Contoh',
        'lokasi': 'Austin, TX',
        'kota': 'Austin',
        'hargaSewa': 1285,
        'mataUang': 'USD',
        'tipeKos': 'Kamar Standard',
        'fasilitas': <String>['wifi', 'ac'],
        'cosineSimilarity': 0.314126,
        'reasons': <String>['Lokasi sesuai: Austin'],
      },
    );

    expect(recommendation.rank, 1);
    expect(recommendation.name, 'Kos Contoh');
    expect(recommendation.facilities, <String>['wifi', 'ac']);
    expect(recommendation.cosineSimilarity, closeTo(0.314126, 0.000001));
  });

  test('provides five local demo recommendations', () {
    expect(KosRecommendationRepository.demoRecommendations, hasLength(5));
    expect(
      KosRecommendationRepository.demoRecommendations.first.isDemo,
      isTrue,
    );
    expect(
      KosRecommendationRepository.demoRecommendations.first.cosineSimilarity,
      greaterThan(0),
    );
  });
}
