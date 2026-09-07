import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/device_model.dart';
import '../services/device_info_service.dart';
import '../services/discovery_service.dart';

class DiscoveryState extends ChangeNotifier {
  final DeviceInfoService _deviceInfoService;
  DiscoveryService? _discoveryService;
  StreamSubscription<List<DeviceModel>>? _peersSubscription;

  DeviceModel? _localDevice;
  List<DeviceModel> _peers = [];
  bool _isScanning = false;
  bool _isInitialized = false;
  String? _errorMessage;
  final bool _enableNetwork;

  DiscoveryState({
    DeviceInfoService? deviceInfoService,
    bool enableNetwork = true,
    DeviceModel? initialLocalDevice,
    List<DeviceModel>? initialPeers,
  }) : _deviceInfoService = deviceInfoService ?? DeviceInfoService(),
       _enableNetwork = enableNetwork,
       _localDevice = initialLocalDevice,
       _peers = initialPeers ?? [];

  DeviceModel? get localDevice => _localDevice;
  List<DeviceModel> get peers => _peers;
  bool get isScanning => _isScanning;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  /// Initializes local device info and starts discovery
  Future<void> initialize() async {
    if (_isInitialized) return;
    _errorMessage = null;

    if (!_enableNetwork) {
      _isInitialized = true;
      _isScanning = false;
      notifyListeners();
      return;
    }

    try {
      _localDevice = await _deviceInfoService.getLocalDevice();
      notifyListeners();

      _discoveryService = DiscoveryService(
        localDevice: _localDevice!,
        onPeersChanged: (peersList) {
          _peers = List.unmodifiable(peersList);
          notifyListeners();
        },
      );

      _peersSubscription = _discoveryService!.peersStream.listen((peersList) {
        _peers = List.unmodifiable(peersList);
        notifyListeners();
      });

      await _discoveryService!.start();
      _isScanning = true;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to start discovery: $e';
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Refreshes local network IP and restarts discovery
  Future<void> refresh() async {
    _errorMessage = null;
    notifyListeners();

    if (!_enableNetwork) {
      _isScanning = false;
      notifyListeners();
      return;
    }

    try {
      await _discoveryService?.stop();
      await _peersSubscription?.cancel();

      _localDevice = await _deviceInfoService.getLocalDevice();
      notifyListeners();

      _discoveryService = DiscoveryService(
        localDevice: _localDevice!,
        onPeersChanged: (peersList) {
          _peers = List.unmodifiable(peersList);
          notifyListeners();
        },
      );

      _peersSubscription = _discoveryService!.peersStream.listen((peersList) {
        _peers = List.unmodifiable(peersList);
        notifyListeners();
      });

      await _discoveryService!.start();
      _isScanning = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Refresh failed: $e';
      notifyListeners();
    }
  }

  /// Updates local device name and advertises the new name
  Future<void> updateDeviceName(String newName) async {
    if (newName.trim().isEmpty) return;
    if (_enableNetwork) {
      await _deviceInfoService.setCustomDeviceName(newName.trim());
      await refresh();
    } else {
      _localDevice = _localDevice?.copyWith(name: newName.trim());
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _peersSubscription?.cancel();
    _discoveryService?.stop();
    super.dispose();
  }
}
