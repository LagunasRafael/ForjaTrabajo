import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NominatimService {
  static const String _userAgent = 'ForjaTrabajoApp/1.0 (contact: juanl.escuela.residencias@gmail.com)';

  /// Performs an HTTP GET call to Nominatim OpenStreetMap API to find matching locations
  static Future<List<Map<String, dynamic>>> searchAddresses(String query) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1&countrycodes=mx'
    );
    
    try {
      final response = await http.get(url, headers: {'User-Agent': _userAgent});
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((item) {
          return {
            'display_name': item['display_name'] ?? '',
            'lat': double.tryParse(item['lat'] ?? '') ?? 0.0,
            'lon': double.tryParse(item['lon'] ?? '') ?? 0.0,
            'address': item['address'] ?? {},
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Error fetching suggestions: $e");
    }
    return [];
  }

  /// Performs reverse geocoding to retrieve a physical street address from latitude/longitude
  static Future<String> reverseGeocode(double lat, double lng) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1'
    );
    
    try {
      final response = await http.get(url, headers: {'User-Agent': _userAgent});
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return formatAddress(data);
      }
    } catch (e) {
      debugPrint("Error reverse geocoding: $e");
    }
    return '';
  }

  /// Helper to format raw Nominatim API responses into natural, short street addresses
  static String formatAddress(Map<String, dynamic> data) {
    final addressObj = data['address'];
    if (addressObj != null) {
      final road = addressObj['road'] ?? addressObj['pedestrian'] ?? addressObj['suburb'] ?? '';
      final houseNumber = addressObj['house_number'] ?? '';
      final neighbourhood = addressObj['neighbourhood'] ?? addressObj['suburb'] ?? '';
      final city = addressObj['city'] ?? addressObj['town'] ?? addressObj['village'] ?? '';
      
      List<String> parts = [];
      if (road.isNotEmpty) {
        if (houseNumber.isNotEmpty) {
          parts.add("$road #$houseNumber");
        } else {
          parts.add(road);
        }
      }
      if (neighbourhood.isNotEmpty) parts.add(neighbourhood);
      if (city.isNotEmpty) parts.add(city);
      
      if (parts.isNotEmpty) {
        return parts.join(", ");
      }
    }
    return data['display_name'] ?? '';
  }
}
