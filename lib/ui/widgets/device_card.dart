import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/device_model.dart';

/// Machined Double-Bezel (Doppelrand) Device Card with Button-in-Button CTA
class DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback? onSendFile;
  final VoidCallback? onSendClipboard;
  final VoidCallback? onTap;

  const DeviceCard({
    super.key,
    required this.device,
    this.onSendFile,
    this.onSendClipboard,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Outer Bezel Shell
    return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.borderDark, width: 1),
          ),
          // 2. Inner Machined Core
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceCardDark,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: AppTheme.borderSubtle, width: 1),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(19),
              child: InkWell(
                onTap: onTap ?? onSendFile,
                borderRadius: BorderRadius.circular(19),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Ethereal Avatar with subtle gradient & glow
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primary.withValues(alpha: 0.18),
                                  AppTheme.secondary.withValues(alpha: 0.10),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              device.deviceType.icon,
                              color: AppTheme.primaryLight,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Device Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    // Pulsing online aura
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.statusOnline,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.statusOnline
                                                .withValues(alpha: 0.6),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        device.ip.isNotEmpty
                                            ? '${device.ip}:${device.port}'
                                            : 'Connecting...',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // OS Badge
                          if (device.osName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.borderDark),
                              ),
                              child: Text(
                                device.osName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSubheading,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppTheme.borderSubtle),
                      const SizedBox(height: 12),

                      // Button-in-Button Action Row (Equally expanded to ensure 0 overflow)
                      Row(
                        children: [
                          // 1. Primary CTA: Send File with nested circular trailing arrow
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onSendFile,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.25,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Send File',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: AppTheme.textInverse,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            letterSpacing: 0.1,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: AppTheme.textInverse
                                              .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.arrow_upward_rounded,
                                          size: 14,
                                          color: AppTheme.textInverse,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 2. Secondary CTA: Clipboard Sync with nested trailing icon
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onSendClipboard,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceDark,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.borderDark,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Clipboard',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.08,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.content_paste_rounded,
                                          size: 13,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
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
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }
}
