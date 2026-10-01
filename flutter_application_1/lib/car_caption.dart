import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'spot_it_theme.dart';

class CarCaption extends StatelessWidget {
  const CarCaption({this.text = '', super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SpotItColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SpotItColors.border),
      ),
      child: text.isEmpty
          ? null
          : Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                color: Colors.white,
              ),
            ),
    );
  }
}
