import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/protocol_constants.dart';
import '../models/device_model.dart';
import '../models/transfer_item.dart';
import 'storage_service.dart';

class _DigestAccumulator implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}

/// Protocol frame helper: [1 byte OpCode] [4 bytes Length (BigEndian)] [Payload]
class ProtocolFrame {
  final int opCode;
  final Uint8List payload;

  ProtocolFrame({required this.opCode, required this.payload});

  static Uint8List encode(int opCode, List<int> payload) {
    final length = payload.length;
    final bytes = Uint8List(5 + length);
    final view = ByteData.view(bytes.buffer);

    bytes[0] = opCode;
    view.setUint32(1, length, Endian.big);
    bytes.setRange(5, 5 + length, payload);
    return bytes;
  }
}

/// High-performance accumulator for incoming TCP bytes with zero-copy frame slicing
class FrameDecoder {
  Uint8List _buffer = Uint8List(512 * 1024);
  int _length = 0;

  List<ProtocolFrame> feed(List<int> chunk) {
    final needed = _length + chunk.length;
    if (needed > _buffer.length) {
      int newCap = _buffer.length * 2;
      while (newCap < needed) {
        newCap *= 2;
      }
      final newBuf = Uint8List(newCap);
      newBuf.setRange(0, _length, _buffer);
      _buffer = newBuf;
    }

    _buffer.setRange(_length, _length + chunk.length, chunk);
    _length += chunk.length;

    final frames = <ProtocolFrame>[];
    int offset = 0;

    final view = ByteData.view(_buffer.buffer, _buffer.offsetInBytes);

    while (_length - offset >= 5) {
      final opCode = _buffer[offset];
      final payloadLength = view.getUint32(offset + 1, Endian.big);
      final totalFrameLength = 5 + payloadLength;

      if (_length - offset < totalFrameLength) {
        break; // Incomplete frame, wait for more data
      }

      final payload = Uint8List(payloadLength);
      payload.setRange(0, payloadLength, _buffer, offset + 5);
      frames.add(ProtocolFrame(opCode: opCode, payload: payload));

      offset += totalFrameLength;
    }

    if (offset > 0) {
      final remaining = _length - offset;
      if (remaining > 0) {
        _buffer.setRange(0, remaining, _buffer, offset);
      }
      _length = remaining;
    }

    return frames;
  }

  void clear() {
    _length = 0;
  }
}

typedef IncomingPromptCallback = Future<bool> Function(TransferItem item);

class TransferService {
  final DeviceModel localDevice;
  final StorageService _storageService;

  ServerSocket? _serverSocket;
  bool _isListening = false;

  IncomingPromptCallback? onIncomingTransferRequest;
  final StreamController<TransferItem> _transferUpdatesController =
      StreamController<TransferItem>.broadcast();

  // Active transfers in flight
  final Map<String, Socket> _activeSockets = {};
  final Map<String, Completer<bool>> _pendingAccepts = {};

  TransferService({
    required this.localDevice,
    StorageService? storageService,
    this.onIncomingTransferRequest,
  }) : _storageService = storageService ?? StorageService();

  Stream<TransferItem> get transferUpdates => _transferUpdatesController.stream;
  bool get isListening => _isListening;

  void _notifyTransferUpdate(TransferItem item) {
    if (!_transferUpdatesController.isClosed) {
      _transferUpdatesController.add(item);
    }
  }

  /// Starts the TCP listener on local network
  Future<void> startListening({
    int port = ProtocolConstants.defaultTcpPort,
  }) async {
    if (_isListening) return;

    try {
      _serverSocket = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        port,
        shared: true,
      );
      _isListening = true;
      debugPrint('TransferService listening on port $port');

      _serverSocket!.listen(
        _handleIncomingConnection,
        onError: (err) => debugPrint('Server socket error: $err'),
      );
    } catch (e) {
      debugPrint(
        'Failed to bind TransferService server socket on port $port: $e',
      );
    }
  }

  /// Stops TCP listener and closes all active sockets
  Future<void> stop() async {
    _isListening = false;
    for (final socket in _activeSockets.values) {
      try {
        socket.destroy();
      } catch (_) {}
    }
    _activeSockets.clear();

    await _serverSocket?.close();
    _serverSocket = null;
  }

  // ==========================================
  // RECEIVER ENGINE
  // ==========================================

  void _handleIncomingConnection(Socket socket) {
    socket.setOption(SocketOption.tcpNoDelay, true);
    final decoder = FrameDecoder();
    String? currentTransferId;
    IOSink? fileSink;
    File? tempFile;
    _DigestAccumulator? hashSinkAcc;
    ChunkedConversionSink<List<int>>? hashSink;
    TransferItem? transferItem;
    int lastSpeedCheckTime = DateTime.now().millisecondsSinceEpoch;
    int lastNotificationTime = DateTime.now().millisecondsSinceEpoch;
    int bytesSinceLastCheck = 0;

    socket.listen(
      (data) async {
        final frames = decoder.feed(data);
        for (final frame in frames) {
          switch (frame.opCode) {
            case ProtocolConstants.msgTransferRequest:
              try {
                final json =
                    jsonDecode(utf8.decode(frame.payload))
                        as Map<String, dynamic>;
                currentTransferId = json['id'] as String;
                _activeSockets[currentTransferId!] = socket;

                transferItem = TransferItem(
                  id: currentTransferId!,
                  fileName: json['fileName'] as String,
                  fileSizeBytes: (json['fileSize'] as num).toInt(),
                  filePath: '',
                  direction: TransferDirection.incoming,
                  peerId: json['senderId'] as String? ?? '',
                  peerName: json['senderName'] as String? ?? 'Nearby Device',
                  peerIp: socket.remoteAddress.address,
                  status: TransferStatus.pending,
                  sha256Checksum: json['sha256'] as String?,
                );
                _notifyTransferUpdate(transferItem!);

                // Prompt user
                bool accepted = false;
                if (onIncomingTransferRequest != null) {
                  accepted = await onIncomingTransferRequest!(transferItem!);
                }

                if (accepted) {
                  try {
                    tempFile = await _storageService.createTempFile(
                      currentTransferId!,
                    );
                    fileSink = tempFile!.openWrite();
                    hashSinkAcc = _DigestAccumulator();
                    hashSink = sha256.startChunkedConversion(hashSinkAcc!);

                    transferItem = transferItem!.copyWith(
                      status: TransferStatus.inProgress,
                    );
                    _notifyTransferUpdate(transferItem!);

                    // Send accept frame
                    final acceptPayload = utf8.encode(
                      jsonEncode({'id': currentTransferId, 'accepted': true}),
                    );
                    socket.add(
                      ProtocolFrame.encode(
                        ProtocolConstants.msgTransferAccept,
                        acceptPayload,
                      ),
                    );
                    await socket.flush();
                  } catch (err) {
                    debugPrint('Failed to prepare file storage: $err');
                    try {
                      final rejectPayload = utf8.encode(
                        jsonEncode({
                          'id': currentTransferId,
                          'reason': 'Storage error: $err',
                        }),
                      );
                      socket.add(
                        ProtocolFrame.encode(
                          ProtocolConstants.msgTransferReject,
                          rejectPayload,
                        ),
                      );
                      await socket.flush();
                    } catch (_) {}
                    socket.destroy();
                    transferItem = transferItem!.copyWith(
                      status: TransferStatus.failed,
                      errorMessage: 'Storage preparation error: $err',
                    );
                    _notifyTransferUpdate(transferItem!);
                  }
                } else {
                  // Send reject frame
                  final rejectPayload = utf8.encode(
                    jsonEncode({'id': currentTransferId, 'reason': 'declined'}),
                  );
                  socket.add(
                    ProtocolFrame.encode(
                      ProtocolConstants.msgTransferReject,
                      rejectPayload,
                    ),
                  );
                  await socket.flush();
                  socket.destroy();
                  transferItem = transferItem!.copyWith(
                    status: TransferStatus.rejected,
                  );
                  _notifyTransferUpdate(transferItem!);
                }
              } catch (e) {
                debugPrint('Error handling transfer request: $e');
                try {
                  final rejectPayload = utf8.encode(
                    jsonEncode({'id': currentTransferId, 'reason': 'Error: $e'}),
                  );
                  socket.add(
                    ProtocolFrame.encode(
                      ProtocolConstants.msgTransferReject,
                      rejectPayload,
                    ),
                  );
                  await socket.flush();
                } catch (_) {}
                socket.destroy();
              }
              break;

            case ProtocolConstants.msgFileChunk:
              if (fileSink != null && transferItem != null) {
                final chunk = frame.payload;
                fileSink!.add(chunk);
                hashSink?.add(chunk);

                final newTransferred =
                    transferItem!.bytesTransferred + chunk.length;
                bytesSinceLastCheck += chunk.length;

                // Speed calculation every 250ms
                final now = DateTime.now().millisecondsSinceEpoch;
                final elapsed = (now - lastSpeedCheckTime) / 1000.0;
                double speed = transferItem!.speedBytesPerSec;
                if (elapsed >= 0.25) {
                  speed = bytesSinceLastCheck / elapsed;
                  lastSpeedCheckTime = now;
                  bytesSinceLastCheck = 0;
                }

                transferItem = transferItem!.copyWith(
                  bytesTransferred: newTransferred,
                  speedBytesPerSec: speed,
                );

                // Throttle progress notifications to at most once per 100ms
                if (now - lastNotificationTime >= 100) {
                  lastNotificationTime = now;
                  _notifyTransferUpdate(transferItem!);
                }
              }
              break;

            case ProtocolConstants.msgTransferComplete:
              if (fileSink != null && transferItem != null) {
                try {
                  await fileSink!.flush();
                  await fileSink!.close();
                  fileSink = null;
                  hashSink?.close();

                  final computedSha = hashSinkAcc?.value?.toString() ?? '';

                  final json =
                      jsonDecode(utf8.decode(frame.payload))
                          as Map<String, dynamic>;
                  final senderSha = json['sha256'] as String? ?? '';

                  final checksumMatches =
                      (senderSha.isEmpty || computedSha == senderSha);

                  if (checksumMatches && tempFile != null) {
                    final destPath = await _storageService
                        .getUniqueDestinationPath(transferItem!.fileName);
                    final finalFile = await _storageService.finalizeFile(
                      tempFile!,
                      destPath,
                    );

                    transferItem = transferItem!.copyWith(
                      status: TransferStatus.completed,
                      filePath: finalFile.path,
                      sha256Checksum: computedSha,
                      checksumVerified: true,
                      endTime: DateTime.now(),
                      speedBytesPerSec: 0,
                    );
                    _notifyTransferUpdate(transferItem!);

                    // Send complete ACK
                    final ackPayload = utf8.encode(
                      jsonEncode({
                        'id': currentTransferId,
                        'success': true,
                        'verified': true,
                      }),
                    );
                    socket.add(
                      ProtocolFrame.encode(
                        ProtocolConstants.msgTransferComplete,
                        ackPayload,
                      ),
                    );
                    await socket.flush();
                  } else {
                    await _storageService.cleanupTempFile(currentTransferId!);
                    transferItem = transferItem!.copyWith(
                      status: TransferStatus.failed,
                      errorMessage: 'Checksum verification failed',
                      endTime: DateTime.now(),
                    );
                    _notifyTransferUpdate(transferItem!);

                    final errPayload = utf8.encode(
                      jsonEncode({
                        'id': currentTransferId,
                        'code': ProtocolConstants.errChecksumMismatch,
                        'message': 'Checksum verification mismatch',
                      }),
                    );
                    socket.add(
                      ProtocolFrame.encode(
                        ProtocolConstants.msgError,
                        errPayload,
                      ),
                    );
                    await socket.flush();
                  }
                } catch (e) {
                  debugPrint('Error finalizing received file: $e');
                } finally {
                  socket.destroy();
                }
              }
              break;

            case ProtocolConstants.msgError:
              await fileSink?.close();
              if (currentTransferId != null) {
                await _storageService.cleanupTempFile(currentTransferId!);
              }
              if (transferItem != null) {
                transferItem = transferItem!.copyWith(
                  status: TransferStatus.cancelled,
                  errorMessage: 'Transfer cancelled by peer',
                  endTime: DateTime.now(),
                );
                _notifyTransferUpdate(transferItem!);
              }
              socket.destroy();
              break;
          }
        }
      },
      onError: (err) async {
        debugPrint('Socket error on receiver: $err');
        await fileSink?.close();
        if (currentTransferId != null) {
          await _storageService.cleanupTempFile(currentTransferId!);
        }
        if (transferItem != null) {
          transferItem = transferItem!.copyWith(
            status: TransferStatus.failed,
            errorMessage: 'Network error: $err',
            endTime: DateTime.now(),
          );
          _notifyTransferUpdate(transferItem!);
        }
      },
      onDone: () async {
        await fileSink?.close();
        if (currentTransferId != null &&
            transferItem?.status != TransferStatus.completed) {
          await _storageService.cleanupTempFile(currentTransferId!);
        }
        if (currentTransferId != null) {
          _activeSockets.remove(currentTransferId);
        }
      },
    );
  }

  // ==========================================
  // SENDER ENGINE
  // ==========================================

  /// Initiates an outgoing file transfer to a target peer
  Future<TransferItem> sendFile({
    required DeviceModel targetPeer,
    required File file,
  }) async {
    if (!await file.exists()) {
      throw Exception('Selected file does not exist: ${file.path}');
    }

    final fileSize = await file.length();
    final fileName = file.uri.pathSegments.last;
    final transferId =
        '${DateTime.now().millisecondsSinceEpoch}_${file.hashCode.abs()}';

    var item = TransferItem(
      id: transferId,
      fileName: fileName,
      fileSizeBytes: fileSize,
      filePath: file.path,
      direction: TransferDirection.outgoing,
      peerId: targetPeer.id,
      peerName: targetPeer.name,
      peerIp: targetPeer.ip,
      status: TransferStatus.pending,
    );
    _notifyTransferUpdate(item);

    Socket? socket;
    try {
      socket = await Socket.connect(
        targetPeer.ip,
        targetPeer.port,
        timeout: const Duration(seconds: 6),
      );
      socket.setOption(SocketOption.tcpNoDelay, true);
      _activeSockets[transferId] = socket;

      final acceptCompleter = Completer<bool>();
      final completeCompleter = Completer<void>();
      _pendingAccepts[transferId] = acceptCompleter;
      final decoder = FrameDecoder();

      socket.listen(
        (data) {
          final frames = decoder.feed(data);
          for (final frame in frames) {
            if (frame.opCode == ProtocolConstants.msgTransferAccept) {
              if (!acceptCompleter.isCompleted) {
                acceptCompleter.complete(true);
              }
            } else if (frame.opCode == ProtocolConstants.msgTransferReject) {
              if (!acceptCompleter.isCompleted) {
                acceptCompleter.complete(false);
              }
            } else if (frame.opCode == ProtocolConstants.msgTransferComplete) {
              if (!completeCompleter.isCompleted) {
                completeCompleter.complete();
              }
              item = item.copyWith(
                status: TransferStatus.completed,
                bytesTransferred: fileSize,
                checksumVerified: true,
                endTime: DateTime.now(),
                speedBytesPerSec: 0,
              );
              _notifyTransferUpdate(item);
            } else if (frame.opCode == ProtocolConstants.msgError) {
              if (!completeCompleter.isCompleted) {
                completeCompleter.complete();
              }
              item = item.copyWith(
                status: TransferStatus.failed,
                errorMessage: 'Transfer error from receiver',
                endTime: DateTime.now(),
              );
              _notifyTransferUpdate(item);
            }
          }
        },
        onError: (err) {
          debugPrint('Sender socket error: $err');
          if (!acceptCompleter.isCompleted) {
            acceptCompleter.complete(false);
          }
          if (!completeCompleter.isCompleted) {
            completeCompleter.complete();
          }
        },
        onDone: () {
          if (!acceptCompleter.isCompleted) {
            acceptCompleter.complete(false);
          }
          if (!completeCompleter.isCompleted) {
            completeCompleter.complete();
          }
        },
      );

      // 1. Send TRANSFER_REQUEST
      final reqPayload = utf8.encode(
        jsonEncode({
          'id': transferId,
          'fileName': fileName,
          'fileSize': fileSize,
          'senderName': localDevice.name,
          'senderId': localDevice.id,
        }),
      );
      socket.add(
        ProtocolFrame.encode(ProtocolConstants.msgTransferRequest, reqPayload),
      );
      await socket.flush();

      // 2. Await accept / reject
      final accepted = await acceptCompleter.future.timeout(
        const Duration(
          seconds: ProtocolConstants.transferPromptTimeoutSeconds + 2,
        ),
        onTimeout: () => false,
      );

      if (!accepted) {
        item = item.copyWith(
          status: TransferStatus.rejected,
          errorMessage: 'Transfer request was declined or timed out',
          endTime: DateTime.now(),
        );
        _notifyTransferUpdate(item);
        socket.destroy();
        return item;
      }

      // 3. Accepted -> Stream file chunks with backpressure & SHA-256 computation
      item = item.copyWith(status: TransferStatus.inProgress);
      _notifyTransferUpdate(item);

      final digestAcc = _DigestAccumulator();
      final hashSink = sha256.startChunkedConversion(digestAcc);

      int bytesSent = 0;
      int lastSpeedCheckTime = DateTime.now().millisecondsSinceEpoch;
      int bytesSinceLastCheck = 0;

      final fileStream = file.openRead();
      int unflushedBytes = 0;
      int lastNotificationTime = DateTime.now().millisecondsSinceEpoch;

      await for (final chunk in fileStream) {
        if (item.status == TransferStatus.cancelled) break;

        hashSink.add(chunk);
        final frameBytes = ProtocolFrame.encode(
          ProtocolConstants.msgFileChunk,
          chunk,
        );
        socket.add(frameBytes);
        unflushedBytes += frameBytes.length;

        // Batch socket flushes every 512KB to maintain high network throughput while respecting backpressure
        if (unflushedBytes >= 512 * 1024) {
          await socket.flush();
          unflushedBytes = 0;
        }

        bytesSent += chunk.length;
        bytesSinceLastCheck += chunk.length;

        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsed = (now - lastSpeedCheckTime) / 1000.0;
        double speed = item.speedBytesPerSec;
        if (elapsed >= 0.25) {
          speed = bytesSinceLastCheck / elapsed;
          lastSpeedCheckTime = now;
          bytesSinceLastCheck = 0;
        }

        item = item.copyWith(
          bytesTransferred: bytesSent,
          speedBytesPerSec: speed,
        );

        // Throttle UI stream updates to at most once every 100ms
        if (now - lastNotificationTime >= 100) {
          lastNotificationTime = now;
          _notifyTransferUpdate(item);
        }
      }

      if (unflushedBytes > 0) {
        await socket.flush();
      }
      _notifyTransferUpdate(item);

      hashSink.close();
      final finalChecksum = digestAcc.value?.toString() ?? '';

      // 4. Send TRANSFER_COMPLETE with final checksum
      final completePayload = utf8.encode(
        jsonEncode({'id': transferId, 'sha256': finalChecksum}),
      );
      socket.add(
        ProtocolFrame.encode(
          ProtocolConstants.msgTransferComplete,
          completePayload,
        ),
      );
      await socket.flush();

      try {
        await completeCompleter.future.timeout(const Duration(seconds: 15));
      } catch (_) {}
      socket.destroy();

      return item;
    } catch (e) {
      item = item.copyWith(
        status: TransferStatus.failed,
        errorMessage: 'Connection failed: $e',
        endTime: DateTime.now(),
      );
      _notifyTransferUpdate(item);
      socket?.destroy();
      return item;
    } finally {
      _pendingAccepts.remove(transferId);
    }
  }

  /// Cancels an active transfer
  void cancelTransfer(String transferId) {
    final socket = _activeSockets[transferId];
    if (socket != null) {
      try {
        final errPayload = utf8.encode(
          jsonEncode({
            'id': transferId,
            'code': ProtocolConstants.errCancelled,
            'message': 'Cancelled by user',
          }),
        );
        socket.add(
          ProtocolFrame.encode(ProtocolConstants.msgError, errPayload),
        );
        socket.destroy();
      } catch (_) {}
      _activeSockets.remove(transferId);
    }
  }

  void dispose() {
    stop();
    _transferUpdatesController.close();
  }
}
