import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/device_model.dart';
import 'peer_tile.dart';

/// Nearby Devices section with count badge and responsive peer cards
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: "Nearby Devices (N)"
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: Row(
            children: [
              Text(
                'Nearby Devices',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF142936),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${peers.length}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (peers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.wifi_tethering_rounded,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Searching for nearby devices on Wi-Fi...',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
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
}
