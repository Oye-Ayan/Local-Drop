import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/history_item.dart';
import '../../models/transfer_item.dart';
import '../../services/history_service.dart';

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

  String _formatRelativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.historyService,
      builder: (context, _) {
        final allItems = widget.historyService.items;
        final displayItems = _showOnlyPinned
            ? allItems.where((it) => it.isPinned).toList()
            : allItems;

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppTheme.borderDark)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.borderDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transfer History',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              '${allItems.length} transfers recorded',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (allItems.isNotEmpty)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz_rounded, color: AppTheme.textSecondary),
                            color: AppTheme.surfaceCardDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppTheme.borderDark),
                            ),
                            onSelected: (val) {
                              if (val == 'clear_unpinned') {
                                widget.historyService.clearUnpinned();
                              } else if (val == 'clear_all') {
                                widget.historyService.clearAll();
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'clear_unpinned',
                                child: Text(
                                  'Clear Unpinned',
                                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'clear_all',
                                child: Text(
                                  'Clear All History',
                                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.statusError),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // 7-Day Auto-Purge & Lossless Policy Banner
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '100% Lossless • Transfers auto-delete in 7 days unless pinned 📌',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        FilterChip(
                          selected: !_showOnlyPinned,
                          label: Text('All (${allItems.length})'),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: !_showOnlyPinned ? AppTheme.textInverse : AppTheme.textSecondary,
                          ),
                          backgroundColor: AppTheme.surfaceDark,
                          selectedColor: AppTheme.primary,
                          side: BorderSide(
                            color: !_showOnlyPinned ? AppTheme.primary : AppTheme.borderDark,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onSelected: (_) => setState(() => _showOnlyPinned = false),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: _showOnlyPinned,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.push_pin_rounded,
                                size: 13,
                                color: _showOnlyPinned ? AppTheme.textInverse : AppTheme.statusBusy,
                              ),
                              const SizedBox(width: 4),
                              Text('Keep Forever (${allItems.where((i) => i.isPinned).length})'),
                            ],
                          ),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _showOnlyPinned ? AppTheme.textInverse : AppTheme.textSecondary,
                          ),
                          backgroundColor: AppTheme.surfaceDark,
                          selectedColor: AppTheme.statusBusy,
                          side: BorderSide(
                            color: _showOnlyPinned ? AppTheme.statusBusy : AppTheme.borderDark,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onSelected: (_) => setState(() => _showOnlyPinned = true),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: AppTheme.borderSubtle, height: 1),

                  // List
                  Expanded(
                    child: displayItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _showOnlyPinned
                                      ? Icons.push_pin_outlined
                                      : Icons.folder_open_rounded,
                                  size: 44,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _showOnlyPinned
                                      ? 'No pinned transfers yet'
                                      : 'No transfer history yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _showOnlyPinned
                                      ? 'Pin items to prevent them from auto-deleting after 7 days.'
                                      : 'Completed transfers will be safely logged here.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: displayItems.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = displayItems[index];
                              return _buildHistoryCard(context, item);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryCard(BuildContext context, HistoryItem item) {
    final isIncoming = item.direction == TransferDirection.incoming;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isPinned ? AppTheme.statusBusy.withValues(alpha: 0.35) : AppTheme.borderDark,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.surfaceCardElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Icon(item.icon, color: AppTheme.primaryLight, size: 22),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isIncoming ? Icons.south_west_rounded : Icons.north_east_rounded,
                      size: 11,
                      color: isIncoming ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        '${Formatters.formatBytes(item.fileSizeBytes)} • ${item.peerName}',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${_formatRelativeDate(item.timestamp)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pin toggle ("Keep Forever")
              IconButton(
                icon: Icon(
                  item.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  size: 18,
                  color: item.isPinned ? AppTheme.statusBusy : AppTheme.textMuted,
                ),
                tooltip: item.isPinned ? 'Pinned (Keep Forever)' : 'Pin (Keep Forever)',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () => widget.historyService.togglePin(item.id),
              ),

              // Open file
              if (item.filePath.isNotEmpty && File(item.filePath).existsSync())
                IconButton(
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: AppTheme.primaryLight,
                  ),
                  tooltip: 'Open File',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () => OpenFilex.open(item.filePath),
                ),

              // Delete entry
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
                tooltip: 'Delete Record',
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
                onPressed: () => widget.historyService.deleteItem(item.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
