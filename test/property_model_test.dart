import 'package:flutter_test/flutter_test.dart';
import 'package:rent_house/Models/property.dart';

void main() {
  group('Property Model Tests', () {
    test('Property.fromJson should create Property from valid JSON', () {
      final json = {
        'id': 'test-id',
        'ownerId': 'owner-id',
        'title': 'Test Property',
        'description': 'A test property',
        'type': 'apartment',
        'city': 'Yaoundé',
        'country': 'Cameroon',
        'price': 50000.0,
        'currency': 'XAF',
        'surface': 50.0,
        'rooms': 2,
        'bathrooms': 1,
        'latitude': 3.8667,
        'longitude': 11.5167,
        'imageUrls': ['https://example.com/image.jpg'],
        'amenities': ['wifi', 'parking'],
        'status': 'published',
        'createdAt': '2023-01-01T00:00:00Z',
        'updatedAt': '2023-01-01T00:00:00Z',
        'isAvailable': true,
        'rating': 4.5,
        'reviewCount': 10,
      };

      final property = Property.fromJson(json);

      expect(property.id, 'test-id');
      expect(property.title, 'Test Property');
      expect(property.price, 50000.0);
      expect(property.city, 'Yaoundé');
      expect(property.imageUrls, ['https://example.com/image.jpg']);
      expect(property.isAvailable, true);
    });

    test('Property.toJson should convert Property to JSON', () {
      final property = Property(
        id: 'test-id',
        ownerId: 'owner-id',
        title: 'Test Property',
        description: 'A test property',
        type: 'apartment',
        city: 'Yaoundé',
        country: 'Cameroon',
        price: 50000.0,
        currency: 'XAF',
        surface: 50.0,
        rooms: 2,
        bathrooms: 1,
        latitude: 3.8667,
        longitude: 11.5167,
        imageUrls: ['https://example.com/image.jpg'],
        amenities: ['wifi', 'parking'],
        status: 'published',
        createdAt: DateTime.parse('2023-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2023-01-01T00:00:00Z'),
        isAvailable: true,
        rating: 4.5,
        reviewCount: 10,
      );

      final json = property.toJson();

      expect(json['id'], 'test-id');
      expect(json['title'], 'Test Property');
      expect(json['price'], 50000.0);
      expect(json['city'], 'Yaoundé');
    });

    test('Property getters should work correctly', () {
      final property = Property(
        id: 'test-id',
        ownerId: 'owner-id',
        title: 'Test Property',
        description: 'A test property',
        type: 'apartment',
        city: 'Yaoundé',
        country: 'Cameroon',
        price: 50000.0,
        currency: 'XAF',
        surface: 50.0,
        rooms: 2,
        bathrooms: 1,
        latitude: 3.8667,
        longitude: 11.5167,
        imageUrls: ['https://example.com/image.jpg'],
        amenities: ['wifi', 'parking'],
        status: 'published',
        createdAt: DateTime.parse('2023-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2023-01-01T00:00:00Z'),
        isAvailable: true,
        rating: 4.5,
        reviewCount: 10,
      );

      expect(property.bedrooms, 2); // rooms alias
      expect(property.imageUrl, 'https://example.com/image.jpg'); // first image
    });
  });
}
