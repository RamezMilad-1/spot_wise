import 'package:flutter_test/flutter_test.dart';
import 'package:spot_wise/models/enums.dart';
import 'package:spot_wise/models/spot.dart';
import 'package:spot_wise/widgets/spot_search_sheet.dart';

Spot _spot(String id, String name, {double rating = 4.5, List<String> tags = const []}) => Spot(
      id: id,
      name: name,
      description: 'desc',
      country: 'Egypt',
      city: 'Cairo',
      categoryId: 'landmark',
      lat: 30,
      lng: 31,
      rating: rating,
      tags: tags,
      status: SpotStatus.approved,
      submittedBy: 'u1',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  final catalog = [
    _spot('s1', 'Pyramids of Giza', rating: 4.9),
    _spot('s2', 'Eiffel Tower', rating: 4.8),
    _spot('s3', 'Tower Bridge', rating: 4.7),
    _spot('s4', 'The Egyptian Museum'),
    _spot('s5', 'Khan el-Khalili', tags: ['Market']),
    _spot('s6', 'Borough Market'),
    _spot('s7', 'Camden Market'),
    _spot('s8', 'Mercat de la Boqueria', tags: ['Market']),
    _spot('s9', 'Markthalle Neun', tags: ['Market', 'Food']),
    _spot('s10', 'Marienplatz & Glockenspiel'),
  ];

  group('searchSpots', () {
    test('partial name prefix finds the spot first ("pyram")', () {
      final results = searchSpots(catalog, 'pyram');
      expect(results, isNotEmpty);
      expect(results.first.name, 'Pyramids of Giza');
    });

    test('typo-tolerant: "tour" still finds the towers', () {
      final names = searchSpots(catalog, 'tour').map((s) => s.name).toList();
      expect(names, contains('Eiffel Tower'));
      expect(names, contains('Tower Bridge'));
    });

    test('matches inside the name ("bridge")', () {
      final results = searchSpots(catalog, 'bridge');
      expect(results.first.name, 'Tower Bridge');
    });

    test('matches tags too ("market") and caps results at 5', () {
      final results = searchSpots(catalog, 'market');
      expect(results.length, 5);
    });

    test('empty and unmatched queries return nothing', () {
      expect(searchSpots(catalog, '  '), isEmpty);
      expect(searchSpots(catalog, 'zzzzzzz'), isEmpty);
    });
  });
}
