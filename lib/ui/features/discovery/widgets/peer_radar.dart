import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/device_model.dart';

/// Central Peer Radar visualization matching the LocalDrop design spec
class PeerRadar extends StatefulWidget {
  final DeviceModel localDevice;
  final List<DeviceModel> peers;
  final bool isScanning;
  final ValueChanged<DeviceModel>? onPeerTap;
  final VoidCallback? onCenterTap;
  final double size;

  const PeerRadar({
    super.key,
    required this.localDevice,
    required this.peers,
    this.isScanning = true,
    this.onPeerTap,
    this.onCenterTap,
    this.size = 280,
  });

  @override
  State<PeerRadar> createState() => _PeerRadarState();
}

class _PeerRadarState extends State<PeerRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
              builder: (context, _) {
                return CustomPaint(
                  size: Size(radarSize, radarSize),
                  painter: _RadarCanvasPainter(
                    progress: _pulseController.value,
                    accentColor: AppTheme.primary,
                    isScanning: widget.isScanning,
                  ),
                );
              },
            ),

            // 2. Center Hub: Local Device Avatar & "This Device" Badge
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
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF132030),
            border: Border.all(
              color: AppTheme.primary,
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.22),
                blurRadius: 18,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                _resolveDeviceIcon(widget.localDevice.deviceType, widget.localDevice.osName),
                color: Colors.white,
                size: 28,
              ),
              // Signal dot at 4 o'clock edge
              Positioned(
                bottom: 4,
                right: 6,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary,
                    border: Border.all(color: const Color(0xFF132030), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
          decoration: BoxDecoration(
            color: const Color(0xFF101726),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary, width: 1.2),
          ),
          child: Text(
            'This Device',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
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
    // Angular layout: start at top (-pi/2) and distribute
    final baseAngle = -math.pi / 2;
    final angleStep = (2 * math.pi) / (total > 0 ? total : 1);
    final angle = baseAngle + (index * angleStep);

    final x = center.dx + (radius * math.cos(angle)) - 36;
    final y = center.dy + (radius * math.sin(angle)) - 38;

    return Positioned(
      left: x,
      top: y,
      child: _PeerNodeWidget(
        peer: peer,
        icon: _resolveDeviceIcon(peer.deviceType, peer.osName),
        onTap: () => widget.onPeerTap?.call(peer),
      ),
    );
  }
}

class _PeerNodeWidget extends StatelessWidget {
  final DeviceModel peer;
  final IconData icon;
  final VoidCallback onTap;

  const _PeerNodeWidget({
    required this.peer,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF182338),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 23),
                  Positioned(
                    top: 3,
                    right: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              peer.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.1,
              ),
            ),
            Text(
              peer.osName.isNotEmpty ? peer.osName : 'Nearby',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarCanvasPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final bool isScanning;

  _RadarCanvasPainter({
    required this.progress,
    required this.accentColor,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = (size.width / 2) - 4;

    // Static concentric guide rings
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, maxRadius * 0.38, ringPaint);
    canvas.drawCircle(center, maxRadius * 0.70, ringPaint);
    canvas.drawCircle(center, maxRadius, ringPaint);

    if (!isScanning) return;

    // Subtle expanding radar pulse
    const ringCount = 2;
    for (int i = 0; i < ringCount; i++) {
      final ringProgress = (progress + (i / ringCount)) % 1.0;
      final radius = ringProgress * maxRadius;
      final alpha = ((1.0 - ringProgress) * 0.22).clamp(0.0, 0.22);

      final pulsePaint = Paint()
        ..color = accentColor.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawCircle(center, radius, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarCanvasPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isScanning != isScanning;
  }
}
