import 'package:flutter_test/flutter_test.dart';
import 'package:rent_house/Services/PropertyService.dart';

void main() {
  late PropertyService propertyService;

  setUp(() {
    propertyService = PropertyService();
  });

  group('PropertyService Basic Tests', () {
    test('PropertyService can be instantiated', () {
      expect(propertyService, isNotNull);
    });
  });
}
