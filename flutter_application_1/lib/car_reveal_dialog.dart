import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'car_showcase_dialog.dart';
import 'framed_image.dart';
import 'recognition.dart';
import 'spot_it_theme.dart';

enum AnalysisChoice { addToLibrary, login }

Future<AnalysisChoice?> showCarRevealDialog(
  BuildContext context, {
  required Uint8List bytes,
  required Recognition recognition,
}) {
  return showShowcaseDialog<AnalysisChoice>(context, (context) {
    final loggedIn = AuthService.isLoggedIn;
    return CarShowcaseDialog(
      label: 'NOUVELLE VOITURE',
      recognition: recognition,
      image: FramedImage(bytes: bytes, box: recognition.box),
      actions: ShowcaseActions(
        primary: FilledButton(
          onPressed: () => Navigator.pop(
            context,
            loggedIn ? AnalysisChoice.addToLibrary : AnalysisChoice.login,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: SpotItColors.accent,
            foregroundColor: SpotItColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: ShowcaseActionLabel(
            icon: loggedIn ? Icons.add_circle_outline : Icons.login,
            text: loggedIn
                ? 'Ajouter à la bibliothèque'
                : 'Se connecter pour sauvegarder',
          ),
        ),
      ),
    );
  });
}
