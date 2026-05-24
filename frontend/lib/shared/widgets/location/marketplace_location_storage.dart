import 'package:shared_preferences/shared_preferences.dart';

class MarketplaceLocationStorage {
  MarketplaceLocationStorage._();

  static const _latitudeKey = 'marketplace_latitude';
  static const _longitudeKey = 'marketplace_longitude';
  static const _labelKey = 'marketplace_location_label';
  static const _radiusKey = 'marketplace_radius_km';
  static const _filterEnabledKey = 'marketplace_use_location_filter';

  static Future<void> saveLocation({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latitudeKey, latitude);
    await prefs.setDouble(_longitudeKey, longitude);
    await prefs.setString(_labelKey, label);
  }

  static Future<void> saveRadius(double km) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_radiusKey, km);
  }

  static Future<void> saveFilterEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_filterEnabledKey, enabled);
  }

  static Future<void> clearLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_latitudeKey);
    await prefs.remove(_longitudeKey);
    await prefs.remove(_labelKey);
  }

  static Future<({double? latitude, double? longitude, String? label, double radius, bool filterEnabled})> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      latitude: prefs.getDouble(_latitudeKey),
      longitude: prefs.getDouble(_longitudeKey),
      label: prefs.getString(_labelKey),
      radius: prefs.getDouble(_radiusKey) ?? 25.0,
      filterEnabled: prefs.getBool(_filterEnabledKey) ?? true,
    );
  }
}
