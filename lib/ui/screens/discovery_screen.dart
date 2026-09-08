import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localdrop/core/constants/protocol_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/device_model.dart';
import '../../services/history_service.dart';
import '../../state/discovery_state.dart';
import '../../state/transfer_state.dart';
import '../../state/web_share_state.dart';
import '../widgets/device_card.dart';
import '../widgets/history_modal.dart';
import '../widgets/peer_radar.dart';
import '../widgets/transfer_modals.dart';
import '../widgets/web_share_modal.dart';

/// Ethereal Obsidian LocalDrop Discovery Screen
class DiscoveryScreen extends StatefulWidget {
  final DiscoveryState discoveryState;
  final TransferState? transferState;
  final HistoryService? historyService;
  final WebShareState? webShareState;

  const DiscoveryScreen({
    super.key,
    required this.discoveryState,
    this.transferState,
    this.historyService,
    this.webShareState,
  });

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanSpinController;

  @override
  void initState() {
    super.initState();
    widget.discoveryState.initialize();
    _scanSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _scanSpinController.dispose();
    super.dispose();
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
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
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

  void _showSendByIpDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderDark),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.send_to_mobile_rounded,
                color: AppTheme.primaryLight,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Direct IP Share',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the destination device\'s local IP address (shown at the top of the other device\'s screen under "THIS DEVICE"):',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '💡 Normally, devices on the same Wi-Fi discover automatically. Use this only if automatic scan fails.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.primaryLight,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. 10.10.20.121',
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
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final ip = controller.text.trim();
              if (ip.isNotEmpty) {
                Navigator.pop(ctx);
                final targetDevice = DeviceModel(
                  id: 'direct-$ip',
                  name: 'Target ($ip)',
                  ip: ip,
                  port: ProtocolConstants.defaultTcpPort,
                  deviceType: DeviceType.unknown,
                  osName: 'Direct Peer',
                );
                widget.transferState?.pickAndSendFile(targetDevice);
              }
            },
            child: const Text('Pick & Send'),
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
                style: GoogleFonts.inter(
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


  void _onBroadcastTap(BuildContext context, List<DeviceModel> peers) {
    if (peers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No nearby devices discovered yet. Open LocalDrop on another device to connect.',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
          ),
          backgroundColor: AppTheme.surfaceCardElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.borderDark),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (peers.length == 1) {
      widget.transferState?.pickAndSendFile(peers.first);
      return;
    }

    // Multiple peers: show clean modal picker
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppTheme.borderDark),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Destination Device',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...peers.map(
                (peer) => ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: Icon(
                      peer.deviceType.icon,
                      color: AppTheme.primaryLight,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    peer.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    peer.ip.isNotEmpty ? peer.ip : 'Local Peer',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.transferState?.pickAndSendFile(peer);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[widget.discoveryState];
    if (widget.transferState != null) {
      listenables.add(widget.transferState!);
    }
    if (widget.webShareState != null) {
      listenables.add(widget.webShareState!);
    }

    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, _) {
        final state = widget.discoveryState;
        final local = state.localDevice;
        if (local == null) {
          return const Scaffold(
            backgroundColor: AppTheme.bgDark,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }
        final peers = state.peers;
        final transfer = widget.transferState;

        if (state.isScanning) {
          if (!_scanSpinController.isAnimating) {
            _scanSpinController.repeat();
          }
        } else {
          if (_scanSpinController.isAnimating) {
            _scanSpinController.stop();
            _scanSpinController.reset();
          }
        }

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            backgroundColor: AppTheme.bgDark,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: AppTheme.microShadow,
                  ),
                  child: const Icon(
                    Icons.wifi_tethering_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'LocalDrop',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      letterSpacing: -0.4,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              // 1. Universal Web Share & Offline Hotspot Action
              IconButton(
                icon: Badge(
                  isLabelVisible: widget.webShareState?.isSharing ?? false,
                  backgroundColor: AppTheme.primary,
                  smallSize: 8,
                  child: const Icon(Icons.public_rounded, size: 20),
                ),
                tooltip: 'Web Portal & Offline Hotspot (Zero-Install)',
                color: (widget.webShareState?.isSharing ?? false)
                    ? AppTheme.primaryLight
                    : AppTheme.textSecondary,
                onPressed: () {
                  if (widget.webShareState != null) {
                    if (!widget.webShareState!.isSharing) {
                      widget.webShareState!.startSharing(localIp: local.ip);
                    }
                    WebShareModal.show(context, widget.webShareState!);
                  }
                },
              ),

              // 2. Transfer History Action
              IconButton(
                icon: const Icon(Icons.history_rounded, size: 20),
                tooltip: 'Transfer History',
                color: AppTheme.textSecondary,
                onPressed: () {
                  final hist = widget.historyService ??
                      widget.transferState?.historyService;
                  if (hist != null) {
                    HistoryModal.show(context, hist);
                  }
                },
              ),

              // 3. Direct IP Share
              IconButton(
                icon: const Icon(Icons.send_to_mobile_rounded, size: 20),
                tooltip: 'Direct IP Share',
                color: AppTheme.textSecondary,
                onPressed: () => _showSendByIpDialog(context),
              ),

              // 4. Rescan Network (smooth rotation when scanning)
              IconButton(
                icon: state.isScanning
                    ? RotationTransition(
                        turns: _scanSpinController,
                        child: const Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: AppTheme.primary,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                tooltip: state.isScanning ? 'Scanning network...' : 'Rescan Network',
                onPressed: state.isScanning ? null : () => state.refresh(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 750;

              return Stack(
                children: [
                  if (isDesktop)
                    _buildDesktopLayout(
                      state,
                      local,
                      peers,
                      transfer,
                      constraints,
                    )
                  else
                    _buildMobileLayout(
                      state,
                      local,
                      peers,
                      transfer,
                      constraints,
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
              );
            },
          ),
        );
      },
    );
  }

  /// Top Status Header Pill showing Wi-Fi status, green dot, and local IP/device identifier
  Widget _buildStatusHeader(DeviceModel local, bool isScanning) {
    final ipText = local.ip.isNotEmpty
        ? '${local.ip}:${local.port}'
        : 'Connecting...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Subtle Wi-Fi Status Pill (constrained to prevent overflow on narrow screens)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderDark, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Green signal dot
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.statusOnline,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Connected • $ipText',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 2. User Device Identity Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  local.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 14),
                color: AppTheme.textMuted,
                tooltip: 'Edit Device Name',
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
                onPressed: () => _showEditNameDialog(context, local.name),
              ),
            ],
          ),

          // 3. Active Web Portal Indicator Pill (if active)
          if (widget.webShareState?.isSharing ?? false) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => WebShareModal.show(context, widget.webShareState!),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language_rounded, size: 12, color: AppTheme.primaryLight),
                    const SizedBox(width: 6),
                    Text(
                      'Web Portal Live • ${widget.webShareState!.cleanWebUrl}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.qr_code_rounded, size: 12, color: AppTheme.primaryLight),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Interactive Action Zone:
  /// - Floating drag-and-drop target area ("Drop files here or tap to broadcast")
  /// - Universal Web Share / Offline Hotspot Hub button (Zero-Install)
  /// - Live Transfer Drawer showing progress, speed, and action buttons when active
  Widget _buildActionZone(
    DeviceModel local,
    List<DeviceModel> peers,
    TransferState? transfer,
  ) {
    final activeItem = transfer?.activeTransfer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Active Transfer Progress Card (if any transfer in progress)
        if (activeItem != null)
          TransferDrawer(
            item: activeItem,
            onCancel: () => transfer?.cancelActiveTransfer(),
            onDismiss: () => transfer?.clearActiveTransfer(),
          ),

        // 2. Floating Action Controls
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Broadcast / Drag & Drop Target
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onBroadcastTap(context, peers),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderDark, width: 1),
                      boxShadow: AppTheme.microShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.file_upload_outlined,
                            color: AppTheme.primaryLight,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Drop files here or tap to broadcast',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '100% Lossless Original Quality • Bit-for-bit SHA-256',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primaryLight,
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

              const SizedBox(height: 8),

              // Universal Web Drop & Offline Hotspot Hub Button (Zero-Install)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (widget.webShareState != null) {
                      if (!widget.webShareState!.isSharing) {
                        widget.webShareState!.startSharing(localIp: local.ip);
                      }
                      WebShareModal.show(context, widget.webShareState!);
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCardElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (widget.webShareState?.isSharing ?? false)
                            ? AppTheme.primary.withValues(alpha: 0.5)
                            : AppTheme.borderSubtle,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.public_rounded,
                            size: 16,
                            color: AppTheme.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Web Drop & Offline Hotspot',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'No App Needed',
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                (widget.webShareState?.isSharing ?? false)
                                    ? 'Portal Live: ${widget.webShareState!.cleanWebUrl}'
                                    : 'Share with iPhone, Mac, Windows via browser or QR',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: (widget.webShareState?.isSharing ?? false)
                                      ? AppTheme.primaryLight
                                      : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.qr_code_2_rounded,
                          size: 18,
                          color: AppTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Mobile Layout (< 750px): Elegant single-column flow with central radar and action zone
  Widget _buildMobileLayout(
    DiscoveryState state,
    DeviceModel local,
    List<DeviceModel> peers,
    TransferState? transfer,
    BoxConstraints constraints,
  ) {
    final radarDiameter = (constraints.maxWidth * 0.82).clamp(260.0, 320.0);

    return Column(
      children: [
        // Top Status Header Pill
        _buildStatusHeader(local, state.isScanning),

        // Scrollable central area
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Central Peer Radar (Main View)
                PeerRadar(
                  localDevice: local,
                  peers: peers,
                  size: radarDiameter,
                  isScanning: state.isScanning,
                  onPeerTap: (peer) => transfer?.pickAndSendFile(peer),
                  onCenterTap: () => _showEditNameDialog(context, local.name),
                ),

                const SizedBox(height: 20),

                // Section: Discovered Peers or Friendly Empty State
                if (peers.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Nearby Devices',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
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
                  ...peers.map(
                    (peer) => DeviceCard(
                      device: peer,
                      onSendFile: transfer != null
                          ? () => transfer.pickAndSendFile(peer)
                          : null,
                      onSendClipboard: () => _onClipboardAction(peer),
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    child: Text(
                      'Open LocalDrop on another device (PC or phone) on this Wi-Fi network.\nThey will appear here automatically — no IP needed!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Interactive Action Zone
        _buildActionZone(local, peers, transfer),
      ],
    );
  }

  /// Desktop Layout (>= 750px): Clean side-by-side split layout
  Widget _buildDesktopLayout(
    DiscoveryState state,
    DeviceModel local,
    List<DeviceModel> peers,
    TransferState? transfer,
    BoxConstraints constraints,
  ) {
    return Row(
      children: [
        // Left Column: Central Peer Radar & Status Header
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildStatusHeader(local, state.isScanning),
              const Spacer(),
              PeerRadar(
                localDevice: local,
                peers: peers,
                size: 340,
                isScanning: state.isScanning,
                onPeerTap: (peer) => transfer?.pickAndSendFile(peer),
                onCenterTap: () => _showEditNameDialog(context, local.name),
              ),
              const Spacer(),
              if (peers.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Scanning for nearby devices on the local network...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Vertical Divider
        const VerticalDivider(width: 1, color: AppTheme.borderSubtle),

        // Right Column: Discovered Devices List & Interactive Action Zone
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  children: [
                    Text(
                      'Nearby Devices',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: Text(
                        '${peers.length}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: peers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.devices_other_rounded,
                              size: 40,
                              color: AppTheme.textMuted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No devices found yet',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Make sure devices are on the same local Wi-Fi',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: peers.length,
                        itemBuilder: (ctx, i) => DeviceCard(
                          device: peers[i],
                          onSendFile: transfer != null
                              ? () => transfer.pickAndSendFile(peers[i])
                              : null,
                          onSendClipboard: () => _onClipboardAction(peers[i]),
                        ),
                      ),
              ),
              _buildActionZone(local, peers, transfer),
            ],
          ),
        ),
      ],
    );
  }
}
