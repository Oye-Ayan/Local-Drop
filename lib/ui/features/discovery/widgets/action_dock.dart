import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Floating bottom action dock for instant file sending and web portal access
class ActionDock extends StatelessWidget {
  final VoidCallback onSendFiles;
  final VoidCallback onWebShare;
  final bool isWebPortalLive;

  const ActionDock({
    super.key,
    required this.onSendFiles,
    required this.onWebShare,
    this.isWebPortalLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.bgDark.withValues(alpha: 0.92),
        border: const Border(top: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Web Drop Button (Secondary / Hub)
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: onWebShare,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    backgroundColor: AppTheme.surfaceCardElevated,
                    foregroundColor: isWebPortalLive
                        ? AppTheme.primaryLight
                        : AppTheme.textPrimary,
                    side: BorderSide(
                      color: isWebPortalLive
                          ? AppTheme.primary.withValues(alpha: 0.5)
                          : AppTheme.borderDark,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.public_rounded,
                        size: 16,
                        color: isWebPortalLive
                            ? AppTheme.primaryLight
                            : AppTheme.accent,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isWebPortalLive ? 'Portal Live' : 'Web Drop',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Send Files Button (Primary Action)
            Expanded(
              flex: 6,
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: onSendFiles,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_upward_rounded, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Send Files',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
