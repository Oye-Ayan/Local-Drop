import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/protocol_constants.dart';
import '../models/device_model.dart';
import '../models/transfer_item.dart';
import '../services/transfer_service.dart';

class TransferState extends ChangeNotifier {
  final TransferService _transferService;
  StreamSubscription<TransferItem>? _updatesSubscription;

  TransferItem? _activeTransfer;
  TransferItem? _incomingPrompt;
  Completer<bool>? _incomingCompleter;
  Timer? _countdownTimer;
  int _countdownSeconds = ProtocolConstants.transferPromptTimeoutSeconds;

  TransferState({required TransferService transferService})
    : _transferService = transferService {
    _init();
  }

  TransferItem? get activeTransfer => _activeTransfer;
  TransferItem? get incomingPrompt => _incomingPrompt;
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
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null) {
        final filePath = result.files.first.path!;
        final file = File(filePath);
        await sendFile(targetPeer: targetPeer, file: file);
      }
    } catch (e) {
      debugPrint('File picker error: $e');
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
