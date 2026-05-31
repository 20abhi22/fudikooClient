import 'package:dio/dio.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/auth/mapplace-model.dart';
import 'package:fudikoclient/utils/tokens.dart';

class MapService {
  Future<List<MapPlacesResponse>> listPlaces(
    String place, {
    double? lat,
    double? lng,
  }) async {
    try {
      final token = await getToken();

      String query = '/places/search?input=${Uri.encodeQueryComponent(place)}';
      if (lat != null && lng != null) {
        query += '&location=$lat,$lng&radius=50000';
      }

      final response = await DioClient.dio.get(
        query,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final List<dynamic> predictions = response.data['predictions'];

        return predictions.map<MapPlacesResponse>((place) {
          return MapPlacesResponse.fromJson({
            'place_id': place['place_id'],
            'main_text': place['structured_formatting']['main_text'],
            'secondary_text':
                place['structured_formatting']['secondary_text'] ?? '',
          });
        }).toList();
      } else {
        print("error");
        return [];
      }
    } catch (e) {
      print("function not loaded error");
      return [];
    }
  }

  Future<MapCoordinatesResponse> getPlace(String placeId) async {
    try {
      final token = await getToken();
      final response = await DioClient.dio.get(
        '/places/details?place_id=$placeId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final formateddata = response.data['result']['geometry']['location'];
        return MapCoordinatesResponse.fromJson(formateddata);
      } else {
        print("error");
        return MapCoordinatesResponse(lat: 0.0, lng: 0.0);
      }
    } catch (e) {
      print("function not loaded error");
      return MapCoordinatesResponse(lat: 0.0, lng: 0.0);
    }
  }

  Future<String?> getPlaceName(String lat, String lng) async {
    final String apiKey = "AIzaSyAHuxPvcWL8s0Ye2fGbiDNJ9cTdcSoxvEw";
    final String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey";

    try {
      final response = await Dio().get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data["status"] == "OK" && data["results"].isNotEmpty) {
          return data["results"][0]["formatted_address"];
        }
      }
      return null;
    } catch (e) {
      print("Error fetching place name: $e");
      return null;
    }
  }
}
