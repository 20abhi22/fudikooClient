class SupportInformationModel {
  final bool status;
  final String contactEmail;
  final String chatLink;
  final String contactUsPhone;

  SupportInformationModel({
    required this.status,
    required this.contactEmail,
    required this.chatLink,
    required this.contactUsPhone,
  });

  factory SupportInformationModel.fromJson(Map<String, dynamic> json) {
    return SupportInformationModel(
      status: json['status'] ?? false,
      contactEmail: json['contact_email'] ?? '',
      chatLink: json['chat_link'] ?? '',
      contactUsPhone: json['contact_us_phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'contact_email': contactEmail,
      'chat_link': chatLink,
      'contact_us_phone': contactUsPhone,
    };
  }
}