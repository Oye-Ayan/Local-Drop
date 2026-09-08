import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/history_item.dart';
import '../../../../models/transfer_item.dart';
import '../../../../services/history_service.dart';

/// Clean Transfer History Modal with 7-day retention and pin-to-keep
class HistoryModal extends StatefulWidget {
  final HistoryService historyService;

  const HistoryModal({super.key, required this.historyService});

  static void show(BuildContext context, HistoryService historyService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HistoryModal(historyService: historyService),
    );
  }

  @override
  State<HistoryModal> createState() => _HistoryModalState();
}

class _HistoryModalState extends State<HistoryModal> {
  bool _showOnlyPinned = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.historyService,
      builder: (context, _) {
        final allItems = widget.historyService.items;
        final displayItems = _showOnlyPinned
            ? allItems.where((it) => it.isPinned).toList()
            : allItems;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceCardDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTheme.borderDark)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.borderDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 14, 8),
                child: Row(
                  children: [
                    Text(
                      'Transfer History',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    const Spacer(),
                    if (allItems.isNotEmpty)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz_rounded, size: 18, color: AppTheme.textSecondary),
                        color: AppTheme.surfaceCardElevated,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppTheme.borderDark)),
                        onSelected: (val) {
                          if (val == 'clear_unpinned') widget.historyService.clearUnpinned();
                          if (val == 'clear_all') widget.historyService.clearAll();
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'clear_unpinned',
                            child: Text('Clear Unpinned', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary)),
                          ),
                          PopupMenuItem(
                            value: 'clear_all',
                            child: Text('Clear All', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.statusError)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilterChip(
                      selected: !_showOnlyPinned,
                      label: Text('All (${allItems.length})'),
                      labelStyle: GoogleFonts.inter(fontSize: 11, color: !_showOnlyPinned ? AppTheme.textInverse : AppTheme.textSecondary),
                      backgroundColor: AppTheme.surfaceDark,
                      selectedColor: AppTheme.primary,
                      onSelected: (_) => setState(() => _showOnlyPinned = false),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _showOnlyPinned,
                      label: Text('Pinned (${allItems.where((i) => i.isPinned).length})'),
                      labelStyle: GoogleFonts.inter(fontSize: 11, color: _showOnlyPinned ? AppTheme.textInverse : AppTheme.textSecondary),
                      backgroundColor: AppTheme.surfaceDark,
                      selectedColor: AppTheme.statusBusy,
                      onSelected: (_) => setState(() => _showOnlyPinned = true),
                    ),
                  ],
                ),
              ),
              const Divider(height: 12, color: AppTheme.borderSubtle),
              Flexible(
                child: displayItems.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _showOnlyPinned ? 'No pinned transfers yet' : 'No transfers recorded yet',
                            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: displayItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (ctx, i) => _buildItemTile(displayItems[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemTile(HistoryItem item) {
    final isIncoming = item.direction == TransferDirection.incoming;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.isPinned ? AppTheme.statusBusy.withValues(alpha: 0.3) : AppTheme.borderDark),
      ),
      child: Row(
        children: [
          Icon(isIncoming ? Icons.south_west_rounded : Icons.north_east_rounded, size: 16, color: isIncoming ? AppTheme.primary : AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text('${Formatters.formatBytes(item.fileSizeBytes)} • ${item.peerName}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(item.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, size: 16, color: item.isPinned ? AppTheme.statusBusy : AppTheme.textMuted),
            onPressed: () => widget.historyService.togglePin(item.id),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
          if (item.filePath.isNotEmpty && File(item.filePath).existsSync())
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, size: 16, color: AppTheme.primaryLight),
              onPressed: () => OpenFilex.open(item.filePath),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 14, color: AppTheme.textMuted),
            onPressed: () => widget.historyService.deleteItem(item.id),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
