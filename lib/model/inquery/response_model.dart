class ResponseModel {
  final String couponId;
  final String restaurantName;
  final int pricePerPerson;
  final String discount;
  final String message;
  final String date;   // "yyyy-MM-dd" — used for filtering
  final String time;   // display time e.g. "12:30pm"

  ResponseModel({
    required this.couponId,
    required this.restaurantName,
    required this.pricePerPerson,
    required this.discount,
    required this.message,
    required this.date,
    required this.time,
  });
}