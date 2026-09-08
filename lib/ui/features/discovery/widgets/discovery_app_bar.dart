import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Top navigation bar for LocalDrop matching the design spec
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

  void _handleRefreshTap() {
    spinController.forward(from: 0.0);
    onRescan();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.bgDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.wifi_tethering_rounded,
              color: AppTheme.bgDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'LocalDrop',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.3,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Web Share (Zero-Install / Browser transfer)
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Badge(
            isLabelVisible: isWebSharingActive,
            backgroundColor: AppTheme.primary,
            smallSize: 7,
            child: Icon(
              Icons.public_rounded,
              size: 20,
              color: isWebSharingActive ? AppTheme.primaryLight : AppTheme.textSecondary,
            ),
          ),
          tooltip: 'Web Drop & Offline Hotspot',
          onPressed: onWebShare,
        ),

        // Transfer History
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(Icons.history_rounded, size: 21, color: AppTheme.textSecondary),
          tooltip: 'Transfer History',
          onPressed: onHistory,
        ),

        // Direct IP Connect
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(Icons.exit_to_app_rounded, size: 21, color: AppTheme.textSecondary),
          tooltip: 'Direct IP Connect',
          onPressed: onDirectIp,
        ),

        // Manual Rescan / Refresh: Spins only upon tap (never continuous loops)
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: RotationTransition(
            turns: spinController,
            child: const Icon(
              Icons.refresh_rounded,
              size: 22,
              color: AppTheme.primary,
            ),
          ),
          tooltip: 'Refresh Discovery',
          onPressed: _handleRefreshTap,
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
