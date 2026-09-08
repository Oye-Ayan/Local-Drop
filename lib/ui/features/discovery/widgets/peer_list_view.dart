import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/device_model.dart';
import 'peer_tile.dart';

/// Clean list of discovered peers with an Apple/Linear calm empty state
class PeerListView extends StatelessWidget {
  final List<DeviceModel> peers;
  final bool isScanning;
  final ValueChanged<DeviceModel> onSendFile;
  final ValueChanged<DeviceModel>? onSendClipboard;

  const PeerListView({
    super.key,
    required this.peers,
    required this.isScanning,
    required this.onSendFile,
    this.onSendClipboard,
  });

  @override
  Widget build(BuildContext context) {
    if (peers.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
          child: Row(
            children: [
              Text(
                'Nearby Devices',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCardElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Text(
                  '${peers.length}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          itemCount: peers.length,
          itemBuilder: (context, index) {
            final peer = peers[index];
            return PeerTile(
              device: peer,
              onSendFile: () => onSendFile(peer),
              onSendClipboard: onSendClipboard != null
                  ? () => onSendClipboard!(peer)
                  : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCardElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: const Icon(
                Icons.wifi_tethering_rounded,
                size: 24,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isScanning ? 'Searching for devices...' : 'Ready to Connect',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Open LocalDrop on another device on this Wi-Fi network, or tap Web Drop to transfer with any phone or PC via browser.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
