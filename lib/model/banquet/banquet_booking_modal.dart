// booking_model.dart

class BookingModel {
  final String id;
  final String uuid;
  final String couponId;
  final double discount;
  final String restaurantName;
  final int pricePerPerson;
  final String message;
  final DateTime eventDate;
  final DateTime bookingDate;
  final int persons;
  final String status;
  final String? applicableFor;
  final String? offerCode;

  BookingModel({
    this.id = '',
    this.uuid = '',
    required this.couponId,
    required this.restaurantName,
    required this.pricePerPerson,
    required this.discount,
    required this.message,
    required this.eventDate,
    required this.bookingDate,
    required this.persons,
    required this.status,
    this.applicableFor,
    this.offerCode,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final DateTime now = DateTime.now();
    final offer = json['offer'] as Map<String, dynamic>?;

    return BookingModel(
      id: (json['id'] ?? '').toString(),
      uuid: (json['uuid'] ?? '').toString(),
      couponId: (json['reservation_id'] ?? json['offer_code'] ?? json['enquiry_id'] ?? json['coupon_id'] ?? '').toString(),
      restaurantName: (json['restaurant_name'] ?? json['restaurant']?['name'] ?? json['restaurant_id'] ?? '').toString(),
      pricePerPerson: _toInt(json['amount'] ?? json['bill_amount']) ?? 0,
      discount: _toDouble(offer?['discount_percentage'] ?? json['extra_offer']) ?? 0,
      message: (json['comments'] ?? json['message'] ?? json['offer_code_status'] ?? '').toString(),
      eventDate: _parseDateTime(
            date: (json['date'] ?? '').toString(),
            time: (json['time'] ?? '').toString(),
          ) ?? now,
      bookingDate: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? now,
      persons: _toInt(json['people']) ?? 0,
      status: (json['status'] ?? '').toString(),
      applicableFor: offer?['applicable_for']?.toString(),
      offerCode: json['offer_code']?.toString(),
    );
  }
}  // ← class ends here

// ── helpers are OUTSIDE the class ──────────────────────────

int? _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  final String normalized = (value?.toString() ?? '').replaceAll(
    RegExp(r'[^0-9.]'),
    '',
  );
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

DateTime? _parseDateTime({required String date, required String time}) {
  final String trimmedDate = date.trim();
  if (trimmedDate.isEmpty) return null;

  final DateTime? parsedDate = DateTime.tryParse(trimmedDate);
  if (parsedDate == null) return null;

  final String trimmedTime = time.trim();
  final RegExp twelveHour = RegExp(r'^(\d{1,2}):(\d{2})\s*([APap][Mm])$');
  final Match? match = twelveHour.firstMatch(trimmedTime);

  if (match == null) return parsedDate;

  int hour = int.tryParse(match.group(1) ?? '') ?? 0;
  final int minute = int.tryParse(match.group(2) ?? '') ?? 0;
  final String meridiem = (match.group(3) ?? '').toUpperCase();

  if (meridiem == 'PM' && hour < 12) hour += 12;
  if (meridiem == 'AM' && hour == 12) hour = 0;

  return DateTime(
    parsedDate.year,
    parsedDate.month,
    parsedDate.day,
    hour,
    minute,
  );
}