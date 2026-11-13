import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/scanned_car.dart';
import '../theme/spot_it_theme.dart';

extension RarityColor on Rarity {
  Color get color => switch (this) {
        Rarity.commune => const Color(0xFF9CA3AF),
        Rarity.rare => const Color(0xFF4DA3FF),
        Rarity.epique => const Color(0xFFB57BFF),
        Rarity.legendaire => const Color(0xFFFFC233),
        Rarity.mythique => const Color(0xFFFF4FA3),
      };
}

class RarityBadge extends StatelessWidget {
  const RarityBadge({required this.rarity, this.small = false, super.key});

  final Rarity rarity;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final color = rarity.color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        // Fond opaque pour rester lisible par-dessus une photo
        color: Color.alphaBlend(
          color.withValues(alpha: 0.16),
          SpotItColors.background,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.diamond_outlined, size: small ? 10 : 13, color: color),
          SizedBox(width: small ? 3 : 5),
          Text(
            rarity.label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: small ? 8 : 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
