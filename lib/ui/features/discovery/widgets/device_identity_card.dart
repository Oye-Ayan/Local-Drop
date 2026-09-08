import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/device_model.dart';

/// Clean host identity header card showing device name, IP, and web portal status
class DeviceIdentityCard extends StatelessWidget {
  final DeviceModel local;
  final bool isWebSharingActive;
  final String? webPortalUrl;
  final VoidCallback onEditName;
  final VoidCallback onWebShareTap;

  const DeviceIdentityCard({
    super.key,
    required this.local,
    required this.isWebSharingActive,
    this.webPortalUrl,
    required this.onEditName,
    required this.onWebShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final ipText = local.ip.isNotEmpty ? '${local.ip}:${local.port}' : 'Connecting...';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          // Green Status Dot
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.statusOnline,
            ),
          ),
          const SizedBox(width: 10),

          // Device Name & IP
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        local.name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onEditName,
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.all(3),
                        child: Icon(Icons.edit_outlined, size: 13, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
                Text(
                  ipText,
                  style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          // Active Web Portal Chip (if sharing)
          if (isWebSharingActive)
            InkWell(
              onTap: onWebShareTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language_rounded, size: 11, color: AppTheme.primaryLight),
                    const SizedBox(width: 5),
                    Text(
                      'Web Live',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryLight),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
