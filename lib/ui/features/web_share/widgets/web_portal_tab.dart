import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../state/web_share_state.dart';

/// Web Share Portal Tab: Zero-install browser sharing via local Wi-Fi
class WebPortalTab extends StatelessWidget {
  final WebShareState state;

  const WebPortalTab({super.key, required this.state});

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard', style: GoogleFonts.inter(fontSize: 12)),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // URL Bar & Copy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: Row(
              children: [
                const Icon(Icons.language_rounded, size: 18, color: AppTheme.primaryLight),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    state.cleanWebUrl,
                    style: GoogleFonts.firaCode(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.textSecondary),
                  tooltip: 'Copy URL',
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                  onPressed: () => _copy(context, state.webPortalUrl, 'Portal URL'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // QR Code
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: state.webPortalUrl,
              version: QrVersions.auto,
              size: 150.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          // PIN Gate
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Security PIN: ',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Text(
                  state.sessionPin,
                  style: GoogleFonts.firaCode(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppTheme.statusOnline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Staged Files Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shared Files (${state.activeFiles.length})',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              TextButton.icon(
                onPressed: () => state.pickAndAddFiles(),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Files'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryLight,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          if (state.activeFiles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No files staged yet. Tap "Add Files" or let recipient upload to you.',
                style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...state.activeFiles.map(
              (file) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_rounded, size: 16, color: AppTheme.primaryLight),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file.name,
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      file.formattedSize,
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 14, color: AppTheme.textMuted),
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      padding: EdgeInsets.zero,
                      onPressed: () => state.removeFile(file.id),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
