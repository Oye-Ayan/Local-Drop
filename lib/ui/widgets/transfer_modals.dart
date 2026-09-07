import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/constants/protocol_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transfer_item.dart';
import '../../state/transfer_state.dart';



/// Minimalist Matte Incoming File Transfer Request Dialog
class IncomingTransferDialog extends StatelessWidget {
  final TransferState transferState;

  const IncomingTransferDialog({super.key, required this.transferState});

  @override
  Widget build(BuildContext context) {
    final item = transferState.incomingPrompt;
    if (item == null) return const SizedBox.shrink();

    final countdown = transferState.countdownSeconds;
    final progressVal =
        (countdown / ProtocolConstants.transferPromptTimeoutSeconds).clamp(
          0.0,
          1.0,
        );

    return Dialog(
      backgroundColor: AppTheme.surfaceCardElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderDark, width: 1.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardElevation,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Countdown Ring with Download Icon
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: progressVal,
                    strokeWidth: 3.0,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surfaceDark,
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: AppTheme.primaryLight,
                    size: 24,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              'Incoming File Transfer',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            Text(
              'From ${item.peerName} (${item.peerIp})',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // File Info Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.insert_drive_file_rounded,
                      color: AppTheme.primaryLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.fileName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.formattedSize,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Auto-rejects in ${countdown}s',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => transferState.rejectIncoming(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.borderDark),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Decline',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => transferState.acceptIncoming(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Accept',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().scale(
      begin: const Offset(0.96, 0.96),
      end: const Offset(1, 1),
      duration: 160.ms,
      curve: Curves.easeOutCubic,
    );
  }
}

/// Minimalist Matte Active Transfer Progress Modal
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
    } else if (item.status == TransferStatus.failed ||
        item.status == TransferStatus.rejected) {
      statusColor = AppTheme.statusError;
      statusIcon = Icons.error_rounded;
    } else if (item.status == TransferStatus.cancelled) {
      statusColor = AppTheme.statusBusy;
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = item.direction.isOutgoing
          ? AppTheme.primaryLight
          : AppTheme.secondary;
      statusIcon = item.direction.isOutgoing
          ? Icons.arrow_upward_rounded
          : Icons.arrow_downward_rounded;
    }

    return Dialog(
      backgroundColor: AppTheme.surfaceCardElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderDark, width: 1.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardElevation,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.direction.isOutgoing
                            ? 'Sending File'
                            : 'Receiving File',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.peerName} (${item.peerIp})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // File Details & Linear Progress Bar
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
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${item.formattedTransferred} / ${item.formattedSize}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${item.percentage}%',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
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

            // Live Metrics (Speed & ETA)
            if (!isDone)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.speed_rounded,
                        size: 14,
                        color: AppTheme.primaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.formattedSpeed,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (item.eta != null)
                    Text(
                      '${item.eta!.inSeconds}s remaining',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isSuccess
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isSuccess
                            ? 'Transfer completed successfully'
                            : (item.errorMessage ?? 'Transfer ended'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Modal Action Buttons
            Row(
              children: [
                if (!isDone)
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: Text(
                          'Cancel Transfer',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.statusError,
                          side: const BorderSide(
                            color: AppTheme.statusError,
                            width: 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  )
                else ...[
                  if (isSuccess && item.filePath.isNotEmpty) ...[
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: () => OpenFilex.open(item.filePath),
                          icon: const Icon(Icons.folder_open_rounded, size: 16),
                          label: Text(
                            'Open File',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(
                              color: AppTheme.borderDark,
                              width: 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: onDismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Done',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 160.ms);
  }
}

/// Minimalist Horizontal Drawer / Action Card for Active Transfers
/// Features smooth linear progress, transfer speed (MB/s), and instant action buttons
class TransferDrawer extends StatelessWidget {
  final TransferItem item;
  final VoidCallback onCancel;
  final VoidCallback onDismiss;

  const TransferDrawer({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark, width: 1),
        boxShadow: AppTheme.cardElevation,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.direction.isOutgoing
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.peerName} • ${item.formattedTransferred} of ${item.formattedSize} (${item.formattedSpeed})',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isDone)
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppTheme.textSecondary,
                  tooltip: 'Cancel',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                )
              else if (isSuccess && item.filePath.isNotEmpty)
                TextButton(
                  onPressed: () => OpenFilex.open(item.filePath),
                  child: Text(
                    'Open',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  color: AppTheme.statusOnline,
                  tooltip: 'Dismiss',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

