import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'services/history_service.dart';
import 'services/storage_service.dart';
import 'services/transfer_service.dart';
import 'state/discovery_state.dart';
import 'state/transfer_state.dart';
import 'state/web_share_state.dart';
import 'ui/screens/discovery_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LocalDropApp());
}

class LocalDropApp extends StatefulWidget {
  const LocalDropApp({super.key});

  @override
  State<LocalDropApp> createState() => _LocalDropAppState();
}

class _LocalDropAppState extends State<LocalDropApp> {
  late final DiscoveryState _discoveryState;
  late final HistoryService _historyService;
  late final StorageService _storageService;
  TransferState? _transferState;
  TransferService? _transferService;
  WebShareState? _webShareState;

  @override
  void initState() {
    super.initState();
    _storageService = StorageService();
    _discoveryState = DiscoveryState();
    _historyService = HistoryService();
    _historyService.init();
    _initTransferIntegration();
  }

  Future<void> _initTransferIntegration() async {
    _discoveryState.addListener(_onDiscoveryStateChanged);
    await _discoveryState.initialize();
    _onDiscoveryStateChanged();
  }

  void _onDiscoveryStateChanged() {
    final local = _discoveryState.localDevice;
    if (local != null && _transferService == null) {
      final service = TransferService(
        localDevice: local,
        storageService: _storageService,
      );
      final state = TransferState(
        transferService: service,
        historyService: _historyService,
      );
      _transferService = service;
      _transferState = state;
      state.startListening();

      _webShareState = WebShareState(
        storageService: _storageService,
        deviceName: local.name,
        historyService: _historyService,
      );

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _discoveryState.removeListener(_onDiscoveryStateChanged);
    _webShareState?.dispose();
    _transferState?.dispose();
    _discoveryState.dispose();
    _historyService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocalDrop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: DiscoveryScreen(
        discoveryState: _discoveryState,
        transferState: _transferState,
        historyService: _historyService,
        webShareState: _webShareState,
      ),
    );
  }
}

