// booking_model.dart
class BookingModel {
  final String couponId;
  final String restaurantName;
  final int pricePerPerson;
  final double discount;
  final String message;
  final DateTime eventDate;      // April 12 - 2:30 pm
  final DateTime bookingDate;    // Apr 11 - 12:30 pm (used for sorting)
  final int persons;
  final String status; // "Confirmed" or "Rejected"

  BookingModel({
    required this.couponId,
    required this.restaurantName,
    required this.pricePerPerson,
    required this.discount,
    required this.message,
    required this.eventDate,
    required this.bookingDate,
    required this.persons,
    required this.status,
  });
}