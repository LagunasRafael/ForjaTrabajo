import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final getDeviceLocationUseCaseProvider = Provider((ref) => GetDeviceLocationUseCase());

class GetDeviceLocationUseCase {
  
  Future<(double, double, String)> execute() async {
    // 1. Verificaciones de rutina (Servicio y Permisos)
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'El GPS está desactivado. Por favor, enciéndelo.';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw 'Permisos de ubicación denegados.';
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Los permisos están denegados permanentemente en ajustes.';
    }

    // 🚀 TRUCO DE LIMPIEZA: Intentamos despertar al sensor con una configuración agresiva
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        // 🛠️ ESTO ES LO QUE EVITA EL REINICIO DEL CELULAR:
        // Fuerza a Android a usar el Manager nativo y no la caché de Google Play Services
        forceAndroidLocationManager: true, 
        // ⏳ Si en 12 segundos no hay respuesta, lanzamos error para no trabar la UI
        timeLimit: const Duration(seconds: 12), 
      );
    } catch (e) {
      // Si falla por timeout, intentamos obtener la última que sepa el celular (Caché rápida)
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        position = lastPosition;
      } else {
        throw 'No se pudo obtener la ubicación. Muévete un poco o revisa tu señal de GPS.';
      }
    }

    // 2. Traducimos las coordenadas a dirección real (Reverse Geocoding)
    String addressText = "";
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      ).timeout(const Duration(seconds: 5)); // También le ponemos tiempo al geocoding

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        addressText = "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}"
            .replaceAll(RegExp(r'^, |, $'), '') 
            .replaceAll(', ,', ',');
      }
    } catch (e) {
      addressText = "Dirección no encontrada automáticamente";
    }

    return (position.latitude, position.longitude, addressText);
  }
}