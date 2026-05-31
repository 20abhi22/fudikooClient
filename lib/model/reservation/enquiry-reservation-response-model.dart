import 'package:fudikoclient/model/banquet/banquet_booking_modal.dart';

class EnquiryResponseModel {
  final String id;
  final String uuid;
  final String enquiryId;
  final String amount;
  final String extraOffer;
  final String comments;
  final String status;
  final String restaurantName;
  final String date;
  final String time;
  final DateTime createdAt;

  EnquiryResponseModel({
    required this.id,
    required this.uuid,
    required this.enquiryId,
    required this.amount,
    required this.extraOffer,
    required this.comments,
    required this.status,
    required this.restaurantName,
    required this.date,
    required this.time,
    required this.createdAt,
  });

  factory EnquiryResponseModel.fromJson(Map<String, dynamic> json) {
    return EnquiryResponseModel(
      id: (json['id'] ?? '').toString(),
      uuid: (json['uuid'] ?? '').toString(),
      enquiryId: (json['enquiry_id'] ?? '').toString(),
      amount: (json['amount'] ?? '0').toString(),
      extraOffer: (json['extra_offer'] ?? '0').toString(),
      comments: (json['comments'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      restaurantName: (json['restaurant_name'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      createdAt: DateTime.tryParse(
            (json['created_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }

  /// Convert to BookingModel for reuse in existing UI widgets
  BookingModel toBookingModel() {
    final DateTime now = DateTime.now();
    final DateTime? parsedEvent = _parseDateTime(date: date, time: time);

    return BookingModel(
      id: id,
      uuid: uuid,
      couponId: enquiryId,
      restaurantName: restaurantName,
      pricePerPerson: int.tryParse(amount) ?? 0,
      discount: double.tryParse(extraOffer) ?? 0,
      message: comments,
      eventDate: parsedEvent ?? now,
      bookingDate: createdAt,
      persons: 0,
      status: status,
    );
  }
}

DateTime? _parseDateTime({required String date, required String time}) {
  final String trimmedDate = date.trim();
  if (trimmedDate.isEmpty) return null;

  final DateTime? parsedDate = DateTime.tryParse(trimmedDate);
  if (parsedDate == null) return null;

  final RegExp twelveHour = RegExp(r'^(\d{1,2}):(\d{2})\s*([APap][Mm])$');
  final Match? match = twelveHour.firstMatch(time.trim());
  if (match == null) return parsedDate;

  int hour = int.tryParse(match.group(1) ?? '') ?? 0;
  final int minute = int.tryParse(match.group(2) ?? '') ?? 0;
  final String meridiem = (match.group(3) ?? '').toUpperCase();

  if (meridiem == 'PM' && hour < 12) hour += 12;
  if (meridiem == 'AM' && hour == 12) hour = 0;

  return DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
}