import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'spot_it_theme.dart';
import 'spot_it_widgets.dart';

void showSpotItToast(
  BuildContext context,
  String message, {
  bool isError = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final color = isError ? SpotItColors.danger : SpotItColors.accent;
  final width = math.min(
    MediaQuery.sizeOf(context).width - 48,
    kContentMaxWidth - 48,
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        width: width,
        backgroundColor: SpotItColors.selectedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: SpotItColors.accent,
                onPressed: onAction ?? () {},
              ),
      ),
    );
}
