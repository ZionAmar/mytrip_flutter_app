import 'dart:convert';
import 'package:http/http.dart' as http;

class Place {
  final String city;
  final String country;

  Place({required this.city, required this.country});

  @override
  String toString() {
    return '$city, $country';
  }
}

class PlacesService {
  final String apiKey;

  PlacesService(this.apiKey);

  Future<List<Place>> searchPlaces(String query) async {
    if (query.isEmpty) {
      return [];
    }

    final uri = Uri.parse(
        'https://api.geoapify.com/v1/geocode/autocomplete?text=$query&type=city&format=json&apiKey=$apiKey');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.map((place) {
        return Place(
          city: place['city'] ?? '',
          country: place['country'] ?? '',
        );
      }).where((place) => place.city.isNotEmpty).toList();
    } else {
      // הדפס את קוד הסטטוס והודעת השגיאה לדיבוג
      print('Failed to load places: Status ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to load places: ${response.statusCode}');
    }
  }
}