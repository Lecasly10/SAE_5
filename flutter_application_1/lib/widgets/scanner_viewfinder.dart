import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/recognition.dart';
import '../theme/spot_it_theme.dart';
import 'framed_image.dart';

class ScannerViewfinder extends StatelessWidget {
  const ScannerViewfinder({
    required this.bytes,
    required this.box,
    required this.onClear,
    super.key,
  });

  final Uint8List? bytes;
  final DetectionBox? box;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final height =
        (MediaQuery.sizeOf(context).height * 0.42).clamp(260.0, 400.0);
    final hasImage = bytes != null;

    return Container(
      width: double.infinity,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: hasImage
              ? SpotItColors.accent.withValues(alpha: 0.5)
              : SpotItColors.border,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SpotItColors.surface, SpotItColors.background],
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: hasImage
            ? Stack(
                key: const ValueKey('photo'),
                fit: StackFit.expand,
                children: [
                  FramedImage(
                    bytes: bytes!,
                    box: box,
                    fit: BoxFit.contain,
                    revealDelay: Duration.zero,
                  ),
                  CustomPaint(
                    painter: _CornerBracketsPainter(SpotItColors.accent),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _CircleIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Retirer la photo',
                      onTap: onClear,
                    ),
                  ),
                ],
              )
            : Stack(
                key: const ValueKey('empty'),
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _CornerBracketsPainter(
                      SpotItColors.disabledText.withValues(alpha: 0.7),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SpotItColors.accent.withValues(alpha: 0.08),
                            border: Border.all(
                              color:
                                  SpotItColors.accent.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.directions_car_filled_rounded,
                            size: 38,
                            color: SpotItColors.accent,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cadrez la voiture',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Prenez une photo ou choisissez-en une',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: SpotItColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  const _CornerBracketsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 20.0;
    const length = 26.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(inset, inset + length)
      ..lineTo(inset, inset)
      ..lineTo(inset + length, inset)
      ..moveTo(w - inset - length, inset)
      ..lineTo(w - inset, inset)
      ..lineTo(w - inset, inset + length)
      ..moveTo(inset, h - inset - length)
      ..lineTo(inset, h - inset)
      ..lineTo(inset + length, h - inset)
      ..moveTo(w - inset - length, h - inset)
      ..lineTo(w - inset, h - inset)
      ..lineTo(w - inset, h - inset - length);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter oldDelegate) =>
      oldDelegate.color != color;
}
