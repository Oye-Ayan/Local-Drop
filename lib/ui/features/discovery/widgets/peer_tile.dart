import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/device_model.dart';

/// Industrial-standard clean device tile for discovered network peers
class PeerTile extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback? onSendFile;
  final VoidCallback? onSendClipboard;

  const PeerTile({
    super.key,
    required this.device,
    this.onSendFile,
    this.onSendClipboard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
        boxShadow: AppTheme.microShadow,
      ),
      child: Row(
        children: [
          // Device Type Icon Container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Icon(
              device.deviceType.icon,
              color: AppTheme.textPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Device Name & Subtitle Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  device.ip.isNotEmpty ? '${device.ip}:${device.port}' : 'Nearby Peer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Clipboard Action Button
          if (onSendClipboard != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.textSecondary),
              tooltip: 'Send Clipboard',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onSendClipboard,
            ),

          // Primary Send Action Button
          ElevatedButton(
            onPressed: onSendFile,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(60, 32),
              textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
