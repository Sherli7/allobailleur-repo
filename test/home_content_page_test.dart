import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rent_house/Screens/guestHomePage.dart';
import 'package:rent_house/Providers/property_provider.dart';
import 'package:rent_house/Models/property.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  testWidgets('HomeContentPage displays shimmer when loading',
      (WidgetTester tester) async {
    // Create a mock PropertyProvider
    final propertyProvider = PropertyProvider();
    propertyProvider.isLoading = true;

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<PropertyProvider>(
          create: (_) => propertyProvider,
          child: const HomeContentPage(),
        ),
      ),
    );

    // Check if shimmer is displayed
    expect(find.byType(Shimmer), findsOneWidget);
  });

  testWidgets('HomeContentPage displays properties when loaded',
      (WidgetTester tester) async {
    final propertyProvider = PropertyProvider();
    propertyProvider.properties = [
      Property(
        id: '1',
        ownerId: 'owner1',
        title: 'Test Property',
        description: 'Description',
        type: 'apartment',
        city: 'Yaounde',
        country: 'Cameroon',
        price: 100.0,
        currency: 'XAF',
        rooms: 2,
        bathrooms: 1,
        rating: 4.5,
        reviewCount: 10,
        imageUrls: ['image1.jpg'],
        amenities: ['wifi'],
        latitude: 3.8667,
        longitude: 11.5167,
        status: 'published',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAvailable: true,
      ),
    ];
    propertyProvider.isLoading = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<PropertyProvider>(
          create: (_) => propertyProvider,
          child: const HomeContentPage(),
        ),
      ),
    );

    // Check if property is displayed
    expect(find.text('Test Property'), findsOneWidget);
  });
}
