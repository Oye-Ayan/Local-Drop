import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../state/web_share_state.dart';

class WebShareModal extends StatefulWidget {
  final WebShareState webShareState;

  const WebShareModal({
    super.key,
    required this.webShareState,
  });

  static Future<void> show(BuildContext context, WebShareState webShareState) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WebShareModal(webShareState: webShareState),
    );
  }

  @override
  State<WebShareModal> createState() => _WebShareModalState();
}

class _WebShareModalState extends State<WebShareModal>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _ssidController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _ssidController = TextEditingController(text: widget.webShareState.hotspotSsid);
    _passwordController = TextEditingController(text: widget.webShareState.hotspotPassword);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            Text('$label copied to clipboard', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          ],
        ),
        backgroundColor: AppTheme.surfaceCardElevated,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.webShareState;

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceCardDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppTheme.borderDark, width: 1.5),
              left: BorderSide(color: AppTheme.borderDark, width: 1),
              right: BorderSide(color: AppTheme.borderDark, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.public_rounded, color: AppTheme.primaryLight, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Universal Drop Hub',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Zero-Install Web Portal & Offline Hotspot',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Segmented Tab Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppTheme.surfaceCardElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppTheme.primaryLight,
                    unselectedLabelColor: AppTheme.textMuted,
                    labelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(
                        iconMargin: EdgeInsets.zero,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.language_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('Web Portal (No App)'),
                          ],
                        ),
                      ),
                      Tab(
                        iconMargin: EdgeInsets.zero,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_tethering_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('Offline Hotspot'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Tab Views
              Flexible(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWebPortalTab(context, state),
                    _buildHotspotTab(context, state),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// TAB 1: Web Portal View
  Widget _buildWebPortalTab(BuildContext context, WebShareState state) {
    if (!state.isSharing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 12),
              Text(
                'Web Portal is Inactive',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Start Web Share to generate a QR code and allow any phone or PC to download/upload files via browser.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: const Text('Start Web Portal Session'),
                onPressed: () => state.startSharing(),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Notification alert if web client sent file or note
          if (state.lastReceivedNotification != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.primaryLight, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.lastReceivedNotification!,
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
                    onPressed: state.clearNotification,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // QR Code Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.18),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: QrImageView(
              data: state.webPortalUrl,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0B0E14),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0B0E14),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Security PIN & Token Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 15, color: AppTheme.primaryLight),
                const SizedBox(width: 8),
                Text(
                  'Access PIN: ',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                ),
                Text(
                  state.sessionPin,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 14, color: AppTheme.borderDark),
                const SizedBox(width: 8),
                Text(
                  'End-to-End Local',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Copyable URL Card
          InkWell(
            onTap: () => _copyToClipboard(context, state.webPortalUrl, 'Portal URL'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, size: 18, color: AppTheme.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.webPortalUrl,
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy_rounded, size: 16, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Network Interface Selector (if multiple IPs available)
          if (state.availableIps.length > 1) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Host Network IP:',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: state.availableIps.map((ip) {
                final isSelected = state.selectedIp == ip;
                return ChoiceChip(
                  label: Text(ip, style: GoogleFonts.inter(fontSize: 11.5)),
                  selected: isSelected,
                  selectedColor: AppTheme.primary.withValues(alpha: 0.25),
                  backgroundColor: AppTheme.surfaceDark,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primary : AppTheme.borderDark,
                  ),
                  onSelected: (_) => state.selectIp(ip),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Queued Files Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Queued for Download (${state.activeFiles.length})',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Files'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryLight,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: state.pickAndAddFiles,
              ),
            ],
          ),
          const SizedBox(height: 6),

          if (state.activeFiles.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Text(
                'No files queued yet. Tap "+ Add Files" to allow the browser client to download them.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
              ),
            )
          else
            ...state.activeFiles.map(
              (file) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, color: AppTheme.primaryLight, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            file.formattedSize,
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.statusError, size: 18),
                      onPressed: () => state.removeFile(file.id),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Stop Sharing Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.stop_circle_outlined, size: 18, color: AppTheme.statusError),
              label: Text('Stop Web Portal', style: GoogleFonts.inter(color: AppTheme.statusError, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.statusError),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                state.stopSharing();
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// TAB 2: Offline Hotspot View
  Widget _buildHotspotTab(BuildContext context, WebShareState state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Use this when traveling or outdoors with NO router and NO internet. Scanning this QR connects any phone camera directly to your hotspot!',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Wi-Fi QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.18),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: QrImageView(
              data: state.wifiQrString,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0B0E14),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0B0E14),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Point any smartphone camera to connect to Wi-Fi',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),

          const SizedBox(height: 16),

          // SSID & Password Fields
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ssidController,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Hotspot SSID',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderDark)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) => state.updateHotspotDetails(val, _passwordController.text),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Passphrase',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderDark)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) => state.updateHotspotDetails(_ssidController.text, val),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3-Step Guide
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline Quick Steps:',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                _buildStepItem('1', 'Turn on Personal Hotspot / Tethering on this device.'),
                _buildStepItem('2', 'Have the other device scan the Wi-Fi QR above to connect.'),
                _buildStepItem('3', 'Switch to the "Web Portal" tab to drop files with zero internet!'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              num,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryLight),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
