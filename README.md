# SAE_5 - Spot'It (application Flutter + backend + IA de reconnaissance)

Spot'It est une application mobile qui reconnaît une voiture à partir d'une photo, comme un Pokédex : on scanne une voiture, l'IA donne la marque et le modèle, et on les garde dans sa bibliothèque personnelle.

## Architecture du projet

Le projet est composé de quatre parties qui communiquent entre elles :

1. **L'application Flutter** (`flutter_application_1/`) : l'interface que voit l'utilisateur.
2. **Le backend** (`backend/`) : un serveur Node.js/Express. Il gère les comptes (inscription/connexion), la bibliothèque de photos et il appelle l'IA. L'application Flutter ne parle **jamais** directement à la base de données ni à l'IA, elle passe toujours par ce serveur.
3. **MongoDB Atlas** : la base de données en ligne (comptes utilisateurs et photos de la bibliothèque).
4. **Le service IA** (`ai/`) : un petit serveur Python (Flask) avec deux modèles : un **détecteur** (SSD MobileNet, TensorFlow Lite) qui trouve où est la voiture dans la photo, et un **classifieur** (MobileNetV3) qui dit quelle voiture c'est.

```
Application Flutter  --->  Backend Node.js  --->  MongoDB Atlas
                                 |
                                 +--->  Service IA (Python + TensorFlow)
```

Quand on clique sur « Analyser », la photo est envoyée à l'IA, qui renvoie la marque, le modèle, les années de production, la confiance et la position de la voiture. L'application dessine alors un **cadre rouge** autour de la voiture, puis ouvre un popup avec le résultat :
- **avec compte** : bouton « Ajouter à la bibliothèque » (la photo, le résultat et le cadre sont enregistrés) ;
- **sans compte** : bouton « Se connecter pour sauvegarder » ;
- dans les deux cas, « Fermer » ne sauvegarde rien.

Dans la bibliothèque, un clic sur une photo ouvre sa fiche (cadre, marque, modèle, production, date de découverte, confiance) avec un bouton pour la supprimer.

Pour l'instant le modèle ne connaît que **6 voitures** (voir `ai/models/classes.json`).

## Prérequis à installer avant de commencer

- **Flutter SDK** installé et fonctionnel (vérifie avec `flutter doctor`).
- **Node.js** (version LTS) et **npm** (vérifie avec `node -v` et `npm -v`).
- **Python** pour le service IA. TensorFlow ne supporte pas toujours les versions les plus récentes de Python : si l'installation échoue, utilise Python 3.13.
- Un éditeur de code (VSCode recommandé, avec les extensions Flutter/Dart).
- **Les identifiants de la base MongoDB du groupe** (dans le fichier `backend/.env`, voir plus bas) : demande-les à l'équipe, ils ne sont jamais sur Git.

## Structure du dépôt

```
├── README.md
├── package.json               <- dépendances du backend (Node.js)
├── requirements.txt           <- dépendances Python (IA + service Flask)
├── .gitignore
├── backend/
│   ├── server.js              <- point d'entrée (connexion Mongo + routes)
│   ├── .env                   <- à créer toi-même à partir de .env.example (jamais sur Git)
│   ├── .env.example           <- modèle du fichier .env
│   ├── middleware/
│   │   └── requireAuth.js     <- vérifie le token de connexion
│   ├── models/
│   │   ├── User.js            <- schéma d'un utilisateur
│   │   └── Car.js             <- schéma d'une photo de la bibliothèque
│   ├── routes/
│   │   ├── auth.js            <- /register et /login
│   │   ├── cars.js            <- bibliothèque (ajouter, lister, image, supprimer)
│   │   └── predict.js         <- reconnaissance d'une image sans compte
│   └── services/
│       ├── imageUpload.js     <- vérifie l'image reçue
│       └── recognition.js     <- appelle l'IA et met en forme marque, modèle, années
├── ai/
│   ├── server.py              <- service Flask utilisé par le backend
│   ├── main.py                <- menu pour entraîner / tester le modèle
│   ├── models/                <- modèle entraîné et résultats d'évaluation
│   │   └── detector/          <- détecteur de voitures (SSD MobileNet v1 COCO, TensorFlow, licence Apache 2.0)
│   ├── src/                   <- code d'entraînement, de prédiction et de détection
│   └── README.md              <- documentation du modèle (entraînement, dataset)
└── flutter_application_1/
    └── lib/
        ├── main.dart            <- page d'accueil (photo + analyse)
        ├── car_library_page.dart <- bibliothèque
        ├── car_reveal_dialog.dart <- popup après un scan (ajouter / se connecter / fermer)
        ├── car_card_dialog.dart <- fiche d'une voiture de la bibliothèque (suppression)
        ├── car_showcase_dialog.dart <- popup animé commun (titre, stats, confiance)
        ├── framed_image.dart    <- image avec le cadre rouge autour de la voiture
        ├── car_image.dart       <- chargement d'une photo de la bibliothèque
        ├── recognition.dart     <- résultat de l'IA (marque, modèle, années, confiance, cadre)
        ├── car_service.dart     <- appels HTTP (bibliothèque, reconnaissance)
        ├── auth_service.dart    <- appels HTTP (connexion) et session
        ├── settings_page.dart   <- compte utilisateur
        ├── scanned_car.dart     <- modèle de données d'une voiture
        ├── spot_it_widgets.dart <- widgets partagés (page, en-tête, boutons, confirmation)
        ├── toast.dart           <- petites bulles de message
        └── spot_it_theme.dart   <- couleurs
```

## Lancer le projet

Il faut lancer **trois choses**, chacune dans son propre terminal et dans cet ordre. Laisse-les ouvertes pendant que tu testes.

### 1. Le service IA

À la racine du dépôt :

```
python -m venv ai/.venv
ai\.venv\Scripts\activate
pip install -r requirements.txt
cd ai
python server.py
```

(sur Mac/Linux, l'activation est `source ai/.venv/bin/activate`). Le service écoute sur `http://localhost:5000`. L'installation de TensorFlow est lourde (plusieurs centaines de Mo), mais elle ne se fait qu'une fois.

### 2. Le backend (API + MongoDB)

1. À la racine du dépôt, installe les dépendances Node.js :
   ```
   npm install
   ```
2. Crée ton fichier `backend/.env` : copie `backend/.env.example` et remplis-le avec les vraies valeurs :
   ```
   MONGODB_URI=mongodb+srv://utilisateur:motdepasse@spotitdb.qbodabt.mongodb.net/spotit?retryWrites=true&w=majority
   JWT_SECRET=une_phrase_secrete_a_vous
   PORT=3000
   AI_URL=http://localhost:5000
   ```
   ⚠️ Ce fichier ne doit **jamais** être commité, il contient le mot de passe de la base. `AI_URL` est facultatif : s'il manque, `http://localhost:5000` est utilisé.
3. Lance le serveur :
   ```
   node backend/server.js
   ```
   Le terminal doit afficher `MongoDB OK` puis `Serveur sur le port 3000`.

### 3. L'application Flutter

```
cd flutter_application_1
flutter pub get
flutter run
```

Pour cibler un appareil précis : `flutter devices` puis `flutter run -d <id>` (par exemple `-d windows`, `-d macos`, `-d edge`). Si l'application ne démarre pas correctement : `flutter clean`, `flutter pub get`, `flutter run`.

### Adapter l'adresse du serveur selon ta plateforme

Dans `lib/auth_service.dart`, la constante `host` doit pointer vers le backend :

- App desktop ou navigateur, sur le même ordinateur que le serveur : `http://localhost:3000`
- Émulateur Android : `http://10.0.2.2:3000`
- Téléphone physique (même Wi-Fi que le PC) : `http://IP_LOCALE_DU_PC:3000`

### macOS uniquement : autoriser les connexions réseau sortantes

Sur Mac, l'app est en sandbox par défaut et bloque les requêtes sortantes. Vérifie que ces deux fichiers contiennent `com.apple.security.network.client` à `true` :
- `flutter_application_1/macos/Runner/DebugProfile.entitlements`
- `flutter_application_1/macos/Runner/Release.entitlements`

## Comment vérifier que tout fonctionne

1. Les trois terminaux sont lancés (IA, backend, Flutter).
2. Sans compte : choisis une photo d'une des 6 voitures (par exemple `ai/images/f12.jpg`) puis « Analyser la photo ». Un cadre rouge se dessine autour de la voiture, puis un popup affiche la marque, le modèle, les années et la confiance de l'IA.
3. Va dans les Réglages (engrenage), crée un compte puis reviens à l'accueil.
4. Analyse une photo : elle apparaît dans « Ma bibliothèque ». Clique dessus pour ouvrir sa fiche (cadre, infos) ou la supprimer.
5. Déconnecte-toi puis reconnecte-toi : tes photos sont toujours là (elles sont dans MongoDB).

Si l'IA n'est pas lancée, l'application affiche « Service de reconnaissance indisponible » et rien n'est enregistré.

## Sécurité — à ne jamais pousser sur Git

Le fichier `backend/.env` contient le mot de passe de la base MongoDB et une clé secrète (JWT). Il est dans `.gitignore`. Avant chaque `git add`, vérifie avec `git status` qu'il n'apparaît pas. Pour le partager avec l'équipe, passe-le en message privé.

## Limitations actuelles / à faire ensuite

- Le modèle ne connaît que 6 voitures et répond toujours l'une d'elles, même pour une autre voiture : il faut ajouter un seuil de confiance (« voiture non reconnue »).
- Le détecteur rate parfois une voiture (photo très rapprochée, intérieur) : dans ce cas il n'y a pas de cadre, mais la reconnaissance fonctionne quand même.
- L'IA tourne sur le serveur ; à terme, l'exporter en TensorFlow Lite pour qu'elle tourne directement sur le téléphone.
- Le token de connexion n'est pas sauvegardé sur l'appareil : il faut se reconnecter à chaque redémarrage (prévoir `shared_preferences`).
- Le backend et le service IA ne tournent qu'en local ; pour s'en passer il faudra les héberger en ligne.
