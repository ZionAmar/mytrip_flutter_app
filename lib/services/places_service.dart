import 'dart:convert';
import 'package:http/http.dart' as http;

class Place {
  // Original fields
  final String city;
  final String country;

  // --- NEW FIELDS for Geoapify 'formatted' and a specific 'address' if available ---
  final String name; // This will hold the full 'formatted' address string
  final String? fullAddress; // Geoapify often puts the full address in 'formatted'. This can be redundant or hold a more parsed version.

  Place({
    required this.city,
    required this.country,
    required this.name, // Now required
    this.fullAddress, // Optional
  });

  @override
  String toString() {
    return name; // Changed to return the 'name' property
  }

  // Updated fromJson to parse 'formatted' as 'name' and potentially other address components
  factory Place.fromJson(Map<String, dynamic> json) {
    // Geoapify Autocomplete API 'results' structure
    final String formatted = json['formatted'] ?? '';
    final String city = json['city'] ?? '';
    final String country = json['country'] ?? '';
    final String street = json['street'] ?? '';
    final String streetNumber = json['housenumber'] ?? '';

    // Construct a more detailed address if necessary, or just use 'formatted'
    String addressDetails = '';
    if (street.isNotEmpty) {
      addressDetails += street;
      if (streetNumber.isNotEmpty) addressDetails += ' $streetNumber';
    }
    if (city.isNotEmpty) {
      if (addressDetails.isNotEmpty) addressDetails += ', ';
      addressDetails += city;
    }
    if (country.isNotEmpty) {
      if (addressDetails.isNotEmpty) addressDetails += ', ';
      addressDetails += country;
    }

    // If 'formatted' is the best display name, use it.
    // If you want 'name' to be strictly "City, Country" and 'fullAddress' to be 'formatted', you can adjust.
    // For now, I'll make 'name' = 'formatted' as it's the most descriptive string.
    return Place(
      city: city,
      country: country,
      name: formatted, // Using Geoapify's 'formatted' field as the main display 'name'
      fullAddress: formatted, // Geoapify often puts the full address in 'formatted'.
      // You can adjust this to parse more specific address components if needed.
    );
  }
}

class PlacesService {
  final String apiKey;

  PlacesService(this.apiKey);

  Future<List<Place>> searchPlaces(String query) async {
    if (query.isEmpty) {
      return [];
    }

    // Geoapify autocomplete for cities only
    final uri = Uri.parse(
        'https://api.geoapify.com/v1/geocode/autocomplete?text=$query&type=city&format=json&apiKey=$apiKey');

    print('DEBUG: Geoapify API URL: $uri'); // <--- DEBUG
    final response = await http.get(uri);
    print('DEBUG: Geoapify API Status: ${response.statusCode}'); // <--- DEBUG
    print('DEBUG: Geoapify API Body: ${response.body}'); // <--- DEBUG

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results']; // Geoapify uses 'results'
      return results.map((placeJson) { // Renamed parameter to avoid conflict with class name
        return Place.fromJson(placeJson as Map<String, dynamic>); // Use fromJson
      }).where((place) => place.name.isNotEmpty).toList(); // Ensure 'name' is not empty
    } else {
      print('Failed to load places: Status ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to load places: ${response.statusCode}');
    }
  }
}