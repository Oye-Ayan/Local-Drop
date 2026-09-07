import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/device_model.dart';

/// Central Peer Radar (Main View)
/// - Center: User's primary device avatar with a soft glowing status ring.
/// - Radar Pulse: 3 concentric, ultra-thin circular rings expanding outward in a smooth, fluid rhythm.
/// - Nearby Peer Nodes: Discovered devices anchored elegantly along the radar rings.
///   On hover/tap, nodes gently scale up (1.05x) with a subtle elevation shadow.
class PeerRadar extends StatefulWidget {
  final DeviceModel localDevice;
  final List<DeviceModel> peers;
  final bool isScanning;
  final void Function(DeviceModel peer)? onPeerTap;
  final VoidCallback? onCenterTap;
  final double size;

  const PeerRadar({
    super.key,
    required this.localDevice,
    required this.peers,
    this.isScanning = true,
    this.onPeerTap,
    this.onCenterTap,
    this.size = 320,
  });

  @override
  State<PeerRadar> createState() => _PeerRadarState();
}

class _PeerRadarState extends State<PeerRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  IconData _getDeviceIcon(DeviceType type, String? osName) {
    final os = (osName ?? '').toLowerCase();
    if (os.contains('mac') || os.contains('darwin')) {
      return Icons.laptop_mac_rounded;
    } else if (os.contains('win')) {
      return Icons.laptop_windows_rounded;
    } else if (os.contains('linux')) {
      return Icons.computer_rounded;
    } else if (type == DeviceType.phone || os.contains('android') || os.contains('ios')) {
      return Icons.phone_iphone_rounded;
    } else if (type == DeviceType.tablet) {
      return Icons.tablet_mac_rounded;
    }
    return Icons.devices_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final radarSize = widget.size;
    final centerOffset = Offset(radarSize / 2, radarSize / 2);
    final orbitRadius = radarSize * 0.38;

    return Center(
      child: SizedBox(
        width: radarSize,
        height: radarSize,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 1. Concentric Animated Radar Rings
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(radarSize, radarSize),
                  painter: _MatteRadarPainter(
                    progress: _pulseController.value,
                    accentColor: AppTheme.primary,
                    isScanning: widget.isScanning,
                  ),
                );
              },
            ),

            // 2. Center Node: Local Device Avatar
            GestureDetector(
              onTap: widget.onCenterTap,
              child: _buildCenterDeviceHub(),
            ),

            // 3. Orbiting Discovered Peer Nodes
            if (widget.peers.isNotEmpty) ...[
              for (int i = 0; i < widget.peers.length; i++)
                _buildPeerNode(
                  peer: widget.peers[i],
                  index: i,
                  total: widget.peers.length,
                  center: centerOffset,
                  radius: orbitRadius,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCenterDeviceHub() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfaceCardElevated,
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                _getDeviceIcon(widget.localDevice.deviceType, widget.localDevice.osName),
                color: AppTheme.textPrimary,
                size: 30,
              ),
              // Tiny online green badge
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.statusOnline,
                    border: Border.all(
                      color: AppTheme.surfaceCardElevated,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Text(
            'This Device',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeerNode({
    required DeviceModel peer,
    required int index,
    required int total,
    required Offset center,
    required double radius,
  }) {
    // Angular distribution: distribute smoothly around circle
    final baseAngle = -math.pi / 2; // Start from top
    final angleStep = (2 * math.pi) / (total > 0 ? total : 1);
    final angle = baseAngle + (index * angleStep);

    final x = center.dx + (radius * math.cos(angle)) - 36; // half peer width (72/2)
    final y = center.dy + (radius * math.sin(angle)) - 42;

    return Positioned(
      left: x,
      top: y,
      child: _PeerNodeItem(
        peer: peer,
        icon: _getDeviceIcon(peer.deviceType, peer.osName),
        onTap: () => widget.onPeerTap?.call(peer),
      ),
    );
  }
}

/// Interactive Peer Node with hover/tap 1.05x scale and elevation micro-shadow
class _PeerNodeItem extends StatefulWidget {
  final DeviceModel peer;
  final IconData icon;
  final VoidCallback onTap;

  const _PeerNodeItem({
    required this.peer,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PeerNodeItem> createState() => _PeerNodeItemState();
}

class _PeerNodeItemState extends State<_PeerNodeItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: 76,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Node Avatar Circle
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isHovered ? AppTheme.surfaceHover : AppTheme.surfaceDark,
                    border: Border.all(
                      color: _isHovered
                          ? AppTheme.primary
                          : Colors.white.withValues(alpha: 0.15),
                      width: _isHovered ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isHovered
                            ? AppTheme.primary.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.4),
                        blurRadius: _isHovered ? 12 : 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        color: _isHovered ? AppTheme.primaryLight : AppTheme.textPrimary,
                        size: 24,
                      ),
                      // Active green signal dot
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.statusOnline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                // Peer Name label
                Text(
                  widget.peer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isHovered ? AppTheme.textPrimary : AppTheme.textSubheading,
                    letterSpacing: -0.1,
                  ),
                ),
                Text(
                  widget.peer.osName.isNotEmpty ? widget.peer.osName : 'Nearby',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for 3 concentric, ultra-thin expanding circular rings
class _MatteRadarPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final bool isScanning;

  _MatteRadarPainter({
    required this.progress,
    required this.accentColor,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = (size.width / 2) - 4;

    // 1. Static subtle boundary guides
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, maxRadius * 0.40, guidePaint);
    canvas.drawCircle(center, maxRadius * 0.72, guidePaint);
    canvas.drawCircle(center, maxRadius, guidePaint);

    if (!isScanning) return;

    // 2. 3 Concentric ultra-thin dynamic expanding pulses
    const ringCount = 3;
    for (int i = 0; i < ringCount; i++) {
      final ringProgress = (progress + (i / ringCount)) % 1.0;
      final radius = ringProgress * maxRadius;

      // Smooth ease-in-out opacity transition from 0.30 down to 0.00
      final easedOpacity = (1.0 - math.pow(ringProgress, 0.8)).clamp(0.0, 1.0);
      final alpha = (easedOpacity * 0.30).clamp(0.0, 0.30);

      final pulsePaint = Paint()
        ..color = accentColor.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawCircle(center, radius, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MatteRadarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isScanning != isScanning;
  }
}
