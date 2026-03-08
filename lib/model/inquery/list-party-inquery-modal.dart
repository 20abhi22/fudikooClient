

//for party
class InqueryModel {
  final String uuid;
  final String enquiryId;
  final String userId;
  final String lat;
  final String lng;
  final String menuItems;
  final int people;
  final String date;
  final String time;
  final String estimatedAmount;
  final String searchRadius;
  final String expirationDate;
  final String expirationTime;
  final String status;

  InqueryModel({
    required this.uuid,
    required this.enquiryId,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.menuItems,
    required this.people,
    required this.date,
    required this.time,
    required this.estimatedAmount,
    required this.searchRadius,
    required this.expirationDate,
    required this.expirationTime,
    required this.status,
  });

  factory InqueryModel.fromJson(Map<String, dynamic> json) {
    return InqueryModel(
      uuid: json['uuid'] ?? '',
      enquiryId: json['enquiry_id'] ?? '',
      userId: json['user_id'] ?? '',
      lat: json['lat'] ?? '',
      lng: json['lng'] ?? '',
      menuItems: json['menu_items'] ?? '',
      people: json['people'] is int
          ? json['people']
          : int.tryParse(json['people'].toString()) ?? 0,
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      estimatedAmount: json['estimated_amount'] ?? '',
      searchRadius: json['search_radius'] ?? '',
      expirationDate: json['expiration_date'] ?? '',
      expirationTime: json['expiration_time'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class InqueryListModel {
  final bool status;
  final List<InqueryModel> enquiries;

  InqueryListModel({required this.status, required this.enquiries});

  factory InqueryListModel.fromJson(Map<String, dynamic> json) {
    return InqueryListModel(
      status: json['status'],
      enquiries: (json['enquiries'] as List)
          .map((item) => InqueryModel.fromJson(item))
          .toList(),
    );
  }
}
