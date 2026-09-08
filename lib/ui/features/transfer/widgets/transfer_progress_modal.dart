import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/transfer_item.dart';

/// Clean Modal showing transfer progress, speed, ETA, and completion actions
class TransferProgressModal extends StatelessWidget {
  final TransferItem item;
  final VoidCallback onCancel;
  final VoidCallback onDismiss;

  const TransferProgressModal({
    super.key,
    required this.item,
    required this.onCancel,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = item.status.isDone;
    final isSuccess = item.status.isSuccess;

    Color statusColor;
    IconData statusIcon;

    if (item.status == TransferStatus.completed) {
      statusColor = AppTheme.statusOnline;
      statusIcon = Icons.check_circle_rounded;
    } else if (item.status == TransferStatus.failed || item.status == TransferStatus.rejected) {
      statusColor = AppTheme.statusError;
      statusIcon = Icons.error_rounded;
    } else if (item.status == TransferStatus.cancelled) {
      statusColor = AppTheme.statusBusy;
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = item.direction.isOutgoing ? AppTheme.primaryLight : AppTheme.secondary;
      statusIcon = item.direction.isOutgoing ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    }

    return Dialog(
      backgroundColor: AppTheme.surfaceCardElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderDark),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.direction.isOutgoing ? 'Sending File' : 'Receiving File',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.peerName} (${item.peerIp})',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.formattedTransferred} / ${item.formattedSize}',
                          style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.percentage}%',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.progress.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!isDone)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.speed_rounded, size: 14, color: AppTheme.primaryLight),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.formattedSpeed,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.eta != null)
                    Text('${item.eta!.inSeconds}s remaining', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              )
            else
              Text(
                isSuccess ? 'Transfer completed' : (item.errorMessage ?? 'Transfer ended'),
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: statusColor),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (!isDone)
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.statusError,
                          side: const BorderSide(color: AppTheme.statusError),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Cancel Transfer', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  )
                else ...[
                  if (isSuccess && item.filePath.isNotEmpty) ...[
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          onPressed: () => OpenFilex.open(item.filePath),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(color: AppTheme.borderDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Open File', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: onDismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Done', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
