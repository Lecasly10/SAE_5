import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/recognition.dart';
import '../theme/spot_it_theme.dart';
import '../widgets/spot_it_widgets.dart';

Future<void> showUnrecognizedDialog(
  BuildContext context, {
  required Uint8List bytes,
  required ScanResult result,
}) {
  final noCar = result.reason == NoMatchReason.noCar;
  final suggestions = noCar ? const <Recognition>[] : result.suggestions;

  return showDialog<void>(
    context: context,
    builder: (context) => SpotItDialog(
      title: Row(
        children: [
          const Icon(Icons.help_outline, color: SpotItColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              noCar ? 'Aucune voiture détectée' : 'Voiture non reconnue',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(bytes, height: 140, fit: BoxFit.cover),
            ),
            const SizedBox(height: 14),
            Text(
              noCar
                  ? 'Cadrez la voiture en entier, de face ou de trois quarts, puis réessayez.'
                  : "L'IA n'est pas assez sûre de ce modèle. Essayez une autre photo, de face ou de trois quarts.",
              style: GoogleFonts.inter(color: SpotItColors.secondaryText),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Elle ressemble peut-être à :',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SpotItColors.secondaryText,
                ),
              ),
              const SizedBox(height: 6),
              for (final suggestion in suggestions)
                _SuggestionRow(suggestion: suggestion),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Réessayer'),
        ),
      ],
    ),
  );
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestion});

  final Recognition suggestion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${suggestion.brand} ${suggestion.model} · ${suggestion.years}',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            ),
          ),
          Text(
            '${suggestion.confidence} %',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: SpotItColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
