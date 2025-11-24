import 'package:flutter/foundation.dart';
import 'package:rent_house/Models/booking.dart';
import 'package:rent_house/Services/BookingService.dart';

class BookingProvider with ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<Booking> _userBookings = [];
  List<Booking> _hostBookings = [];
  List<Booking> _propertyBookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Booking> get userBookings => _userBookings;
  List<Booking> get hostBookings => _hostBookings;
  List<Booking> get propertyBookings => _propertyBookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Créer une réservation
  Future<bool> createBooking(Booking booking) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _bookingService.createBooking(booking);

    _isLoading = false;
    if (!result['success']) {
      _errorMessage = result['message'];
    } else {
      _userBookings.add(booking.copyWith(id: result['bookingId']));
    }
    notifyListeners();

    return result['success'];
  }

  /// Charger les réservations de l'utilisateur
  Future<void> loadUserBookings(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bookings = await _bookingService.getUserBookings(userId);
      _userBookings = bookings;
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Erreur: $error';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger les réservations pour l'hôte
  Future<void> loadHostBookings(String hostId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bookings = await _bookingService.getHostBookings(hostId);
      _hostBookings = bookings;
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Erreur: $error';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger les réservations pour une propriété
  Future<void> loadPropertyBookings(String propertyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bookings = await _bookingService.getPropertyBookings(propertyId);
      _propertyBookings = bookings;
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Erreur: $error';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Vérifier la disponibilité
  Future<bool> checkAvailability(
    String propertyId,
    DateTime checkInDate,
    DateTime checkOutDate,
  ) async {
    return await _bookingService.isPropertyAvailable(
      propertyId,
      checkInDate,
      checkOutDate,
    );
  }

  /// Mettre à jour une réservation
  Future<bool> updateBooking(String bookingId, Booking booking) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _bookingService.updateBooking(bookingId, booking);

    _isLoading = false;
    if (!result['success']) {
      _errorMessage = result['message'];
    }
    notifyListeners();

    return result['success'];
  }

  /// Annuler une réservation
  Future<bool> cancelBooking(String bookingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _bookingService.cancelBooking(bookingId);

    _isLoading = false;
    if (!result['success']) {
      _errorMessage = result['message'];
    } else {
      // Mettre à jour localement
      final index = _userBookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _userBookings[index] =
            _userBookings[index].copyWith(status: 'cancelled');
      }
    }
    notifyListeners();

    return result['success'];
  }

  /// Confirmer une réservation
  Future<bool> confirmBooking(String bookingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _bookingService.confirmBooking(bookingId);

    _isLoading = false;
    if (!result['success']) {
      _errorMessage = result['message'];
    } else {
      // Mettre à jour localement
      final index = _hostBookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _hostBookings[index] =
            _hostBookings[index].copyWith(status: 'confirmed');
      }
    }
    notifyListeners();

    return result['success'];
  }

  /// Supprimer une réservation
  Future<bool> deleteBooking(String bookingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _bookingService.deleteBooking(bookingId);

    _isLoading = false;
    if (!result['success']) {
      _errorMessage = result['message'];
    } else {
      _userBookings.removeWhere((b) => b.id == bookingId);
      _hostBookings.removeWhere((b) => b.id == bookingId);
    }
    notifyListeners();

    return result['success'];
  }

  /// Effacer le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
