import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/spot_it_theme.dart';

class PhotoSourceButton extends StatefulWidget {
  const PhotoSourceButton({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    this.primary = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;
  final bool primary;

  @override
  State<PhotoSourceButton> createState() => _PhotoSourceButtonState();
}

class _PhotoSourceButtonState extends State<PhotoSourceButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;
    final foreground = primary ? SpotItColors.background : Colors.white;
    final captionColor = primary
        ? SpotItColors.background.withValues(alpha: 0.65)
        : SpotItColors.secondaryText;
    final radius = BorderRadius.circular(24);

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: primary
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3CFFE2), Color(0xFF00C9AE)],
                )
              : null,
          color: primary ? null : SpotItColors.surface,
          border: Border.all(
            color: primary ? Colors.transparent : SpotItColors.border,
          ),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: SpotItColors.accent.withValues(alpha: 0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary
                          ? SpotItColors.background.withValues(alpha: 0.14)
                          : SpotItColors.accent.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 24,
                      color: primary
                          ? SpotItColors.background
                          : SpotItColors.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.caption,
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: captionColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
