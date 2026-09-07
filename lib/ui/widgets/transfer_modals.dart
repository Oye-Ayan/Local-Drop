import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/constants/protocol_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transfer_item.dart';
import '../../state/transfer_state.dart';

/// Ultra-Premium Agency-Tier Incoming File Transfer Request Modal
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
      backgroundColor: AppTheme.surfaceCardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppTheme.borderDark, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Glowing Circular Countdown Ring with Beacon Icon
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 66,
                  height: 66,
                  child: CircularProgressIndicator(
                    value: progressVal,
                    strokeWidth: 3.5,
                    backgroundColor: AppTheme.borderDark,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.25),
                        AppTheme.secondary.withValues(alpha: 0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: AppTheme.primaryLight,
                    size: 26,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              'Incoming File Transfer',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            Text(
              'From ${item.peerName} (${item.peerIp})',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Double-Bezel File Info Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.insert_drive_file_rounded,
                      color: AppTheme.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.fileName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.formattedSize,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons Row (Equal Expansion to Prevent Overflows)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton(
                      onPressed: () => transferState.rejectIncoming(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(
                          color: AppTheme.borderDark,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Decline',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => transferState.acceptIncoming(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Accept',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textInverse,
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
      begin: const Offset(0.95, 0.95),
      end: const Offset(1, 1),
      duration: 180.ms,
      curve: Curves.easeOutCubic,
    );
  }
}

/// Ultra-Premium Agency-Tier Active Transfer Progress Modal
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
      backgroundColor: AppTheme.surfaceCardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppTheme.borderDark, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row with Machined Status Badge & Title
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.direction.isOutgoing
                            ? 'Sending File'
                            : 'Receiving File',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.peerName} (${item.peerIp})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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

            // File Details Double-Bezel Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${item.percentage}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // High-End Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: item.progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppTheme.borderDark,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Live Metrics (Speed & ETA) or Verified Status
            if (!isDone)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: AppTheme.primaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.formattedSpeed,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (item.eta != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.eta!.inSeconds}s remaining',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
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
                          ? Icons.verified_user_rounded
                          : Icons.info_outline_rounded,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isSuccess
                            ? 'SHA-256 Verified • Saved successfully'
                            : (item.errorMessage ?? 'Transfer ended'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 18),

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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.statusError,
                          side: const BorderSide(
                            color: AppTheme.statusError,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(
                              color: AppTheme.borderDark,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Done',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textInverse,
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
    ).animate().fadeIn(duration: 180.ms);
  }
}
