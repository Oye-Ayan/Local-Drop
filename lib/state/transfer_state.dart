import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/protocol_constants.dart';
import '../models/device_model.dart';
import '../models/transfer_item.dart';
import '../services/history_service.dart';
import '../services/transfer_service.dart';

class TransferState extends ChangeNotifier {
  final TransferService _transferService;
  final HistoryService? _historyService;
  StreamSubscription<TransferItem>? _updatesSubscription;

  TransferItem? _activeTransfer;
  TransferItem? _incomingPrompt;
  Completer<bool>? _incomingCompleter;
  Timer? _countdownTimer;
  int _countdownSeconds = ProtocolConstants.transferPromptTimeoutSeconds;

  TransferState({
    required TransferService transferService,
    HistoryService? historyService,
  })  : _transferService = transferService,
        _historyService = historyService {
    _init();
  }

  TransferItem? get activeTransfer => _activeTransfer;
  TransferItem? get incomingPrompt => _incomingPrompt;
  HistoryService? get historyService => _historyService;
  int get countdownSeconds => _countdownSeconds;
  bool get hasIncomingPrompt => _incomingPrompt != null;
  bool get hasActiveTransfer =>
      _activeTransfer != null && !_activeTransfer!.status.isDone;

  void _init() {
    _transferService.onIncomingTransferRequest = _handleIncomingRequest;
    _updatesSubscription = _transferService.transferUpdates.listen((
      updatedItem,
    ) {
      _activeTransfer = updatedItem;
      if (updatedItem.status == TransferStatus.completed) {
        _historyService?.recordTransfer(updatedItem);
      }
      notifyListeners();
    });
  }

  Future<void> startListening({
    int port = ProtocolConstants.defaultTcpPort,
  }) async {
    await _transferService.startListening(port: port);
  }

  Future<bool> _handleIncomingRequest(TransferItem item) {
    _incomingPrompt = item;
    _countdownSeconds = ProtocolConstants.transferPromptTimeoutSeconds;
    _incomingCompleter = Completer<bool>();
    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        _countdownSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        rejectIncoming();
      }
    });

    return _incomingCompleter!.future;
  }

  void acceptIncoming() {
    _countdownTimer?.cancel();
    if (_incomingCompleter != null && !_incomingCompleter!.isCompleted) {
      _incomingCompleter!.complete(true);
    }
    _incomingPrompt = null;
    notifyListeners();
  }

  void rejectIncoming() {
    _countdownTimer?.cancel();
    if (_incomingCompleter != null && !_incomingCompleter!.isCompleted) {
      _incomingCompleter!.complete(false);
    }
    _incomingPrompt = null;
    notifyListeners();
  }

  /// Opens the native OS file picker and initiates transfer to target peer
  Future<void> pickAndSendFile(DeviceModel targetPeer) async {
    try {
      if (targetPeer.ip.isEmpty || targetPeer.ip == '0.0.0.0' || targetPeer.ip.endsWith('.local')) {
        _activeTransfer = TransferItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fileName: 'File',
          fileSizeBytes: 0,
          filePath: '',
          direction: TransferDirection.outgoing,
          peerId: targetPeer.id,
          peerName: targetPeer.name,
          peerIp: targetPeer.ip,
          status: TransferStatus.failed,
          errorMessage: 'Cannot connect to peer with invalid IP: ${targetPeer.ip}',
        );
        notifyListeners();
        return;
      }

      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.first;
        File? file;
        if (picked.path != null && picked.path!.isNotEmpty) {
          file = File(picked.path!);
        } else if (picked.bytes != null) {
          final tempDir = Directory.systemTemp;
          file = File('${tempDir.path}/${picked.name}');
          await file.writeAsBytes(picked.bytes!);
        }

        if (file != null && await file.exists()) {
          await sendFile(targetPeer: targetPeer, file: file);
        }
      }
    } catch (e) {
      debugPrint('File picker error: $e');
      _activeTransfer = TransferItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: 'File',
        fileSizeBytes: 0,
        filePath: '',
        direction: TransferDirection.outgoing,
        peerId: targetPeer.id,
        peerName: targetPeer.name,
        peerIp: targetPeer.ip,
        status: TransferStatus.failed,
        errorMessage: 'File selection error: $e',
      );
      notifyListeners();
    }
  }

  /// Sends a specific file to a target peer
  Future<void> sendFile({
    required DeviceModel targetPeer,
    required File file,
  }) async {
    _activeTransfer = null;
    notifyListeners();
    await _transferService.sendFile(targetPeer: targetPeer, file: file);
  }

  /// Cancels currently active transfer
  void cancelActiveTransfer() {
    if (_activeTransfer != null) {
      _transferService.cancelTransfer(_activeTransfer!.id);
      _activeTransfer = _activeTransfer!.copyWith(
        status: TransferStatus.cancelled,
        errorMessage: 'Cancelled by user',
      );
      notifyListeners();
    }
  }

  void clearActiveTransfer() {
    _activeTransfer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _updatesSubscription?.cancel();
    _transferService.dispose();
    super.dispose();
  }
}
