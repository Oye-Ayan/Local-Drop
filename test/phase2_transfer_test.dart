import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localdrop/models/device_model.dart';
import 'package:localdrop/models/transfer_item.dart';
import 'package:localdrop/services/storage_service.dart';
import 'package:localdrop/services/transfer_service.dart';
import 'package:localdrop/state/transfer_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2 End-to-End TCP Transfer & Engine Tests', () {
    late Directory tempDir;
    late DeviceModel senderDevice;
    late DeviceModel receiverDevice;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('localdrop_p2_test_');

      senderDevice = DeviceModel(
        id: 'sender-device-01',
        name: 'Sender Terminal',
        ip: '127.0.0.1',
        port: 53321,
        deviceType: DeviceType.desktop,
        osName: 'Linux',
      );

      receiverDevice = DeviceModel(
        id: 'receiver-device-01',
        name: 'Receiver Terminal',
        ip: '127.0.0.1',
        port: 53322,
        deviceType: DeviceType.desktop,
        osName: 'Linux',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'Full End-to-End File Transfer between Sender and Receiver over TCP',
      () async {
        // 1. Create a mock 150KB test file (spans across multiple 64KB chunks)
        final testFile = File('${tempDir.path}/test_payload.bin');
        final randomBytes = List<int>.generate(
          150 * 1024,
          (i) => (i * 17 + 31) % 256,
        );
        await testFile.writeAsBytes(randomBytes);
        final expectedSha256 = sha256.convert(randomBytes).toString();

        // 2. Setup receiver transfer service with isolated temp storage
        final receiverStorage = StorageService(customBaseDirectory: tempDir);
        final receiverService = TransferService(
          localDevice: receiverDevice,
          storageService: receiverStorage,
        );
        final receiverState = TransferState(transferService: receiverService);

        // Bind receiver on test port
        await receiverService.startListening(port: 53322);

        // Auto-accept incoming request on receiver side
        receiverService.onIncomingTransferRequest = (item) async {
          expect(item.fileName, 'test_payload.bin');
          expect(item.fileSizeBytes, 150 * 1024);
          return true; // Accept!
        };

        // 3. Setup sender transfer service
        final senderStorage = StorageService(customBaseDirectory: tempDir);
        final senderService = TransferService(
          localDevice: senderDevice,
          storageService: senderStorage,
        );
        final senderState = TransferState(transferService: senderService);

        // Track completion on both sides
        final receiverCompleted = Completer<TransferItem>();
        final senderCompleted = Completer<TransferItem>();

        final receiverSub = receiverService.transferUpdates.listen((item) {
          if (item.status == TransferStatus.completed) {
            if (!receiverCompleted.isCompleted) {
              receiverCompleted.complete(item);
            }
          }
        });

        final senderSub = senderService.transferUpdates.listen((item) {
          if (item.status == TransferStatus.completed) {
            if (!senderCompleted.isCompleted) {
              senderCompleted.complete(item);
            }
          }
        });

        // 4. Send file from sender to receiver
        await senderState.sendFile(targetPeer: receiverDevice, file: testFile);

        // 5. Wait for both sides to finish with timeout
        final completedSenderItem = await senderCompleted.future.timeout(
          const Duration(seconds: 10),
        );
        final completedReceiverItem = await receiverCompleted.future.timeout(
          const Duration(seconds: 10),
        );

        // 6. Assert sender completion
        expect(completedSenderItem.status, TransferStatus.completed);
        expect(completedSenderItem.bytesTransferred, 150 * 1024);
        expect(completedSenderItem.percentage, 100);

        // 7. Assert receiver completion & checksum verification
        expect(completedReceiverItem.status, TransferStatus.completed);
        expect(completedReceiverItem.checksumVerified, isTrue);
        expect(completedReceiverItem.bytesTransferred, 150 * 1024);

        // 8. Verify the received file on disk exists and matches byte-for-byte
        final receivedFile = File(completedReceiverItem.filePath);
        expect(await receivedFile.exists(), isTrue);
        final receivedBytes = await receivedFile.readAsBytes();
        expect(receivedBytes.length, randomBytes.length);
        expect(sha256.convert(receivedBytes).toString(), expectedSha256);

        // Clean up
        await receiverSub.cancel();
        await senderSub.cancel();
        receiverState.dispose();
        senderState.dispose();
        if (await receivedFile.exists()) {
          await receivedFile.delete();
        }
      },
    );

    test(
      'Transfer is declined by receiver and sender receives rejection',
      () async {
        final testFile = File('${tempDir.path}/secret_doc.txt');
        await testFile.writeAsString('Confidential data');

        final receiverService = TransferService(localDevice: receiverDevice);
        final receiverState = TransferState(transferService: receiverService);
        await receiverService.startListening(port: 53323);

        // Explicitly reject the transfer
        receiverService.onIncomingTransferRequest = (item) async {
          return false; // Reject!
        };

        final senderService = TransferService(localDevice: senderDevice);
        final senderState = TransferState(transferService: senderService);

        final senderRejectedCompleter = Completer<TransferItem>();
        final sub = senderService.transferUpdates.listen((item) {
          if (item.status == TransferStatus.rejected) {
            if (!senderRejectedCompleter.isCompleted) {
              senderRejectedCompleter.complete(item);
            }
          }
        });

        final targetWithPort = DeviceModel(
          id: receiverDevice.id,
          name: receiverDevice.name,
          ip: receiverDevice.ip,
          port: 53323,
          deviceType: receiverDevice.deviceType,
          osName: receiverDevice.osName,
        );

        await senderState.sendFile(targetPeer: targetWithPort, file: testFile);

        final rejectedItem = await senderRejectedCompleter.future.timeout(
          const Duration(seconds: 5),
        );

        expect(rejectedItem.status, TransferStatus.rejected);
        expect(rejectedItem.errorMessage, contains('declined'));

        await sub.cancel();
        receiverState.dispose();
        senderState.dispose();
      },
    );

    test('Sender cancel mid-transfer terminates connection cleanly', () async {
      // 1MB file so we can cancel mid-stream
      final testFile = File('${tempDir.path}/large_file.bin');
      await testFile.writeAsBytes(List<int>.filled(1024 * 1024, 65));

      final receiverService = TransferService(
        localDevice: receiverDevice,
        storageService: StorageService(customBaseDirectory: tempDir),
      );
      final receiverState = TransferState(transferService: receiverService);
      await receiverService.startListening(port: 53324);

      receiverService.onIncomingTransferRequest = (item) async => true;

      final senderService = TransferService(
        localDevice: senderDevice,
        storageService: StorageService(customBaseDirectory: tempDir),
      );
      final senderState = TransferState(transferService: senderService);

      final targetWithPort = DeviceModel(
        id: receiverDevice.id,
        name: receiverDevice.name,
        ip: receiverDevice.ip,
        port: 53324,
        deviceType: receiverDevice.deviceType,
        osName: receiverDevice.osName,
      );

      // Start sending asynchronously
      unawaited(
        senderState.sendFile(targetPeer: targetWithPort, file: testFile),
      );

      // Wait a tick then trigger cancel
      await Future.delayed(const Duration(milliseconds: 20));
      senderState.cancelActiveTransfer();

      expect(senderState.activeTransfer?.status, TransferStatus.cancelled);

      receiverState.dispose();
      senderState.dispose();
    });

    test(
      'StorageService filename collision resolution appends index',
      () async {
        final storage = StorageService();
        final targetFolder = Directory('${tempDir.path}/localdrop_downloads');
        await targetFolder.create(recursive: true);

        // Create an existing file
        final existingFile = File('${targetFolder.path}/photo.png');
        await existingFile.writeAsString('first photo');

        // Resolve destination for file with same name
        final resolvedPath = await storage.getUniqueDestinationPath(
          'photo.png',
          customDirectory: targetFolder,
        );

        expect(resolvedPath.endsWith('photo (1).png'), isTrue);

        // Create photo (1).png as well
        await File(resolvedPath).writeAsString('second photo');

        // Next resolution should be photo (2).png
        final resolvedPath2 = await storage.getUniqueDestinationPath(
          'photo.png',
          customDirectory: targetFolder,
        );
        expect(resolvedPath2.endsWith('photo (2).png'), isTrue);
      },
    );
  });
}
