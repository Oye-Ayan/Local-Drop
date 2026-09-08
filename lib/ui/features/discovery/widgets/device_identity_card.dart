import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/device_model.dart';

/// Device identity card matching the screenshot design:
/// - Centered status pill: "• Connected • IP:Port"
/// - Centered device name with edit pencil
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
    final ipText = local.ip.isNotEmpty ? '${local.ip}:${local.port}' : '127.0.0.1:${local.port}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Centered Connection Status Pill
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF131D2D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'Connected • $ipText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Web Portal Live Pill (if active)
          if (isWebSharingActive) ...[
            const SizedBox(height: 6),
            Center(
              child: InkWell(
                onTap: onWebShareTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language_rounded, size: 12, color: AppTheme.primaryLight),
                      const SizedBox(width: 4),
                      Text(
                        'Web Drop Active',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),

          // 2. Centered Device Name with Edit Pencil
          Center(
            child: InkWell(
              onTap: onEditName,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        local.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
