import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localdrop/core/constants/protocol_constants.dart';
import 'package:localdrop/core/theme/app_theme.dart';
import 'package:localdrop/core/utils/formatters.dart';
import 'package:localdrop/models/device_model.dart';
import 'package:localdrop/models/transfer_item.dart';
import 'package:localdrop/services/transfer_service.dart';
import 'package:localdrop/state/discovery_state.dart';
import 'package:localdrop/state/transfer_state.dart';
import 'package:localdrop/ui/screens/discovery_screen.dart';
import 'package:localdrop/ui/widgets/device_card.dart';
import 'package:localdrop/ui/widgets/radar_pulse.dart';
import 'package:localdrop/ui/widgets/transfer_modals.dart';

void main() {
  group('DeviceModel Tests', () {
    test('DeviceModel serializes and deserializes correctly', () {
      final device = DeviceModel(
        id: 'device-123',
        name: 'Pixel 8',
        ip: '192.168.1.50',
        port: 53317,
        deviceType: DeviceType.phone,
        osName: 'Android',
      );

      final json = device.toJson();
      expect(json['id'], 'device-123');
      expect(json['name'], 'Pixel 8');
      expect(json['ip'], '192.168.1.50');
      expect(json['deviceType'], 'phone');

      final fromJson = DeviceModel.fromJson(json);
      expect(fromJson.id, device.id);
      expect(fromJson.name, device.name);
      expect(fromJson.ip, device.ip);
      expect(fromJson.deviceType, DeviceType.phone);
      expect(fromJson.osName, 'Android');
    });

    test('DeviceType parses from string correctly', () {
      expect(DeviceType.fromString('phone'), DeviceType.phone);
      expect(DeviceType.fromString('android'), DeviceType.phone);
      expect(DeviceType.fromString('desktop'), DeviceType.desktop);
      expect(DeviceType.fromString('linux'), DeviceType.desktop);
      expect(DeviceType.fromString('unknown_device'), DeviceType.unknown);
    });
  });

  group('Phase 2: TransferItem & Protocol Tests', () {
    test('TransferItem serializes and deserializes properly', () {
      final item = TransferItem(
        id: 'tx-001',
        fileName: 'presentation.pdf',
        fileSizeBytes: 10485760, // 10 MB
        filePath: '/storage/presentation.pdf',
        peerId: 'peer-1',
        peerName: 'Work Laptop',
        peerIp: '192.168.1.20',
        direction: TransferDirection.outgoing,
        status: TransferStatus.inProgress,
        bytesTransferred: 5242880, // 5 MB
        speedBytesPerSec: 1048576, // 1 MB/s
        sha256Checksum:
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );

      expect(item.percentage, 50);
      expect(item.progress, closeTo(0.5, 0.01));
      expect(item.formattedSize, contains('MB'));
      expect(item.formattedSpeed, contains('MB/s'));

      final json = item.toJson();
      expect(json['id'], 'tx-001');
      expect(json['fileName'], 'presentation.pdf');
      expect(json['direction'], 'outgoing');

      final restored = TransferItem.fromJson(json);
      expect(restored.id, item.id);
      expect(restored.fileName, item.fileName);
      expect(restored.fileSizeBytes, item.fileSizeBytes);
      expect(restored.peerName, 'Work Laptop');
    });

    test('Formatters test bytes, speed and ETA', () {
      expect(Formatters.formatBytes(500), '500 B');
      expect(Formatters.formatBytes(1024), '1.0 KB');
      expect(Formatters.formatBytes(10485760), '10 MB');
      expect(Formatters.formatSpeed(2097152), '2.0 MB/s');
      expect(Formatters.formatEta(const Duration(seconds: 30)), '30s');
      expect(Formatters.formatEta(const Duration(seconds: 125)), '2m 5s');
    });

    test('ProtocolFrame encode produces expected format', () {
      final payload = utf8.encode('{"hello":"world"}');
      final encoded = ProtocolFrame.encode(
        ProtocolConstants.msgTransferRequest,
        payload,
      );

      expect(encoded[0], ProtocolConstants.msgTransferRequest);
      final view = ByteData.view(encoded.buffer);
      final len = view.getUint32(1, Endian.big);
      expect(len, payload.length);
      expect(encoded.sublist(5), payload);
    });

    test('FrameDecoder extracts complete frames across chunk boundaries', () {
      final decoder = FrameDecoder();
      final payload1 = utf8.encode('{"frame":1}');
      final payload2 = utf8.encode('{"frame":2}');

      final frame1Bytes = ProtocolFrame.encode(
        ProtocolConstants.msgTransferRequest,
        payload1,
      );
      final frame2Bytes = ProtocolFrame.encode(
        ProtocolConstants.msgFileChunk,
        payload2,
      );

      // Feed half of frame 1
      final half = frame1Bytes.length ~/ 2;
      final result1 = decoder.feed(frame1Bytes.sublist(0, half));
      expect(result1, isEmpty);

      // Feed remaining of frame 1 + all of frame 2 together
      final combined = <int>[...frame1Bytes.sublist(half), ...frame2Bytes];
      final result2 = decoder.feed(combined);

      expect(result2.length, 2);
      expect(result2[0].opCode, ProtocolConstants.msgTransferRequest);
      expect(utf8.decode(result2[0].payload), '{"frame":1}');
      expect(result2[1].opCode, ProtocolConstants.msgFileChunk);
      expect(utf8.decode(result2[1].payload), '{"frame":2}');
    });
  });

  group('Phase 2: UI Responsive & Modal Verification Tests', () {
    testWidgets(
      'DeviceCard displays device info and action buttons without overflow on 320px width',
      (tester) async {
        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final peer = DeviceModel(
          id: 'peer-99',
          name: 'Work MacBook Pro Long Name',
          ip: '192.168.1.88',
          port: 53317,
          deviceType: DeviceType.desktop,
          osName: 'macOS',
        );

        bool sendFileTapped = false;
        bool sendClipboardTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: DeviceCard(
                device: peer,
                onSendFile: () => sendFileTapped = true,
                onSendClipboard: () => sendClipboardTapped = true,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Work MacBook Pro Long Name'), findsOneWidget);
        expect(find.text('192.168.1.88:53317'), findsOneWidget);
        expect(find.text('macOS'), findsOneWidget);
        expect(find.text('Send File'), findsOneWidget);
        expect(find.text('Clipboard'), findsOneWidget);

        await tester.tap(find.text('Send File'));
        expect(sendFileTapped, isTrue);

        await tester.tap(find.text('Clipboard'));
        expect(sendClipboardTapped, isTrue);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'IncomingTransferDialog renders cleanly without overflow on 320px screen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final local = DeviceModel(
          id: 'local-1',
          name: 'My Phone',
          ip: '192.168.1.10',
          port: 53317,
          deviceType: DeviceType.phone,
          osName: 'Android',
        );

        final service = TransferService(localDevice: local);
        final state = TransferState(transferService: service);

        // Inject simulated incoming request
        final item = TransferItem(
          id: 'tx-req-1',
          fileName: 'Quarterly_Report_2026_Final_Draft.pdf',
          fileSizeBytes: 45000000, // 45 MB
          filePath: '/mock/path/Quarterly_Report_2026_Final_Draft.pdf',
          peerId: 'peer-2',
          peerName: 'Sarah\'s MacBook Pro (Ultra Long Name)',
          peerIp: '192.168.1.55',
          direction: TransferDirection.incoming,
        );

        service.onIncomingTransferRequest!(item);
        await tester.pump();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(body: IncomingTransferDialog(transferState: state)),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Incoming File Transfer'), findsOneWidget);
        expect(
          find.text('Quarterly_Report_2026_Final_Draft.pdf'),
          findsOneWidget,
        );
        expect(find.text('Accept'), findsOneWidget);
        expect(find.text('Decline'), findsOneWidget);

        // Verify zero RenderFlex overflow
        expect(tester.takeException(), isNull);

        state.dispose();
      },
    );

    testWidgets(
      'TransferProgressModal renders progress and speed without overflow on 320px screen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final item = TransferItem(
          id: 'tx-active-1',
          fileName: 'Large_Archive_Dataset.zip',
          fileSizeBytes: 100000000, // 100 MB
          filePath: '/mock/Large_Archive_Dataset.zip',
          peerId: 'peer-2',
          peerName: 'Workstation Extreme',
          peerIp: '192.168.1.20',
          direction: TransferDirection.outgoing,
          status: TransferStatus.inProgress,
          bytesTransferred: 45000000,
          speedBytesPerSec: 5242880, // 5 MB/s
        );

        bool cancelTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: TransferProgressModal(
                item: item,
                onCancel: () => cancelTapped = true,
                onDismiss: () {},
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Large_Archive_Dataset.zip'), findsOneWidget);
        expect(find.text('Sending File'), findsOneWidget);
        expect(find.text('Workstation Extreme (192.168.1.20)'), findsOneWidget);
        expect(find.text('Cancel Transfer'), findsOneWidget);

        await tester.tap(find.text('Cancel Transfer'));
        expect(cancelTapped, isTrue);

        // Verify zero overflow
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'DiscoveryScreen renders populated peers list without any overflow on 320x480 screen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final state = DiscoveryState(
          enableNetwork: false,
          initialLocalDevice: DeviceModel(
            id: 'self-1',
            name: 'Local Machine',
            ip: '192.168.1.100',
            port: 53317,
            deviceType: DeviceType.desktop,
            osName: 'Linux',
            isSelf: true,
          ),
          initialPeers: [
            DeviceModel(
              id: 'peer-1',
              name: 'Infinix NOTE 7 Lite',
              ip: '192.168.1.105',
              port: 53317,
              deviceType: DeviceType.phone,
              osName: 'Android',
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: DiscoveryScreen(discoveryState: state),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.widgetWithText(DeviceCard, 'Infinix NOTE 7 Lite'), findsOneWidget);
        expect(find.text('192.168.1.105:53317'), findsOneWidget);
        expect(find.text('Send File'), findsOneWidget);
        expect(find.text('Clipboard'), findsOneWidget);

        // Verify no layout overflow exception
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('RadarPulse renders without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RadarPulse(size: 130))),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(RadarPulse), findsOneWidget);
      expect(find.byIcon(Icons.wifi_tethering_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
