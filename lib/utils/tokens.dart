import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
}
Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}
Future<void> removeToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');
}
Future<void> saveIsFirstUse(bool token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('first_use', token);
}
Future<bool?> getIsFirstUse() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('first_use');
}
