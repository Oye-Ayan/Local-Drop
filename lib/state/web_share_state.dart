import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../core/utils/hotspot_helper.dart';
import '../models/transfer_item.dart';
import '../models/web_share_item.dart';
import '../services/history_service.dart';
import '../services/storage_service.dart';
import '../services/web_share_service.dart';

class WebShareState extends ChangeNotifier {
  final StorageService storageService;
  final HistoryService? historyService;
  final String deviceName;

  late final WebShareService _service;
  final List<SharedFileItem> _activeFiles = [];

  bool _isSharing = false;
  bool _isHotspotMode = false;
  String _hotspotSsid = '';
  String _hotspotPassword = '';
  List<String> _availableIps = [];
  String _selectedIp = '';

  String? _lastReceivedNotification;

  WebShareState({
    required this.storageService,
    required this.deviceName,
    this.historyService,
  }) {
    _hotspotSsid = HotspotHelper.generateDefaultSsid();
    _hotspotPassword = HotspotHelper.generateDefaultPassword();

    _service = WebShareService(
      storageService: storageService,
      deviceName: deviceName,
      onFileReceived: _handleWebFileReceived,
      onTextReceived: _handleWebTextReceived,
    );
  }

  bool get isSharing => _isSharing;
  bool get isHotspotMode => _isHotspotMode;
  String get hotspotSsid => _hotspotSsid;
  String get hotspotPassword => _hotspotPassword;
  List<String> get availableIps => _availableIps;
  String get selectedIp => _selectedIp;
  List<SharedFileItem> get activeFiles => List.unmodifiable(_activeFiles);
  String? get lastReceivedNotification => _lastReceivedNotification;

  String get webPortalUrl => _service.webPortalUrl;
  String get cleanWebUrl => _service.cleanWebUrl;
  String get sessionPin => _service.sessionPin;
  String get sessionToken => _service.sessionToken;

  String get wifiQrString => HotspotHelper.formatWifiQrString(
        ssid: _hotspotSsid,
        password: _hotspotPassword,
      );

  /// Initializes IP detection and starts Web Sharing
  Future<void> startSharing({
    String? localIp,
    List<String>? initialFilePaths,
  }) async {
    _availableIps = await HotspotHelper.getAvailableIpAddresses();

    if (localIp != null && localIp.isNotEmpty && localIp != '0.0.0.0') {
      _selectedIp = localIp;
    } else if (_availableIps.isNotEmpty) {
      _selectedIp = _availableIps.first;
    } else {
      _selectedIp = '192.168.43.1'; // Default mobile hotspot gateway fallback
    }

    if (initialFilePaths != null) {
      for (final path in initialFilePaths) {
        _addFileByPath(path);
      }
    }

    await _service.start(
      localIp: _selectedIp,
      initialFiles: _activeFiles,
    );
    _isSharing = true;
    notifyListeners();
  }

  /// Stops Web Sharing session and frees ports
  Future<void> stopSharing() async {
    await _service.stop();
    _activeFiles.clear();
    _isSharing = false;
    notifyListeners();
  }

  /// Changes the IP address being broadcast/encoded in QR code
  Future<void> selectIp(String ip) async {
    if (_selectedIp == ip) return;
    _selectedIp = ip;
    if (_isSharing) {
      await _service.start(
        localIp: _selectedIp,
        initialFiles: _activeFiles,
      );
    }
    notifyListeners();
  }

  /// Opens system file picker to queue files for web download
  Future<void> pickAndAddFiles() async {
    try {
      final result = await FilePicker.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        for (final f in result.files) {
          if (f.path != null) {
            _addFileByPath(f.path!);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking files for Web Share: $e');
    }
  }

  void _addFileByPath(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return;

    final id = 'f_${DateTime.now().millisecondsSinceEpoch}_${_activeFiles.length}';
    final name = p.basename(filePath);
    final size = file.lengthSync();
    final mime = SharedFileItem.guessMimeType(filePath);

    final item = SharedFileItem(
      id: id,
      name: name,
      path: filePath,
      sizeBytes: size,
      mimeType: mime,
    );

    _activeFiles.add(item);
    _service.addSharedFile(item);
  }

  void removeFile(String id) {
    _activeFiles.removeWhere((f) => f.id == id);
    _service.removeSharedFile(id);
    notifyListeners();
  }

  void toggleHotspotMode(bool value) {
    _isHotspotMode = value;
    notifyListeners();
  }

  void updateHotspotDetails(String ssid, String password) {
    _hotspotSsid = ssid.trim();
    _hotspotPassword = password.trim();
    notifyListeners();
  }

  void clearNotification() {
    _lastReceivedNotification = null;
    notifyListeners();
  }

  void _handleWebFileReceived(File file, String name, int size) {
    _lastReceivedNotification = 'Received "$name" (${(size / 1024).toStringAsFixed(1)} KB) from Web Portal';

    // Record completed file transfer into history
    final transferItem = TransferItem(
      id: 'web_${DateTime.now().millisecondsSinceEpoch}',
      fileName: name,
      fileSizeBytes: size,
      bytesTransferred: size,
      filePath: file.path,
      direction: TransferDirection.incoming,
      peerId: 'web-client',
      peerName: 'Web Portal',
      peerIp: _selectedIp,
      status: TransferStatus.completed,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      checksumVerified: true,
    );

    historyService?.recordTransfer(transferItem);
    notifyListeners();
  }

  void _handleWebTextReceived(String text) {
    _lastReceivedNotification = 'Web Note: "$text"';
    notifyListeners();
  }

  @override
  void dispose() {
    _service.stop();
    super.dispose();
  }
}
