import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/recognition.dart';
import '../services/auth_service.dart';
import '../widgets/framed_image.dart';
import '../widgets/spot_it_widgets.dart';
import 'car_showcase_dialog.dart';

enum AnalysisChoice { addToLibrary, login, wrongCar }

Future<AnalysisChoice?> showCarRevealDialog(
  BuildContext context, {
  required Uint8List bytes,
  required Recognition recognition,
  DetectionBox? box,
  bool corrected = false,
}) {
  return showShowcaseDialog<AnalysisChoice>(context, (context) {
    final loggedIn = AuthService.isLoggedIn;
    return CarShowcaseDialog(
      label: corrected ? 'VOITURE CORRIGÉE' : 'NOUVELLE VOITURE',
      recognition: recognition,
      showConfidence: !corrected,
      image: FramedImage(bytes: bytes, box: box ?? recognition.box),
      actions: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShowcaseActions(
            primary: SpotItPrimaryButton(
              icon: loggedIn ? Icons.add_circle_outline : Icons.login,
              label: loggedIn
                  ? 'Ajouter à la bibliothèque'
                  : 'Se connecter pour sauvegarder',
              onPressed: () => Navigator.pop(
                context,
                loggedIn ? AnalysisChoice.addToLibrary : AnalysisChoice.login,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, AnalysisChoice.wrongCar),
            child: Text(
              corrected
                  ? 'Choisir une autre voiture'
                  : "Ce n'est pas la bonne voiture ?",
            ),
          ),
        ],
      ),
    );
  });
}
