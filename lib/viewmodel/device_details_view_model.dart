import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../services/ble_preferences.dart';

class DeviceDetailsViewModel extends ChangeNotifier {
  DeviceDetailsViewModel(this.device);

  final BluetoothDevice device;

  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  bool isConnected = true;
  bool isLoadingServices = false;
  bool isConnecting = false;
  String? connectErrorMessage;
  List<BluetoothService> services = [];

  Future<void> initialize() async {
    _connectionSubscription = device.connectionState.listen((state) {
      isConnected = state == BluetoothConnectionState.connected;
      notifyListeners();
      if (state == BluetoothConnectionState.disconnected) {
        debugPrint('Device disconnected, waiting for reconnection...');
      }
    });

    await ensureConnectedAndDiscover();
  }

  Future<void> _saveLastDeviceId() async {
    await BlePreferences.setManualDisconnect(false);
    await BlePreferences.setLastDeviceId(device.remoteId.str);
  }

  Future<bool> _waitForConnected() async {
    try {
      await device.connectionState
          .where((state) => state == BluetoothConnectionState.connected)
          .first
          .timeout(const Duration(seconds: 10));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> ensureConnectedAndDiscover() async {
    if (isConnecting) return;
    connectErrorMessage = null;
    isConnecting = true;
    notifyListeners();

    final currentState = await device.connectionState.first;
    if (currentState == BluetoothConnectionState.connected) {
      await _saveLastDeviceId();
      await discoverServices();
      isConnecting = false;
      notifyListeners();
      return;
    }

    if (currentState == BluetoothConnectionState.connecting) {
      final connected = await _waitForConnected();
      if (!connected) {
        connectErrorMessage = '연결에 실패했어요. 다시 시도해 주세요.';
        isConnecting = false;
        notifyListeners();
        return;
      }
      await _saveLastDeviceId();
      await discoverServices();
      isConnecting = false;
      notifyListeners();
      return;
    }

    try {
      await device.connect(
        license: License.free,
        autoConnect: false,
        mtu: null,
      );
    } catch (e) {
      debugPrint('Connect failed: $e');
      connectErrorMessage = '연결에 실패했어요. 다시 시도해 주세요.';
      isConnecting = false;
      notifyListeners();
      return;
    }

    final connected = await _waitForConnected();
    if (!connected) {
      connectErrorMessage = '연결에 실패했어요. 다시 시도해 주세요.';
      isConnecting = false;
      notifyListeners();
      return;
    }

    await _saveLastDeviceId();
    await discoverServices();
    isConnecting = false;
    notifyListeners();
  }

  Future<void> discoverServices() async {
    isLoadingServices = true;
    notifyListeners();
    try {
      final results = await device.discoverServices();
      debugPrint('Found ${results.length} services');
      services = results;
    } catch (e) {
      debugPrint('Discover services error: $e');
      connectErrorMessage = '서비스를 가져오지 못했어요.';
    } finally {
      isLoadingServices = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    try {
      await BlePreferences.setManualDisconnect(true);
      await device.disconnect();
      services = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Disconnect failed: $e');
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
