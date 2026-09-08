import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/device_model.dart';

/// Industrial-standard clean device card matching the screenshot design:
/// - Top row: Squircle device icon, Device Name, Green Dot + IP:Port, and OS badge pill
/// - Bottom row: Solid teal "Send File" primary button and dark "Clipboard" action button
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

  IconData _resolveDeviceIcon(DeviceType type, String? osName) {
    final os = (osName ?? '').toLowerCase();
    if (os.contains('mac') || os.contains('darwin')) {
      return Icons.laptop_mac_rounded;
    } else if (os.contains('win')) {
      return Icons.laptop_windows_rounded;
    } else if (os.contains('linux')) {
      return Icons.computer_rounded;
    } else if (type == DeviceType.phone || os.contains('android') || os.contains('ios')) {
      return Icons.phone_android_rounded;
    } else if (type == DeviceType.tablet) {
      return Icons.tablet_mac_rounded;
    }
    return device.deviceType.icon;
  }

  @override
  Widget build(BuildContext context) {
    final ipText = device.ip.isNotEmpty ? '${device.ip}:${device.port}' : 'Nearby';
    final osDisplay = device.osName.isNotEmpty ? device.osName : 'Device';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2C42)),
        boxShadow: AppTheme.microShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Icon + Name & IP + OS Badge
          Row(
            children: [
              // Squircle Device Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A253A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                ),
                child: Icon(
                  _resolveDeviceIcon(device.deviceType, device.osName),
                  color: AppTheme.primaryLight,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),

              // Device Name & Status/IP
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            ipText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // OS Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2838),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(
                  osDisplay,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8E9BAE),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Bottom Row: Action Buttons (Responsive & Overflow-proof)
          Row(
            children: [
              // Primary "Send File" Button
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: onSendFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.bgDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_upward_rounded, size: 15, color: AppTheme.bgDark),
                        const SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Send File',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.bgDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Secondary "Clipboard" Button
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: onSendClipboard,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2538),
                      side: const BorderSide(color: Color(0xFF26354D)),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_rounded, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Clipboard',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
