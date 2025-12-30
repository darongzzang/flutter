import 'package:shared_preferences/shared_preferences.dart';

class BlePreferences {
  static const String _lastBleDeviceIdKey = 'last_ble_device_id';
  static const String _manualDisconnectKey = 'manual_ble_disconnect';

  static Future<String?> getLastDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastBleDeviceIdKey);
  }

  static Future<void> setLastDeviceId(String remoteId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBleDeviceIdKey, remoteId);
  }

  static Future<bool> getManualDisconnect() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_manualDisconnectKey) ?? false;
  }

  static Future<void> setManualDisconnect(bool didDisconnect) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_manualDisconnectKey, didDisconnect);
  }
}
