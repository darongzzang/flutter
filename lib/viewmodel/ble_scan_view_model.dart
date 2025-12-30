import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../services/ble_preferences.dart';

class BleScanViewModel extends ChangeNotifier {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  String? scanStatusMessage;
  BluetoothDevice? pendingNavigationDevice;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool _didAutoNavigate = false;
  bool _isAutoNavigatingFromScan = false;

  static final List<Guid> _systemDeviceServices = [Guid('1800')];

  Future<void> initialize() async {
    final adapterReady = await _waitForAdapterOn();
    if (!adapterReady) return;

    final didNavigate = await _openLastDeviceIfAvailable();
    if (!didNavigate) {
      final didSystemNavigate = await _openBondedDeviceIfAvailable();
      if (!didSystemNavigate) {
        await startScan(allowAutoNavigate: false);
      }
    }
  }

  Future<bool> _waitForAdapterOn() async {
    try {
      final state = await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 5));
      return state == BluetoothAdapterState.on;
    } catch (_) {
      scanStatusMessage = '블루투스가 꺼져 있어요. 설정에서 켜 주세요.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _isBondedOnAndroid(BluetoothDevice device) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final state = await device.bondState.first;
      return state == BluetoothBondState.bonded;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _openBondedDeviceIfAvailable() async {
    if (_didAutoNavigate) return false;
    try {
      final systemDevices =
          await FlutterBluePlus.systemDevices(_systemDeviceServices);
      for (final device in systemDevices) {
        final shouldOpen = defaultTargetPlatform == TargetPlatform.android
            ? await _isBondedOnAndroid(device)
            : true;
        if (shouldOpen) {
          _didAutoNavigate = true;
          pendingNavigationDevice = device;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('System devices error: $e');
    }
    return false;
  }

  Future<bool> _openLastDeviceIfAvailable() async {
    if (_didAutoNavigate) return false;

    final didManualDisconnect = await BlePreferences.getManualDisconnect();
    if (didManualDisconnect) {
      return false;
    }

    final remoteId = await BlePreferences.getLastDeviceId();
    if (remoteId == null || remoteId.isEmpty) {
      return false;
    }

    final device = BluetoothDevice.fromId(remoteId);
    try {
      await device.connect(
        license: License.free,
        autoConnect: true,
        mtu: null,
      );
      await device.connectionState
          .where((state) => state == BluetoothConnectionState.connected)
          .first
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Auto connect failed: $e');
      try {
        await device.disconnect();
      } catch (_) {}
      return false;
    }

    _didAutoNavigate = true;
    pendingNavigationDevice = device;
    notifyListeners();
    return true;
  }

  Future<void> _tryAutoOpenFromScanResults(List<ScanResult> results) async {
    if (_didAutoNavigate || _isAutoNavigatingFromScan) return;
    for (final result in results) {
      final device = result.device;
      final isBonded = await _isBondedOnAndroid(device);
      if (!isBonded) continue;
      _isAutoNavigatingFromScan = true;
      _didAutoNavigate = true;
      pendingNavigationDevice = device;
      notifyListeners();
      _isAutoNavigatingFromScan = false;
      return;
    }
  }

  Future<void> startScan({bool allowAutoNavigate = true}) async {
    if (allowAutoNavigate) {
      _didAutoNavigate = false;
      final didNavigate = await _openLastDeviceIfAvailable();
      if (didNavigate) {
        return;
      }
      final didSystemNavigate = await _openBondedDeviceIfAvailable();
      if (didSystemNavigate) {
        return;
      }
    }

    final adapterReady = await _waitForAdapterOn();
    if (!adapterReady) {
      return;
    }

    isScanning = true;
    scanResults = [];
    scanStatusMessage = null;
    notifyListeners();

    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.onScanResults.listen(
      (results) async {
        scanResults = results;
        notifyListeners();
        await _tryAutoOpenFromScanResults(results);
      },
      onError: (e) => debugPrint('Scan Error: $e'),
    );

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      debugPrint('Start scan error: $e');
      scanStatusMessage = '스캔을 시작하지 못했어요.';
      notifyListeners();
    }

    isScanning = false;
    notifyListeners();
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    isScanning = false;
    notifyListeners();
  }

  Future<void> openDeviceFromTap(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    pendingNavigationDevice = device;
    notifyListeners();
  }

  void clearPendingNavigation() {
    pendingNavigationDevice = null;
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}
