# Spot'It — écran Flutter

Implémentation Flutter de l'écran `spot-it-home` issu de la maquette Figma.

## Lancer le projet

```bash
flutter pub get
flutter run
```

La sélection d'image fonctionne avec l'appareil photo ou la galerie grâce à
`image_picker`. Les permissions natives peuvent être ajoutées selon la cible :

- iOS : `NSCameraUsageDescription` et `NSPhotoLibraryUsageDescription` dans
  `ios/Runner/Info.plist` ;
- Android : la configuration standard d'`image_picker` suffit dans la plupart
  des cas récents.
