import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/transfer_item.dart';

/// Clean Active Transfer Bar showing live progress, speed, and actions
class ActiveTransferBar extends StatelessWidget {
  final TransferItem item;
  final VoidCallback onCancel;
  final VoidCallback onDismiss;

  const ActiveTransferBar({
    super.key,
    required this.item,
    required this.onCancel,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = item.status.isDone;
    final isSuccess = item.status.isSuccess;

    Color statusColor = item.status == TransferStatus.completed
        ? AppTheme.statusOnline
        : (item.status == TransferStatus.failed || item.status == TransferStatus.rejected
            ? AppTheme.statusError
            : AppTheme.primary);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCardElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                item.direction.isOutgoing ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: statusColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${item.formattedTransferred} / ${item.formattedSize} • ${item.formattedSpeed}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (!isDone)
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: AppTheme.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                )
              else if (isSuccess && item.filePath.isNotEmpty)
                TextButton(
                  onPressed: () => OpenFilex.open(item.filePath),
                  child: Text('Open', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryLight)),
                )
              else
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  color: AppTheme.statusOnline,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: item.progress.clamp(0.0, 1.0),
              minHeight: 3.5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
