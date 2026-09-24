# SAE_5 - Spot'It (application Flutter + backend d'authentification)

Cette branche contient l'application mobile Flutter de l'outil Spot'It **ainsi que le petit serveur backend (Node.js + MongoDB) qui gère la création de compte et la connexion des utilisateurs**.

L'objectif de l'application est de proposer une interface mobile pour scanner une voiture à partir d'une photo, afficher le résultat de l'analyse, enregistrer les véhicules détectés dans une bibliothèque locale et gérer un profil utilisateur (inscription / connexion) dans les paramètres.

## Architecture du projet

Le projet est composé de trois parties qui communiquent entre elles :

1. **L'application Flutter** (`flutter_application_1/`) : l'interface mobile/desktop que voit l'utilisateur.
2. **Le backend** (`backend/`) : un petit serveur Node.js/Express qui reçoit les demandes d'inscription et de connexion, vérifie les mots de passe et parle à la base de données. L'application Flutter ne se connecte **jamais** directement à la base de données, elle passe toujours par ce serveur.
3. **MongoDB Atlas** : la base de données en ligne où sont stockés les comptes utilisateurs (nom, email, mot de passe hashé).

```
Application Flutter  --->  requêtes HTTP  --->  Backend Node.js  --->  MongoDB Atlas
```

## Prérequis à installer avant de commencer

- **Flutter SDK** installé et fonctionnel (vérifie avec `flutter doctor` dans un terminal).
- **Node.js** (version LTS) et **npm**, nécessaires pour faire tourner le backend. Vérifie avec :
  ```
  node -v
  npm -v
  ```
  Si ces commandes ne répondent rien, installe Node.js depuis [nodejs.org](https://nodejs.org) (version LTS), puis redémarre complètement ton éditeur.
- Un éditeur de code (VSCode recommandé, avec les extensions Flutter/Dart).
- **Les identifiants de la base MongoDB du groupe** (dans le fichier `.env`, voir plus bas) — demande-les à l'équipe, ils ne sont jamais sur Git.

## Structure du dépôt

```
SAE_5-flutter_dev/
├── README.md
├── package.json              <- dépendances du backend (Node.js)
├── .gitignore
├── backend/
│   ├── server.js             <- point d'entrée du serveur (connexion Mongo + routes)
│   ├── .env                  <- à créer toi-même à partir de .env.example (jamais sur Git)
│   ├── .env.example          <- modèle du fichier .env à copier
│   ├── models/
│   │   └── User.js           <- schéma MongoDB d'un utilisateur
│   └── routes/
│       └── auth.js           <- routes /register et /login
└── flutter_application_1/
    └── lib/
        ├── main.dart
        ├── auth_service.dart <- appels HTTP vers le backend (login/register)
        ├── settings_page.dart
        ├── car_library_page.dart
        ├── scanned_car.dart
        └── spot_it_theme.dart
```

## 1. Lancer le backend (API + connexion MongoDB)

Le backend doit tourner **avant** de lancer l'application Flutter, et rester ouvert dans un terminal pendant que tu testes.

1. Ouvre un terminal **à la racine du dépôt** (le dossier `SAE_5-flutter_dev`, pas dans `backend/`).

2. Installe les dépendances Node.js :
   ```
   npm install
   ```
   Ça crée un dossier `node_modules/` — ne le touche pas, ne le pousse jamais sur Git (il est dans `.gitignore`).

3. Crée ton fichier `.env` : copie `backend/.env.example`, renomme la copie en `backend/.env`, et remplis-le avec les vraies valeurs (demande-les à l'équipe si tu les as pas) :
   ```
   MONGODB_URI=mongodb+srv://utilisateur:motdepasse@spotitdb.qbodabt.mongodb.net/spotit?retryWrites=true&w=majority
   JWT_SECRET=une_phrase_secrete_a_vous
   PORT=3000
   ```
   ⚠️ Ce fichier ne doit **jamais** être commité, il contient le mot de passe de la base de données.

4. Lance le serveur :
   ```
   node backend/server.js
   ```
   Si tout va bien, le terminal affiche :
   ```
   MongoDB OK
   Serveur sur le port 3000
   ```
   Laisse ce terminal ouvert tant que tu testes l'application.

## 2. Lancer l'application Flutter

1. Ouvrir un terminal dans le dossier de l'application :
   ```
   cd flutter_application_1
   ```
2. Installer les dépendances :
   ```
   flutter pub get
   ```
3. Lancer l'application :
   ```
   flutter run
   ```
4. Si tu veux cibler un appareil précis :
   - macOS : `flutter run -d macos`
   - Windows : `flutter run -d windows`
   - Android : `flutter devices` puis `flutter run -d <device-id>`
   - Web : `flutter run -d chrome`
5. Si l'application ne démarre pas correctement, réinitialise le cache :
   ```
   flutter clean
   flutter pub get
   flutter run
   ```

### ⚠️ Adapter l'adresse du serveur selon ta plateforme

Dans `lib/auth_service.dart`, la constante `baseUrl` doit pointer vers l'adresse du backend. Adapte-la selon où tu testes :

- App desktop (macOS/Windows/Linux) ou navigateur, sur le même ordinateur que le serveur :
  `http://localhost:3000/api/auth`
- Émulateur Android :
  `http://10.0.2.2:3000/api/auth`
- Téléphone physique (sur le même Wi-Fi que l'ordinateur qui fait tourner le serveur) :
  `http://IP_LOCALE_DU_PC:3000/api/auth` (trouve l'IP avec `ipconfig` sur Windows ou dans Réglages réseau sur Mac)

### macOS uniquement : autoriser les connexions réseau sortantes

Sur Mac, l'app est en sandbox par défaut et bloque les requêtes réseau sortantes. Si tu as une erreur réseau au moment de t'inscrire/te connecter, vérifie que ces deux fichiers contiennent bien la permission `com.apple.security.network.client` à `true` :
- `flutter_application_1/macos/Runner/DebugProfile.entitlements`
- `flutter_application_1/macos/Runner/Release.entitlements`

## Comment vérifier que tout fonctionne

1. Backend lancé (`node backend/server.js`), terminal laissé ouvert.
2. Application Flutter lancée (`flutter run`).
3. Aller dans les Réglages (icône engrenage) → onglet inscription → remplir le formulaire → "S'inscrire".
4. Vérifier dans MongoDB Atlas (Data Explorer) que le compte apparaît dans la base `spotit`, collection `users`, avec un mot de passe **hashé** (jamais en clair, ça doit ressembler à `$2b$10$...`).
5. Se déconnecter puis se reconnecter avec le même email/mot de passe pour tester le login.

## Fichiers de la lib (Flutter)

### `main.dart`
Point d'entrée de l'application. Contient l'initialisation Flutter et la configuration de la fenêtre desktop, la création de l'application principale `SpotItApp`, la page d'accueil `SpotItHomePage`, la gestion du choix entre caméra et galerie, la logique de sélection d'une image, le bouton d'analyse et l'ajout d'un véhicule dans la bibliothèque, ainsi que la navigation vers la bibliothèque et vers les paramètres.

### `car_library_page.dart`
Page "Ma bibliothèque". Affiche la liste des voitures scannées, une grille de cartes avec l'image, le nom reconnu et la date du scan, l'état vide quand aucune voiture n'a encore été ajoutée, et le bouton retour vers l'écran principal.

### `settings_page.dart`
Page des paramètres et du compte utilisateur. Gère le mode connexion/inscription, la validation des formulaires, l'édition du profil, la déconnexion, la suppression du compte. Depuis l'ajout du backend, cette page **appelle réellement `AuthService`** (voir `auth_service.dart`) au lieu de simuler la connexion localement : les identifiants sont vérifiés côté serveur et en base de données.

### `auth_service.dart` (nouveau)
Contient les appels réseau vers le backend pour l'inscription et la connexion. Envoie les informations du formulaire aux routes `/api/auth/register` et `/api/auth/login`, et renvoie soit les infos de l'utilisateur (nom, email) soit une erreur affichée à l'écran.

### `scanned_car.dart`
Modèle de données représentant une voiture scannée : chemin de l'image, nom reconnu par l'IA, date du scan.

### `spot_it_theme.dart`
Centralise la palette graphique de l'application (fond, cartes, bordures, texte secondaire, couleur d'accentuation, alertes) pour une interface cohérente.

## Fichiers du backend

### `backend/server.js`
Point d'entrée du serveur : charge les variables d'environnement (`.env`), connecte Mongoose à MongoDB Atlas, démarre le serveur Express et branche les routes d'authentification sur `/api/auth`.

### `backend/models/User.js`
Définit le schéma Mongoose d'un utilisateur : `name`, `email` (unique) et `password`. Le mot de passe est **toujours stocké hashé** (avec bcrypt), jamais en clair.

### `backend/routes/auth.js`
Contient les deux routes principales :
- `POST /api/auth/register` : crée un compte, hash le mot de passe avant de l'enregistrer en base.
- `POST /api/auth/login` : vérifie l'email et le mot de passe, renvoie un token JWT valable 7 jours si c'est correct.

## Sécurité — à ne jamais pousser sur Git

Le fichier `backend/.env` contient le mot de passe de la base MongoDB et une clé secrète (JWT). Il est listé dans `.gitignore` et ne doit **jamais** être commité. Avant chaque `git add`, vérifie avec `git status` que `.env` n'apparaît pas dans la liste. Pour le partager avec l'équipe, passe-le en message privé, jamais sur un repo public ou un Discord/Slack accessible à tous.

## Ce que fait l'application dans son état actuel

L'application permet aujourd'hui de choisir une image, de créer un compte et de se connecter (vérifié en base de données), d'ajouter un élément à la bibliothèque, de naviguer entre les écrans, avec une interface mobile élégante et cohérente. La partie "reconnaissance IA" n'est pas encore branchée : le texte "Modèle reconnu par l'IA" est un texte de remplacement à remplacer par le vrai résultat du modèle dès qu'il sera intégré.

## Limitations actuelles / à faire ensuite

- Le token reçu après connexion n'est pas encore sauvegardé sur l'appareil : l'utilisateur doit se reconnecter à chaque redémarrage de l'app (prévoir le package `shared_preferences` pour corriger ça).
- Le backend ne tourne pour l'instant qu'en local sur la machine de développement : pour que l'app marche sans avoir le serveur d'un développeur allumé, il faudra l'héberger en ligne (Render ou Railway ont un plan gratuit suffisant).
- Le modèle de reconnaissance IA n'est pas encore intégré.

## Résumé rapide

Cette branche contient la version Flutter de Spot'It (scan d'images, bibliothèque, paramètres) ainsi qu'un backend Node.js + MongoDB qui gère l'inscription et la connexion des utilisateurs. Pour tout lancer : `npm install` puis `node backend/server.js` à la racine (backend), et `flutter pub get` puis `flutter run` dans `flutter_application_1/` (application).
