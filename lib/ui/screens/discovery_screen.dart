import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/protocol_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/device_model.dart';
import '../../services/history_service.dart';
import '../../state/discovery_state.dart';
import '../../state/transfer_state.dart';
import '../../state/web_share_state.dart';
import '../features/discovery/widgets/action_dock.dart';
import '../features/discovery/widgets/device_identity_card.dart';
import '../features/discovery/widgets/discovery_app_bar.dart';
import '../features/discovery/widgets/edit_name_dialog.dart';
import '../features/discovery/widgets/peer_list_view.dart';
import '../features/discovery/widgets/peer_radar.dart';
import '../features/discovery/widgets/send_by_ip_sheet.dart';
import '../features/history/widgets/history_modal.dart';
import '../features/transfer/widgets/active_transfer_bar.dart';
import '../features/transfer/widgets/incoming_transfer_dialog.dart';
import '../features/transfer/widgets/transfer_progress_modal.dart';
import '../features/web_share/web_share_modal.dart';

/// Clean coordinator screen adhering strictly to the LocalDrop design spec
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
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    widget.discoveryState.initialize();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _onEditName(BuildContext context, String currentName) {
    EditNameDialog.show(context, currentName, (newName) {
      widget.discoveryState.updateDeviceName(newName);
    });
  }

  void _onSendByIp(BuildContext context) {
    SendByIpDialog.show(context, (ip) {
      final target = DeviceModel(
        id: 'direct-$ip',
        name: 'Target ($ip)',
        ip: ip,
        port: ProtocolConstants.defaultTcpPort,
        deviceType: DeviceType.unknown,
        osName: 'Direct Peer',
      );
      widget.transferState?.pickAndSendFile(target);
    });
  }

  void _onWebShare(BuildContext context, String localIp) {
    final state = widget.webShareState;
    if (state != null) {
      if (!state.isSharing) {
        state.startSharing(localIp: localIp);
      }
      WebShareModal.show(context, state);
    }
  }

  void _onHistory(BuildContext context) {
    final hist = widget.historyService ?? widget.transferState?.historyService;
    if (hist != null) {
      HistoryModal.show(context, hist);
    }
  }

  void _onBroadcastTap(BuildContext context, List<DeviceModel> peers) {
    if (peers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No nearby devices discovered yet. Tap Web Drop to share via browser.',
            style: GoogleFonts.inter(fontSize: 12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (peers.length == 1) {
      widget.transferState?.pickAndSendFile(peers.first);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
              child: Text(
                'Select Destination Device',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            ...peers.map((peer) => ListTile(
              leading: Icon(peer.deviceType.icon, color: AppTheme.primaryLight),
              title: Text(
                peer.name,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                peer.ip,
                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11),
              ),
              onTap: () {
                Navigator.pop(ctx);
                widget.transferState?.pickAndSendFile(peer);
              },
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[widget.discoveryState];
    if (widget.transferState != null) listenables.add(widget.transferState!);
    if (widget.webShareState != null) listenables.add(widget.webShareState!);

    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, _) {
        final state = widget.discoveryState;
        final local = state.localDevice;
        final transfer = widget.transferState;
        final webShare = widget.webShareState;

        if (local == null) {
          return const Scaffold(
            backgroundColor: AppTheme.bgDark,
            body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: DiscoveryAppBar(
            isScanning: state.isScanning,
            spinController: _spinController,
            isWebSharingActive: webShare?.isSharing ?? false,
            onRescan: () => state.refresh(),
            onWebShare: () => _onWebShare(context, local.ip),
            onHistory: () => _onHistory(context),
            onDirectIp: () => _onSendByIp(context),
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Centered Status Pill & Device Name
                          DeviceIdentityCard(
                            local: local,
                            isWebSharingActive: webShare?.isSharing ?? false,
                            webPortalUrl: webShare?.cleanWebUrl,
                            onEditName: () => _onEditName(context, local.name),
                            onWebShareTap: () => _onWebShare(context, local.ip),
                          ),

                          // 2. Central Radar Canvas with concentric rings and orbiting peers
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: PeerRadar(
                              localDevice: local,
                              peers: state.peers,
                              isScanning: state.isScanning,
                              onPeerTap: (peer) => transfer?.pickAndSendFile(peer),
                              onCenterTap: () => _onEditName(context, local.name),
                            ),
                          ),

                          // Active transfer status bar (if active)
                          if (transfer?.activeTransfer != null)
                            ActiveTransferBar(
                              item: transfer!.activeTransfer!,
                              onCancel: () => transfer.cancelActiveTransfer(),
                              onDismiss: () => transfer.clearActiveTransfer(),
                            ),

                          // 3. Nearby Devices List
                          PeerListView(
                            peers: state.peers,
                            isScanning: state.isScanning,
                            onSendFile: (peer) => transfer?.pickAndSendFile(peer),
                            onSendClipboard: (peer) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Clipboard sharing with ${peer.name} triggered.',
                                    style: GoogleFonts.inter(fontSize: 12),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // 4. Bottom Broadcast & Lossless Card
                  ActionDock(
                    isWebPortalLive: webShare?.isSharing ?? false,
                    onSendFiles: () => _onBroadcastTap(context, state.peers),
                    onWebShare: () => _onWebShare(context, local.ip),
                  ),
                ],
              ),

              // Overlays for Incoming and Progress
              if (transfer != null && transfer.hasIncomingPrompt)
                Container(
                  color: Colors.black.withValues(alpha: 0.75),
                  alignment: Alignment.center,
                  child: IncomingTransferDialog(transferState: transfer),
                ),
              if (transfer != null &&
                  transfer.activeTransfer != null &&
                  !transfer.hasIncomingPrompt &&
                  transfer.activeTransfer!.status.isDone)
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
