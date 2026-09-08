import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Industrial-standard clean top navigation bar for LocalDrop
class DiscoveryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isScanning;
  final AnimationController spinController;
  final bool isWebSharingActive;
  final VoidCallback onRescan;
  final VoidCallback onDirectIp;
  final VoidCallback onHistory;
  final VoidCallback onWebShare;

  const DiscoveryAppBar({
    super.key,
    required this.isScanning,
    required this.spinController,
    required this.isWebSharingActive,
    required this.onRescan,
    required this.onDirectIp,
    required this.onHistory,
    required this.onWebShare,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.bgDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 14,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.arrow_downward_rounded, color: AppTheme.bgDark, size: 16),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'LocalDrop',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: -0.4,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Web Share (Zero-Install) Action
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          icon: Badge(
            isLabelVisible: isWebSharingActive,
            backgroundColor: AppTheme.primary,
            smallSize: 7,
            child: Icon(
              Icons.public_rounded,
              size: 19,
              color: isWebSharingActive ? AppTheme.primaryLight : AppTheme.textSecondary,
            ),
          ),
          tooltip: 'Web Drop & Offline Hotspot',
          onPressed: onWebShare,
        ),

        // Transfer History
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          icon: const Icon(Icons.history_rounded, size: 19, color: AppTheme.textSecondary),
          tooltip: 'Transfer History',
          onPressed: onHistory,
        ),

        // Direct IP Connect
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          icon: const Icon(Icons.send_to_mobile_rounded, size: 19, color: AppTheme.textSecondary),
          tooltip: 'Direct IP Connect',
          onPressed: onDirectIp,
        ),

        // Network Rescan
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          icon: isScanning
              ? RotationTransition(
                  turns: spinController,
                  child: const Icon(Icons.refresh_rounded, size: 19, color: AppTheme.primary),
                )
              : const Icon(Icons.refresh_rounded, size: 19, color: AppTheme.textSecondary),
          tooltip: isScanning ? 'Scanning...' : 'Rescan Network',
          onPressed: isScanning ? null : onRescan,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
