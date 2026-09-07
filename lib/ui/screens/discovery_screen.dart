import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/device_model.dart';
import '../../state/discovery_state.dart';
import '../../state/transfer_state.dart';
import '../widgets/device_card.dart';
import '../widgets/radar_pulse.dart';
import '../widgets/transfer_modals.dart';

/// Ethereal Obsidian LocalDrop Discovery Screen
class DiscoveryScreen extends StatefulWidget {
  final DiscoveryState discoveryState;
  final TransferState? transferState;

  const DiscoveryScreen({
    super.key,
    required this.discoveryState,
    this.transferState,
  });

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    widget.discoveryState.initialize();
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderDark),
        ),
        title: Text(
          'Edit Device Name',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: 'Enter new device name',
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.surfaceDark,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                widget.discoveryState.updateDeviceName(newName);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Name'),
          ),
        ],
      ),
    );
  }

  void _onClipboardAction(DeviceModel peer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppTheme.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Clipboard sync with ${peer.name} will be enabled in Phase 4.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceCardElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppTheme.borderDark),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[widget.discoveryState];
    if (widget.transferState != null) {
      listenables.add(widget.transferState!);
    }

    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, _) {
        final state = widget.discoveryState;
        final local = state.localDevice;
        final peers = state.peers;
        final transfer = widget.transferState;

        return Scaffold(
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            backgroundColor: AppTheme.bgDark,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wifi_tethering_rounded,
                    color: AppTheme.textInverse,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'LocalDrop',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: state.isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                tooltip: 'Rescan Network',
                onPressed: state.isScanning ? null : () => state.refresh(),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: Stack(
            children: [
              // Ambient Radial Glow 1: Cyan Orb
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Ambient Radial Glow 2: Indigo Orb
              Positioned(
                top: 250,
                left: -100,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.secondary.withValues(alpha: 0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main Scrollable List
              RefreshIndicator(
                color: AppTheme.primary,
                backgroundColor: AppTheme.surfaceCardDark,
                onRefresh: () => state.refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    // 1. Local Device Status Card (Machined Double-Bezel)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppTheme.borderDark,
                            width: 1,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCardDark,
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(
                              color: AppTheme.borderSubtle,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Device Icon Box
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.secondary.withValues(
                                            alpha: 0.2,
                                          ),
                                          AppTheme.accent.withValues(
                                            alpha: 0.1,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(13),
                                      border: Border.all(
                                        color: AppTheme.secondary.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      local?.deviceType.icon ??
                                          Icons.devices_rounded,
                                      color: AppTheme.secondaryLight,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Device Name & Eyebrow Tag
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppTheme.statusOnline,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.statusOnline
                                                        .withValues(alpha: 0.6),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'THIS DEVICE',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color:
                                                        AppTheme.secondaryLight,
                                                    letterSpacing: 1.0,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          local?.name ?? 'Detecting device...',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.textPrimary,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Edit Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: AppTheme.textSecondary,
                                    ),
                                    tooltip: 'Edit Device Name',
                                    onPressed: local != null
                                        ? () => _showEditNameDialog(
                                            context,
                                            local.name,
                                          )
                                        : null,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),
                              const Divider(
                                height: 1,
                                color: AppTheme.borderSubtle,
                              ),
                              const SizedBox(height: 12),

                              // Network Info & OS Tag
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.statusOnline,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.statusOnline
                                              .withValues(alpha: 0.5),
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      local != null
                                          ? '${local.ip}:${local.port}'
                                          : 'Resolving network...',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (local != null && local.osName.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceDark,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppTheme.borderDark,
                                        ),
                                      ),
                                      child: Text(
                                        local.osName,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textSubheading,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 200.ms),

                    // 2. Error Message Banner (if any)
                    if (state.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.statusError.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.statusError.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppTheme.statusError,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  state.errorMessage!,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 3. Section Header: Nearby Devices
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            'Nearby Devices',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${peers.length}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (state.isScanning)
                            Row(
                              children: [
                                Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.primary,
                                      ),
                                    )
                                    .animate(
                                      onPlay: (c) => c.repeat(reverse: true),
                                    )
                                    .scale(
                                      begin: const Offset(0.7, 0.7),
                                      end: const Offset(1.3, 1.3),
                                      duration: 700.ms,
                                    ),
                                const SizedBox(width: 6),
                                Text(
                                  'Scanning...',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // 4. Content: Empty State or Peer Cards
                    if (peers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const RadarPulse(size: 130),
                              const SizedBox(height: 20),
                              Text(
                                'Scanning for devices',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ensure other devices are on the same Wi-Fi\nnetwork with LocalDrop running.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                height: 40,
                                child: OutlinedButton.icon(
                                  onPressed: () => state.refresh(),
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Rescan Network'),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...peers.map(
                        (peer) => DeviceCard(
                          device: peer,
                          onSendFile: transfer != null
                              ? () => transfer.pickAndSendFile(peer)
                              : null,
                          onSendClipboard: () => _onClipboardAction(peer),
                        ),
                      ),
                  ],
                ),
              ),

              // Overlay 1: Incoming Transfer Prompt Dialog
              if (transfer != null && transfer.hasIncomingPrompt)
                Container(
                  color: Colors.black.withValues(alpha: 0.75),
                  alignment: Alignment.center,
                  child: IncomingTransferDialog(transferState: transfer),
                ),

              // Overlay 2: Active Transfer Progress Modal
              if (transfer != null &&
                  transfer.activeTransfer != null &&
                  !transfer.hasIncomingPrompt)
                Container(
                  color: Colors.black.withValues(alpha: 0.75),
                  alignment: Alignment.center,
                  child: TransferProgressModal(
                    item: transfer.activeTransfer!,
                    onCancel: transfer.cancelActiveTransfer,
                    onDismiss: transfer.clearActiveTransfer,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
