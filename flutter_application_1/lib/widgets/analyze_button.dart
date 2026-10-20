import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/spot_it_theme.dart';

class AnalyzeButton extends StatelessWidget {
  const AnalyzeButton({
    required this.enabled,
    required this.loading,
    required this.onPressed,
    super.key,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final active = enabled || loading;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: enabled && !loading ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: SpotItColors.accent,
          foregroundColor: SpotItColors.background,
          disabledBackgroundColor: loading
              ? SpotItColors.accent.withValues(alpha: 0.85)
              : SpotItColors.disabledSurface.withValues(alpha: 0.60),
          disabledForegroundColor:
              loading ? SpotItColors.background : SpotItColors.disabledText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: active ? SpotItColors.accent : SpotItColors.disabledBorder,
            ),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: SpotItColors.background,
                  ),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.center_focus_strong, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Analyser la photo',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
