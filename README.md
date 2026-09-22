# SAE_5 - Branche Flutter Spot'It

Cette branche est dédiée au développement de l’application mobile Flutter de l’outil Spot'It.

L’objectif de cette partie est de proposer une interface mobile pour scanner une voiture à partir d’une photo, afficher le résultat de l’analyse, enregistrer les véhicules détectés dans une bibliothèque locale et gérer un profil utilisateur dans les paramètres.

## Ce que contient cette branche

Cette branche concerne uniquement l’application Flutter, donc la partie front-end mobile du projet. Elle ne décrit pas le modèle IA de classification d’images, mais elle prépare l’intégration de l’interface utilisateur autour du scan d’un véhicule.

L’application permet :

- de prendre une photo depuis l’appareil photo ou de choisir une image depuis la galerie ;
- de lancer une analyse visuelle d’une voiture ;
- d’ajouter le résultat dans une bibliothèque locale ;
- de consulter les voitures déjà scannées ;
- de gérer un compte utilisateur et les paramètres.

## Technologies utilisées

- Flutter
- Dart
- Material 3
- Google Fonts
- image_picker
- window_manager

## Comment lancer l’application Flutter

1. Ouvrir un terminal dans le dossier de l’application :

   `cd flutter_application_1`

2. Installer les dépendances :

   `flutter pub get`

3. Lancer l’application :

   `flutter run`

4. Si tu veux cibler un appareil précis :

   - Windows : `flutter run -d windows`
   - Android : `flutter devices` puis `flutter run -d <device-id>`
   - Web : `flutter run -d chrome`

5. Si l’application ne démarre pas correctement, tu peux réinitialiser le cache :

   `flutter clean`
   `flutter pub get`
   `flutter run`

## Structure principale du projet

Le cœur de l’application se trouve dans le dossier `flutter_application_1/lib`.

### Fichiers de la lib

#### `main.dart`
Ce fichier est le point d’entrée de l’application.

Il contient :

- l’initialisation Flutter et la configuration de la fenêtre desktop ;
- la création de l’application principale `SpotItApp` ;
- la page d’accueil `SpotItHomePage` ;
- la gestion du choix entre caméra et galerie ;
- la logique de sélection d’une image ;
- le bouton d’analyse et l’ajout d’un véhicule dans la bibliothèque ;
- la navigation vers la bibliothèque et vers les paramètres.

En pratique, c’est le fichier qui orchestre la navigation et l’écran principal de l’application.

#### `car_library_page.dart`
Ce fichier correspond à la page “Ma bibliothèque”.

Il affiche :

- la liste des voitures scannées ;
- une grille de cartes contenant l’image, le nom reconnu et la date du scan ;
- l’état vide quand aucune voiture n’a encore été ajoutée ;
- le bouton retour pour revenir à l’écran principal.

C’est la page où l’utilisateur peut revoir les véhicules déjà analysés.

#### `settings_page.dart`
Ce fichier contient la page des paramètres et le système de compte utilisateur.

Il gère :

- le mode connexion / inscription ;
- la validation des formulaires ;
- l’édition du profil ;
- la déconnexion ;
- la suppression du compte ;
- l’affichage de boutons et champs stylisés pour l’interface.

C’est donc l’écran dédié à la gestion du compte utilisateur.

#### `scanned_car.dart`
C’est le modèle de données utilisé pour représenter une voiture scannée.

Il contient :

- le chemin de l’image ;
- le nom reconnu par l’IA ;
- la date du scan.

Ce fichier sert de structure pour stocker les informations d’un véhicule ajouté à la bibliothèque.

#### `spot_it_theme.dart`
Ce fichier centralise la palette graphique de l’application.

Il définit les couleurs utilisées pour :

- le fond global ;
- les cartes et panneaux ;
- les bordures ;
- le texte secondaire ;
- la couleur d’accentuation et les alertes.

Il permet d’avoir une interface visuelle cohérente et uniforme dans toute l’application.

## Ce que fait l’application dans son état actuel

L’application actuelle est une maquette fonctionnelle de l’interface mobile Spot'It. Elle ne connecte pas encore un modèle de reconnaissance IA réel, mais elle prépare l’intégration de celui-ci.

Pour l’instant, elle permet :

- de choisir une image ;
- d’ajouter un élément à la bibliothèque ;
- de naviguer entre les écrans ;
- d’afficher une interface de type application mobile élégante et cohérente.

La partie “modèle reconnu par l’IA” est encore un texte de remplacement à remplacer par le vrai résultat de l’analyse dès que le modèle sera intégré.

## Résumé rapide

Cette branche correspond à la version Flutter de la branche SAE_5 dédiée à l’interface utilisateur du projet Spot'It. Elle permet de visualiser le produit final attendu côté mobile, avec scan d’images, gestion de bibliothèque et paramètres utilisateur.
