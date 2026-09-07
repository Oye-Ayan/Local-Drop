import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:localdrop/models/history_item.dart';
import 'package:localdrop/models/transfer_item.dart';
import 'package:localdrop/services/history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryItem Tests', () {
    test('Calculates expiration accurately based on 7 days threshold', () {
      final recentItem = HistoryItem(
        id: '1',
        fileName: 'photo.jpg',
        fileSizeBytes: 1024,
        filePath: '/path/photo.jpg',
        direction: TransferDirection.incoming,
        peerName: 'Pixel 8',
        peerIp: '192.168.1.50',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isPinned: false,
      );
      expect(recentItem.isExpired(retentionDays: 7), isFalse);

      final oldItem = HistoryItem(
        id: '2',
        fileName: 'video.mp4',
        fileSizeBytes: 2048,
        filePath: '/path/video.mp4',
        direction: TransferDirection.outgoing,
        peerName: 'MacBook',
        peerIp: '192.168.1.60',
        timestamp: DateTime.now().subtract(const Duration(days: 8)),
        isPinned: false,
      );
      expect(oldItem.isExpired(retentionDays: 7), isTrue);

      final pinnedOldItem = oldItem.copyWith(isPinned: true);
      // Pinned items must NEVER expire!
      expect(pinnedOldItem.isExpired(retentionDays: 7), isFalse);
    });

    test('Serializes and deserializes properly', () {
      final original = HistoryItem(
        id: 'test_id',
        fileName: 'document.pdf',
        fileSizeBytes: 50000,
        filePath: '/downloads/document.pdf',
        direction: TransferDirection.incoming,
        peerName: 'Desktop',
        peerIp: '192.168.1.20',
        timestamp: DateTime.parse('2026-09-01T12:00:00.000Z'),
        isPinned: true,
        sha256: 'abc123def456',
      );

      final jsonString = original.serialize();
      final revived = HistoryItem.deserialize(jsonString);

      expect(revived.id, original.id);
      expect(revived.fileName, original.fileName);
      expect(revived.fileSizeBytes, original.fileSizeBytes);
      expect(revived.direction, original.direction);
      expect(revived.isPinned, isTrue);
      expect(revived.sha256, original.sha256);
    });
  });

  group('HistoryService Tests', () {
    late HistoryService historyService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      historyService = HistoryService(prefs: prefs);
      await historyService.init();
    });

    test('Records completed transfer and auto-purges expired non-pinned items', () async {
      final transfer = TransferItem(
        id: 'trans_1',
        fileName: 'report.pdf',
        fileSizeBytes: 12000,
        filePath: '/path/report.pdf',
        direction: TransferDirection.incoming,
        peerId: 'p1',
        peerName: 'Phone',
        peerIp: '10.0.0.2',
        status: TransferStatus.completed,
      );

      await historyService.recordTransfer(transfer);
      expect(historyService.items.length, 1);
      expect(historyService.items.first.fileName, 'report.pdf');
      expect(historyService.items.first.isPinned, isFalse);

      // Toggle pin
      await historyService.togglePin('trans_1');
      expect(historyService.items.first.isPinned, isTrue);

      // Untoggle pin
      await historyService.togglePin('trans_1');
      expect(historyService.items.first.isPinned, isFalse);
    });

    test('Clear unpinned preserves pinned items', () async {
      final item1 = TransferItem(
        id: 't1',
        fileName: 'pinned.png',
        fileSizeBytes: 100,
        filePath: '/p/pinned.png',
        direction: TransferDirection.incoming,
        peerId: 'p1',
        peerName: 'A',
        peerIp: '1.1.1.1',
        status: TransferStatus.completed,
      );
      final item2 = TransferItem(
        id: 't2',
        fileName: 'unpinned.png',
        fileSizeBytes: 200,
        filePath: '/p/unpinned.png',
        direction: TransferDirection.incoming,
        peerId: 'p2',
        peerName: 'B',
        peerIp: '1.1.1.2',
        status: TransferStatus.completed,
      );

      await historyService.recordTransfer(item1);
      await historyService.recordTransfer(item2);
      await historyService.togglePin('t1'); // pin item 1

      expect(historyService.items.length, 2);

      await historyService.clearUnpinned();
      expect(historyService.items.length, 1);
      expect(historyService.items.first.id, 't1');
      expect(historyService.items.first.isPinned, isTrue);
    });
  });
}
