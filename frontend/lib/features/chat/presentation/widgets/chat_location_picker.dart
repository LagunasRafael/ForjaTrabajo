import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ChatLocationPicker {
  static Future<String> pickAndEncodeLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El GPS está desactivado. Por favor, enciéndelo.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permisos de ubicación denegados.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Los permisos están denegados permanentemente en ajustes.');
    }

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
        timeLimit: const Duration(seconds: 12),
      );
    } catch (_) {
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        position = lastPosition;
      } else {
        throw Exception('No se pudo obtener la ubicación. Revisa tu señal GPS.');
      }
    }

    String addressText = "";
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        addressText =
            "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}"
                .replaceAll(RegExp(r'^, |, $'), '')
                .replaceAll(', ,', ',');
      }
    } catch (_) {
      addressText = "";
    }

    final data = {
      'lat': position.latitude,
      'lng': position.longitude,
      'address': addressText,
    };
    return jsonEncode(data);
  }
}
