class PartnerAdModel {
  final int id;
  final String uuid;
  final String partnerId;
  final String image;
  final String createdAt;
  final String updatedAt;

  PartnerAdModel({
    required this.id,
    required this.uuid,
    required this.partnerId,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PartnerAdModel.fromJson(Map<String, dynamic> json) {
    return PartnerAdModel(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      partnerId: json['partner_id'] ?? '',
      image: json['image'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}