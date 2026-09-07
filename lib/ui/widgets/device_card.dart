import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/device_model.dart';



/// Minimalist Matte Peer Device Card with Micro-Interactions
class DeviceCard extends StatefulWidget {
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
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.surfaceHover : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.primary.withValues(alpha: 0.5)
                  : AppTheme.borderDark,
              width: 1,
            ),
            boxShadow: AppTheme.microShadow,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: widget.onTap ?? widget.onSendFile,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Matte Device Avatar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCardElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            widget.device.deviceType.icon,
                            color: AppTheme.primaryLight,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Device Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.device.name,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.statusOnline,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      widget.device.ip.isNotEmpty
                                          ? '${widget.device.ip}:${widget.device.port}'
                                          : 'Connecting...',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
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
                        if (widget.device.osName.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceCardElevated,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.borderDark),
                            ),
                            child: Text(
                              widget.device.osName,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppTheme.borderSubtle),
                    const SizedBox(height: 10),

                    // Clean Minimal Action Buttons
                    Row(
                      children: [
                        // Primary: Send File
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: ElevatedButton.icon(
                              onPressed: widget.onSendFile,
                              icon: const Icon(
                                Icons.arrow_upward_rounded,
                                size: 15,
                              ),
                              label: Text(
                                'Send File',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Secondary: Clipboard Sync
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: OutlinedButton.icon(
                              onPressed: widget.onSendClipboard,
                              icon: const Icon(
                                Icons.content_paste_rounded,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              label: Text(
                                'Clipboard',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppTheme.surfaceCardElevated,
                                side: const BorderSide(color: AppTheme.borderDark),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
      ),
    )
    .animate()
    .fadeIn(duration: 200.ms)
    .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
  }
}
