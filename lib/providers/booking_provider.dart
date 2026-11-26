import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/booking_model.dart';

class BookingProvider extends ChangeNotifier {
  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String _error = '';

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> loadCustomerBookings(int customerId) async {
    _isLoading = true;
    notifyListeners();
    final data = await DatabaseHelper.instance.getBookingsByCustomer(customerId);
    _bookings = data.map((e) => BookingModel.fromMap(e)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadProviderBookings(int providerId) async {
    _isLoading = true;
    notifyListeners();
    final data = await DatabaseHelper.instance.getBookingsByProvider(providerId);
    _bookings = data.map((e) => BookingModel.fromMap(e)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllBookings() async {
    _isLoading = true;
    notifyListeners();
    final data = await DatabaseHelper.instance.getAllBookings();
    _bookings = data.map((e) => BookingModel.fromMap(e)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createBooking({
    required int customerId,
    required int providerId,
    required int categoryId,
    required String serviceDescription,
    required String address,
    required String scheduledDate,
    String? notes,
  }) async {
    _error = '';
    final now = DateTime.now().toIso8601String();
    final booking = BookingModel(
      customerId: customerId,
      providerId: providerId,
      categoryId: categoryId,
      serviceDescription: serviceDescription,
      address: address,
      scheduledDate: scheduledDate,
      status: 'pending',
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    final id = await DatabaseHelper.instance.createBooking(booking.toMap());
    if (id > 0) {
      await loadCustomerBookings(customerId);
      return true;
    }
    _error = 'Failed to create booking';
    notifyListeners();
    return false;
  }

  Future<void> updateStatus(int bookingId, String status, {int? customerId, int? providerId}) async {
    await DatabaseHelper.instance.updateBookingStatus(bookingId, status);
    if (customerId != null) {
      await loadCustomerBookings(customerId);
    } else if (providerId != null) {
      await loadProviderBookings(providerId);
    } else {
      await loadAllBookings();
    }
  }
}

