import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Bottom action area matching the screenshot:
/// "Drop files here or tap to broadcast" with lossless SHA-256 badge
class ActionDock extends StatelessWidget {
  final VoidCallback onSendFiles;
  final VoidCallback onWebShare;
  final bool isWebPortalLive;

  const ActionDock({
    super.key,
    required this.onSendFiles,
    required this.onWebShare,
    this.isWebPortalLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      color: AppTheme.bgDark,
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: onSendFiles,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF131B2A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1F2C42)),
              boxShadow: AppTheme.microShadow,
            ),
            child: Row(
              children: [
                // Squircle Upload Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A253A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.file_upload_outlined,
                    color: AppTheme.primaryLight,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Broadcast & Integrity Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Drop files here or tap to broadcast',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '100% Lossless Original Quality • Bit-for-bit SHA-256',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryLight.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
