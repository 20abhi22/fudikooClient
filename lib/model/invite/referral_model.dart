class ReferralModel {
  final String referralLink;

  ReferralModel({required this.referralLink});

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      referralLink: json['referral_link'] ?? '',
    );
  }
}