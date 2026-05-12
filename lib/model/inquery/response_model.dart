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
  final String time; // display time e.g. "12:30pm"

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
  });

  factory ResponseModel.fromJson(Map<String, dynamic> json) {
    final String parsedEnquiryId = (json['enquiry_id'] ?? '').toString();
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
      date: (json['date'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
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
