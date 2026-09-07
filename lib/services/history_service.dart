import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';
import '../models/transfer_item.dart';

class HistoryService extends ChangeNotifier {
  static const String _storageKey = 'localdrop_transfer_history_v1';
  static const int defaultRetentionDays = 7;

  final SharedPreferences? _prefs;
  List<HistoryItem> _items = [];

  HistoryService({SharedPreferences? prefs}) : _prefs = prefs;

  List<HistoryItem> get items => List.unmodifiable(_items);

  /// Initializes history and automatically purges unpinned entries older than 7 days
  Future<void> init() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];

    final loaded = <HistoryItem>[];
    for (final entry in raw) {
      try {
        final item = HistoryItem.deserialize(entry);
        // Retain if not expired or pinned by user
        if (!item.isExpired(retentionDays: defaultRetentionDays)) {
          loaded.add(item);
        }
      } catch (_) {}
    }

    _items = loaded;
    // Sort descending (most recent first)
    _items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _persist(prefs);
    notifyListeners();
  }

  /// Adds a completed transfer item to history
  Future<void> recordTransfer(TransferItem transfer) async {
    if (transfer.status != TransferStatus.completed) return;

    final historyItem = HistoryItem.fromTransferItem(transfer);

    // Remove existing item with same id if already present
    _items.removeWhere((it) => it.id == historyItem.id);
    _items.insert(0, historyItem);

    // Auto-prune items older than 7 days (preserving pinned)
    _items.removeWhere(
      (it) => it.isExpired(retentionDays: defaultRetentionDays),
    );

    await _persist();
    notifyListeners();
  }

  /// Toggles the "Keep Forever" pin state of a history item
  Future<void> togglePin(String id) async {
    final idx = _items.indexWhere((it) => it.id == id);
    if (idx != -1) {
      final cur = _items[idx];
      _items[idx] = cur.copyWith(isPinned: !cur.isPinned);
      await _persist();
      notifyListeners();
    }
  }

  /// Manually deletes a single history record
  Future<void> deleteItem(String id) async {
    _items.removeWhere((it) => it.id == id);
    await _persist();
    notifyListeners();
  }

  /// Clears all unpinned history items (leaves pinned items intact)
  Future<void> clearUnpinned() async {
    _items.removeWhere((it) => !it.isPinned);
    await _persist();
    notifyListeners();
  }

  /// Clears all history
  Future<void> clearAll() async {
    _items.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist([SharedPreferences? customPrefs]) async {
    try {
      final prefs = customPrefs ?? _prefs ?? await SharedPreferences.getInstance();
      final serialized = _items.map((it) => it.serialize()).toList();
      await prefs.setStringList(_storageKey, serialized);
    } catch (_) {}
  }
}
