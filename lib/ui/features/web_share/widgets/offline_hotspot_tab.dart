import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../state/web_share_state.dart';

/// Offline Hotspot Tab: Zero-router, no-internet hotspot sharing via Wi-Fi QR
class OfflineHotspotTab extends StatefulWidget {
  final WebShareState state;

  const OfflineHotspotTab({super.key, required this.state});

  @override
  State<OfflineHotspotTab> createState() => _OfflineHotspotTabState();
}

class _OfflineHotspotTabState extends State<OfflineHotspotTab> {
  late final TextEditingController _ssidController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _ssidController = TextEditingController(text: widget.state.hotspotSsid);
    _passwordController = TextEditingController(text: widget.state.hotspotPassword);
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wifiQr = widget.state.wifiQrString;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Turn on your mobile hotspot and let other devices scan this QR code with their camera to join your Wi-Fi instantly.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          // Wi-Fi Connect QR Code
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: wifiQr,
              version: QrVersions.auto,
              size: 150.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // SSID and Password fields
          TextField(
            controller: _ssidController,
            style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Hotspot SSID (Network Name)',
              labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              filled: true,
              fillColor: AppTheme.surfaceDark,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderDark)),
            ),
            onChanged: (val) {
              widget.state.updateHotspotDetails(val, widget.state.hotspotPassword);
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Hotspot Password',
              labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              filled: true,
              fillColor: AppTheme.surfaceDark,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderDark)),
            ),
            onChanged: (val) {
              widget.state.updateHotspotDetails(widget.state.hotspotSsid, val);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
