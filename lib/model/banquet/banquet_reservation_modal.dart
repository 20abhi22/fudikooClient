import 'package:fudikoclient/model/banquet/banquet_booking_modal.dart';

class BanquetReservationModal {
  final String id;
  final String uuid;
  final String couponId; // reservation_id
  final String restaurantName;
  final int pricePerPerson; // amount
  final double discount; // extra_offer
  final String message; // comments
  final DateTime eventDate; // date + time
  final DateTime bookingDate; // created_at
  final int persons;
  final String status;
  final String? applicableFor;

  BanquetReservationModal({
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
  });

  factory BanquetReservationModal.fromJson(Map<String, dynamic> json) {
    final DateTime now = DateTime.now();
    final offer = json['offer'] is Map<String, dynamic>
        ? json['offer'] as Map<String, dynamic>
        : null;
    final applicableFor =
        (offer?['applicable_for'] ??
                json['applicable_for'] ??
                json['applicableFor'])
            ?.toString()
            .trim();
    return BanquetReservationModal(
      id: (json['id'] ?? '').toString(),
      uuid: (json['uuid'] ?? '').toString(),
      couponId: (json['reservation_id'] ?? json['enquiry_id'] ?? '').toString(),
      restaurantName: (json['restaurant_name'] ?? '').toString(),
      pricePerPerson: _toInt(json['amount']) ?? 0,
      discount:
          _toDouble(offer?['discount_percentage'] ?? json['extra_offer']) ?? 0,
      message: (json['comments'] ?? '').toString(),
      eventDate:
          _parseDateTime(
            date: (json['date'] ?? '').toString(),
            time: (json['time'] ?? '').toString(),
          ) ??
          now,
      bookingDate:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ?? now,
      persons: _toInt(json['people']) ?? 0,
      status: (json['status'] ?? '').toString(),
      applicableFor: applicableFor?.isEmpty == true ? null : applicableFor,
    );
  }

  BookingModel toBookingModel() {
    return BookingModel(
      id: id,
      uuid: uuid,
      couponId: couponId,
      restaurantName: restaurantName,
      pricePerPerson: pricePerPerson,
      discount: discount,
      message: message,
      eventDate: eventDate,
      bookingDate: bookingDate,
      persons: persons,
      status: status,
      applicableFor: applicableFor,
    );
  }
}

class BanquetReservationListResponse {
  final bool status;
  final String message;
  final List<BanquetReservationModal> reservations;

  BanquetReservationListResponse({
    required this.status,
    required this.message,
    required this.reservations,
  });

  factory BanquetReservationListResponse.fromJson(Map<String, dynamic> json) {
    final rawReservations =
        (json['reservations'] as List?) ?? (json['responses'] as List?) ?? [];
    return BanquetReservationListResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString(),
      reservations: rawReservations
          .whereType<Map<String, dynamic>>()
          .map(BanquetReservationModal.fromJson)
          .toList(),
    );
  }
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  final s = (value?.toString() ?? '').replaceAll(RegExp(r'[^0-9.]'), '');
  if (s.isEmpty) return null;
  return int.tryParse(s) ?? double.tryParse(s)?.toInt();
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  final s = (value?.toString() ?? '').replaceAll(RegExp(r'[^0-9.]'), '');
  return s.isEmpty ? null : double.tryParse(s);
}

DateTime? _parseDateTime({required String date, required String time}) {
  final trimmed = date.trim();
  if (trimmed.isEmpty) return null;
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return null;

  final match = RegExp(
    r'^(\d{1,2}):(\d{2})\s*([APap][Mm])$',
  ).firstMatch(time.trim());
  if (match == null) return parsed;

  int hour = int.tryParse(match.group(1) ?? '') ?? 0;
  final int minute = int.tryParse(match.group(2) ?? '') ?? 0;
  final String mer = (match.group(3) ?? '').toUpperCase();

  if (mer == 'PM' && hour < 12) hour += 12;
  if (mer == 'AM' && hour == 12) hour = 0;

  return DateTime(parsed.year, parsed.month, parsed.day, hour, minute);
}
