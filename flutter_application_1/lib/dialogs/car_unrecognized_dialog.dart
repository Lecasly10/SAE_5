import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/recognition.dart';
import '../theme/spot_it_theme.dart';
import 'car_picker_dialog.dart';
import '../widgets/spot_it_widgets.dart';

/// Renvoie la suggestion touchée par l'utilisateur, ou null.
Future<Recognition?> showUnrecognizedDialog(
  BuildContext context, {
  required Uint8List bytes,
  required ScanResult result,
}) {
  final noCar = result.reason == NoMatchReason.noCar;
  return showSuggestionsDialog(
    context,
    bytes: bytes,
    title: noCar ? 'Aucune voiture détectée' : 'Voiture non reconnue',
    message: noCar
        ? 'Cadrez la voiture en entier, de face ou de trois quarts, puis réessayez.'
        : "L'IA n'est pas assez sûre de ce modèle. Essayez une autre photo, de face ou de trois quarts.",
    suggestions: noCar ? const [] : result.suggestions,
  );
}

Future<Recognition?> showSuggestionsDialog(
  BuildContext context, {
  required Uint8List bytes,
  required String title,
  required String message,
  required List<Recognition> suggestions,
}) {
  return showDialog<Recognition>(
    context: context,
    builder: (context) => SpotItDialog(
      title: Row(
        children: [
          const Icon(Icons.help_outline, color: SpotItColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
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
              message,
              style: GoogleFonts.inter(color: SpotItColors.secondaryText),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                suggestions.any((car) => car.carId != null)
                    ? "C'est l'une de celles-ci ? Touchez la bonne :"
                    : 'Elle ressemble peut-être à :',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SpotItColors.secondaryText,
                ),
              ),
              const SizedBox(height: 6),
              for (final suggestion in suggestions)
                _SuggestionRow(
                  suggestion: suggestion,
                  onTap: suggestion.carId != null
                      ? () => Navigator.pop(context, suggestion)
                      : null,
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            final car = await showCarPickerDialog(context);
            if (car != null && context.mounted) Navigator.pop(context, car);
          },
          icon: const Icon(Icons.school_outlined, size: 18),
          label: const Text("Aider l'IA"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Réessayer'),
        ),
      ],
    ),
  );
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestion, this.onTap});

  final Recognition suggestion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_outline,
                size: 18,
                color: SpotItColors.secondaryText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
