import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../viewmodel/ble_scan_view_model.dart';
import 'device_details_view.dart';

class BleScanView extends StatefulWidget {
  const BleScanView({super.key});

  @override
  State<BleScanView> createState() => _BleScanViewState();
}

class _BleScanViewState extends State<BleScanView> {
  late final BleScanViewModel _viewModel;
  bool _isNavigating = false;

  /// 상태 초기화
  @override
  void initState() {
    super.initState();
    _viewModel = BleScanViewModel();
    _viewModel.addListener(_handleViewModelChanged);
    _viewModel.initialize();
  }

  /// 위젯 정리
  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _handleViewModelChanged() {
    if (!mounted) return;
    _handlePendingNavigation();
    setState(() {});
  }

  Future<void> _handlePendingNavigation() async {
    final device = _viewModel.pendingNavigationDevice;
    if (device == null || _isNavigating) return;
    _isNavigating = true;
    _viewModel.clearPendingNavigation();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeviceDetailsView(device: device),
      ),
    );
    _isNavigating = false;
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await _viewModel.openDeviceFromTap(device);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE 기기 찾기'),
        actions: [
          if (_viewModel.isScanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _viewModel.startScan,
            ),
        ],
      ),
      body: _viewModel.scanResults.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_viewModel.isScanning) const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _viewModel.scanStatusMessage ??
                        (_viewModel.isScanning
                            ? '주변 기기 검색 중...'
                            : '기기를 찾지 못했습니다'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _viewModel.scanResults.length,
              itemBuilder: (context, index) {
                final result = _viewModel.scanResults[index];
                final device = result.device;
                final name = device.platformName.isNotEmpty
                    ? device.platformName
                    : '알 수 없는 기기';

                return ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(name),
                  subtitle: Text(device.remoteId.toString()),
                  trailing: Text('${result.rssi} dBm'),
                  onTap: () => _connectToDevice(device),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed:
                  _viewModel.isScanning ? _viewModel.stopScan : () => Navigator.of(context).pop(),
              child: Text(_viewModel.isScanning ? '스캔 중지' : '로그인 화면으로'),
            ),
          ),
        ),
      ),
    );
  }
}
