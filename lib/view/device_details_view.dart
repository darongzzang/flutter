import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../viewmodel/device_details_view_model.dart';

class DeviceDetailsView extends StatefulWidget {
  const DeviceDetailsView({super.key, required this.device});

  final BluetoothDevice device;

  @override
  State<DeviceDetailsView> createState() => _DeviceDetailsViewState();
}

class _DeviceDetailsViewState extends State<DeviceDetailsView> {
  late final DeviceDetailsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DeviceDetailsViewModel(widget.device);
    _viewModel.addListener(_handleViewModelChanged);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _handleViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.platformName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _viewModel.isLoadingServices
                ? null
                : _viewModel.ensureConnectedAndDiscover,
          ),
        ],
      ),
      body: Center(
        child: _viewModel.isLoadingServices || _viewModel.isConnecting
            ? const CircularProgressIndicator()
            : _viewModel.services.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _viewModel.isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        size: 80,
                        color: _viewModel.isConnected ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _viewModel.isConnected
                            ? '기기 연결됨'
                            : '연결 끊김 (재연결 시도 중...)',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('ID: ${widget.device.remoteId}'),
                      const SizedBox(height: 16),
                      if (_viewModel.connectErrorMessage != null)
                        Text(
                          _viewModel.connectErrorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                        )
                      else
                        const Text('서비스를 찾지 못했습니다.'),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          Icon(
                            _viewModel.isConnected
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth_disabled,
                            color:
                                _viewModel.isConnected ? Colors.blue : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _viewModel.isConnected
                                  ? '기기 연결됨'
                                  : '연결 끊김 (재연결 시도 중...)',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('ID: ${widget.device.remoteId}'),
                      const SizedBox(height: 16),
                      const Text(
                        '서비스 목록',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final service in _viewModel.services) ...[
                        Text(
                          'Service: ${service.uuid}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        for (final characteristic in service.characteristics)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '• Characteristic: ${characteristic.uuid}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _viewModel.isConnected
                  ? _viewModel.disconnect
                  : _viewModel.ensureConnectedAndDiscover,
              child: Text(_viewModel.isConnected ? '연결 해제' : '다시 연결'),
            ),
          ),
        ),
      ),
    );
  }
}
