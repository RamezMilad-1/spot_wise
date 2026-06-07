import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spot_wise/models/enums.dart';
import 'package:spot_wise/models/spot.dart';
import 'package:spot_wise/widgets/app_logo.dart';

void main() {
  testWidgets('AppLogo renders the wordmark', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: AppLogo()))),
    );
    expect(find.text('SpotWise'), findsOneWidget);
  });

  test('Spot round-trips through JSON', () {
    final spot = Spot(
      id: 's1',
      name: 'Test Spot',
      description: 'A lovely place',
      country: 'Egypt',
      city: 'Cairo',
      categoryId: 'landmark',
      lat: 30.0,
      lng: 31.0,
      priceRange: PriceRange.budget,
      status: SpotStatus.approved,
      submittedBy: 'u1',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );

    final restored = Spot.fromJson('s1', spot.toJson());

    expect(restored.name, 'Test Spot');
    expect(restored.city, 'Cairo');
    expect(restored.priceRange, PriceRange.budget);
    expect(restored.status, SpotStatus.approved);
    expect(restored.lat, 30.0);
  });
}
