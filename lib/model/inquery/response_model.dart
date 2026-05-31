class ResponseModel {
  final int? id;
  final String uuid;
  final String enquiryId;
  final String couponId;
  final String restaurantName;
  final int pricePerPerson;
  final String discount;
  final String message;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String date; // "yyyy-MM-dd" — used for filtering
  final String time;
  final String requestMenuItems;
  final String requestOtherServices;
  final int requestPeople;
  final String requestDate;
  final String requestTime;
  final String requestEstimatedAmount;
  final String requestSearchRadius;
  final String requestLat;
  final String requestLng;

  ResponseModel({
    this.id,
    this.uuid = '',
    this.enquiryId = '',
    required this.couponId,
    required this.restaurantName,
    required this.pricePerPerson,
    required this.discount,
    required this.message,
    this.status = '',
    this.createdAt,
    this.updatedAt,
    required this.date,
    required this.time,
    this.requestMenuItems = '',
    this.requestOtherServices = '',
    this.requestPeople = 0,
    this.requestDate = '',
    this.requestTime = '',
    this.requestEstimatedAmount = '',
    this.requestSearchRadius = '',
    this.requestLat = '',
    this.requestLng = '',
  });

  factory ResponseModel.fromJson(Map<String, dynamic> json) {
    final String parsedEnquiryId = (json['enquiry_id'] ?? '').toString();
    final Map<String, dynamic> requestJson = _requestPayload(json);

    // Use json['date'] if present, otherwise fall back to the date part of created_at
    String resolvedDate = (json['date'] ?? '').toString().trim();
    if (resolvedDate.isEmpty) {
      final String createdAtRaw = (json['created_at'] ?? '').toString();
      if (createdAtRaw.isNotEmpty) {
        // created_at may be "2026-05-22 14:30:00" or ISO "2026-05-22T14:30:00Z"
        resolvedDate = createdAtRaw.split(' ').first.split('T').first;
      }
    }

    return ResponseModel(
      id: _toInt(json['id']),
      uuid: (json['uuid'] ?? '').toString(),
      enquiryId: parsedEnquiryId,
      couponId: parsedEnquiryId,
      restaurantName: (json['restaurant_name'] ?? '').toString(),
      pricePerPerson: _toInt(json['amount']) ?? 0,
      discount: (json['extra_offer'] ?? '').toString(),
      message: (json['comments'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
      date: resolvedDate,
      time: (json['time'] ?? '').toString(),
      requestMenuItems: _stringFromAny(requestJson, const [
        'menu_items',
        'menu',
      ]),
      requestOtherServices: _stringFromAny(requestJson, const [
        'other_services',
        'other_service',
        'services',
      ]),
      requestPeople: _toInt(requestJson['people']) ?? 0,
      requestDate: _stringFromAny(requestJson, const ['date']),
      requestTime: _stringFromAny(requestJson, const ['time']),
      requestEstimatedAmount: _stringFromAny(requestJson, const [
        'estimated_amount',
        'amount',
      ]),
      requestSearchRadius: _stringFromAny(requestJson, const [
        'search_radius',
        'radius',
      ]),
      requestLat: _stringFromAny(requestJson, const ['lat', 'latitude']),
      requestLng: _stringFromAny(requestJson, const ['lng', 'longitude']),
    );
  }
}

class EnquiryResponsesListModel {
  final bool status;
  final String message;
  final List<ResponseModel> responses;

  EnquiryResponsesListModel({
    required this.status,
    required this.message,
    required this.responses,
  });

  factory EnquiryResponsesListModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawResponses = (json['responses'] as List?) ?? [];
    return EnquiryResponsesListModel(
      status: _toBool(json['status']),
      message: (json['message'] ?? '').toString(),
      responses: rawResponses
          .map((item) => ResponseModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  final String normalized = value?.toString().toLowerCase() ?? '';
  return normalized == 'true' || normalized == '1';
}

Map<String, dynamic> _requestPayload(Map<String, dynamic> json) {
  const keys = ['enquiry', 'catering_enquiry', 'cateringEnquiry', 'request'];

  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
  }

  return json;
}

String _stringFromAny(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text != 'null') return text;
  }
  return '';
}
