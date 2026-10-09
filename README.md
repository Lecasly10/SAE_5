# Spot'It — Scanne une voiture, l'IA la reconnaît, collectionne-la

> Application mobile (Flutter) qui reconnaît une voiture à partir d'une photo grâce à l'intelligence artificielle, l'entoure d'un cadre rouge et l'ajoute à une bibliothèque personnelle, comme un Pokédex.

Projet réalisé en équipe dans le cadre de la **SAE 5.01 — Développement avancé** (BUT Informatique) : *« Développement d'une application mobile de reconnaissance et de classification d'objets avec IA »*.

| | |
|---|---|
| **Dépôt** | https://github.com/Lecasly10/SAE_5 |
| **Équipe** | Matteo LAURI, Evan STILLE, Thomas FREY, Victorien DENOYELLE |
| **Suivi des tâches** | https://trello.com/b/TlcXJrDZ/sae5 |
| **Testé sur** | Windows 11, Node.js 26, Python 3.13, TensorFlow 2.21, Flutter 3.47, navigateur Edge |

<p align="center">
  <img src="docs/screenshots/home.png" alt="Écran d'accueil" width="190">
  <img src="docs/screenshots/scan-result.png" alt="Résultat d'un scan avec cadre rouge" width="190">
  <img src="docs/screenshots/library.png" alt="Bibliothèque" width="190">
  <img src="docs/screenshots/car-card.png" alt="Fiche d'une voiture" width="190">
</p>

---

## Sommaire

1. [À quoi ça sert ?](#1-à-quoi-ça-sert-)
2. [Comment ça marche](#2-comment-ça-marche)
3. [Ce qu'il faut avant de commencer (prérequis)](#3-ce-quil-faut-avant-de-commencer-prérequis)
4. [Installation pas à pas — Windows (de zéro)](#4-installation-pas-à-pas--windows-de-zéro)
5. [Installation — Linux et macOS](#5-installation--linux-et-macos)
6. [Configurer la base de données (MongoDB Atlas)](#6-configurer-la-base-de-données-mongodb-atlas)
7. [Lancer l'application](#7-lancer-lapplication)
8. [Tester que tout fonctionne](#8-tester-que-tout-fonctionne)
9. [Problèmes fréquents et solutions](#9-problèmes-fréquents-et-solutions)
10. [Structure du projet](#10-structure-du-projet)
11. [Référence technique (API, base de données, IA)](#11-référence-technique-api-base-de-données-ia)
12. [Travailler sur le projet (Git, bonnes pratiques)](#12-travailler-sur-le-projet-git-bonnes-pratiques)
13. [État d'avancement par rapport au sujet](#13-état-davancement-par-rapport-au-sujet)
14. [Limites connues et suite](#14-limites-connues-et-suite)
15. [Mini-lexique](#15-mini-lexique)
16. [Crédits et licences](#16-crédits-et-licences)

---

## 1. À quoi ça sert ?

Imagine un Pokédex, mais avec de vraies voitures :

1. Tu prends une photo d'une voiture (ou tu en choisis une dans ta galerie).
2. L'IA **repère** la voiture et dessine un **cadre rouge** autour.
3. Elle **identifie** la marque et le modèle (par exemple *Ferrari F12 Berlinetta, 2012 – 2015*) et indique sa **confiance** en pourcentage.
4. Si tu as un compte, tu peux **ajouter la voiture à ta bibliothèque**. Elle est conservée dans ton compte : tu la retrouves à chaque connexion.

L'idée est née parce que plusieurs membres de l'équipe sont passionnés d'automobile, et que l'un d'eux photographie des voitures de collection (« carspotting »).

**Pour l'instant, l'IA connaît 6 voitures** : Citroën 2CV, Ferrari F12 Berlinetta, Fiat 500 Abarth, Ford Mustang, Jeep Grand Cherokee et Toyota Hilux Double Cab. Si tu scannes une autre voiture, elle te répondra quand même l'une des 6 (voir [Limites connues](#14-limites-connues-et-suite)).

---

## 2. Comment ça marche

Le projet est composé de **quatre parties** qui se parlent entre elles :

| Partie | Dossier | Rôle | Technologies |
|---|---|---|---|
| **Application** | `flutter_application_1/` | L'écran que voit l'utilisateur (photo, popup, bibliothèque, compte) | Flutter / Dart |
| **Backend** | `backend/` | Le « chef d'orchestre » : gère les comptes, la bibliothèque et appelle l'IA | Node.js, Express |
| **Base de données** | *(en ligne)* | Garde les comptes et les photos | MongoDB Atlas |
| **Service IA** | `ai/` | Trouve la voiture dans la photo et dit laquelle c'est | Python, Flask, TensorFlow |

> ⚠️ L'application ne parle **jamais** directement à la base de données ni à l'IA : elle passe toujours par le backend. C'est plus sûr (les mots de passe de la base restent côté serveur).

```mermaid
flowchart LR
    A[Application Flutter] -->|requêtes HTTP| B[Backend Node.js]
    B --> C[(MongoDB Atlas)]
    B -->|photo| D[Service IA Python]
    D -->|voiture + confiance + cadre| B
```

### Ce qui se passe quand on clique sur « Analyser »

```mermaid
sequenceDiagram
    participant U as Utilisateur
    participant App as Application
    participant API as Backend
    participant IA as Service IA
    participant DB as MongoDB
    U->>App: Choisit une photo, clique sur Analyser
    App->>API: POST /api/predict (photo)
    API->>IA: POST /predict (photo)
    IA-->>API: classe + confiance + position de la voiture
    API-->>App: marque, modèle, années, confiance, cadre
    App->>U: Cadre rouge puis popup du résultat
    opt Utilisateur connecté qui clique sur "Ajouter"
        App->>API: POST /api/cars (photo + token)
        API->>IA: nouvelle analyse (sécurité)
        API->>DB: enregistre la voiture
        API-->>App: voiture ajoutée
    end
```

### Les deux modèles d'IA

1. **Le détecteur** (`ai/models/detector/detect.tflite`) : un modèle *SSD MobileNet* déjà entraîné sur la base d'images COCO. Il sait trouver des voitures dans une photo et renvoie un rectangle. C'est lui qui permet de dessiner le **cadre rouge**.
2. **Le classifieur** (`ai/models/spotit_mobilenet.keras`) : un modèle *MobileNetV3Small* entraîné par l'équipe sur 6 voitures (technique du *transfer learning* : on réutilise un modèle qui sait déjà reconnaître des formes et on lui apprend seulement à choisir entre nos 6 voitures). C'est lui qui donne la **marque, le modèle et la confiance**.

#### La « confiance » en clair
La confiance n'est **pas** « la probabilité d'avoir raison ». C'est la part de préférence du modèle pour cette voiture **par rapport aux 5 autres**. Si deux voitures se ressemblent (Ferrari F12 et Ford Mustang), le modèle hésite et la confiance se partage : une bonne réponse peut donc n'avoir que 40 à 60 %. Avec 6 voitures, répondre au hasard donnerait environ 17 %.

La jauge de l'application est verte à partir de 70 %, orange à partir de 40 %, rouge en dessous.

---

## 3. Ce qu'il faut avant de commencer (prérequis)

### Matériel et système
- Un ordinateur sous **Windows 10/11** (guide complet ci-dessous), **Linux** ou **macOS**.
- **Environ 8 Go d'espace disque libre** (Flutter, TensorFlow, dépendances).
- Une **connexion Internet** (téléchargements, base de données en ligne, polices de l'application).

### Logiciels à installer

| Logiciel | À quoi il sert | Version |
|---|---|---|
| **Git** | Télécharger le projet et suivre les modifications | récente |
| **Node.js** (avec npm) | Faire tourner le backend | 20 LTS ou plus récent |
| **Python** | Faire tourner l'IA | **3.10 à 3.13** (⚠️ pas 3.14) |
| **Flutter SDK** | Construire et lancer l'application | 3.x récente |
| **Un navigateur** (Edge ou Chrome) | Afficher l'application pendant les tests | — |
| *VS Code* (facultatif) | Éditeur de code | — |

### Comptes et accès
- **Accès à la base MongoDB du groupe** : demande le fichier `backend/.env` à un membre de l'équipe (il contient des mots de passe et n'est jamais sur GitHub).
  *Sans ça, tu peux créer ta propre base gratuite : voir [section 6](#6-configurer-la-base-de-données-mongodb-atlas).*

---

## 4. Installation pas à pas — Windows (de zéro)

On suppose un Windows 11 « vierge ». Chaque commande se tape dans **PowerShell** : appuie sur la touche **Windows**, tape `PowerShell`, appuie sur Entrée.

### Étape 1 — Installer Git, Node.js et Python

Windows 11 contient `winget`, un installateur en ligne de commande :

```powershell
winget install --id Git.Git -e
```
```powershell
winget install --id OpenJS.NodeJS.LTS -e
```
```powershell
winget install --id Python.Python.3.13 -e
```

> Si `winget` n'existe pas, télécharge les trois logiciels sur leurs sites officiels : [git-scm.com](https://git-scm.com), [nodejs.org](https://nodejs.org) (version LTS) et [python.org](https://www.python.org/downloads/) (3.13, en cochant « Add python.exe to PATH »).

**Ferme complètement PowerShell et rouvre-le** (sinon les nouveaux programmes ne sont pas reconnus), puis vérifie :

```powershell
git --version
node -v
npm -v
py -3.13 --version
```
Chaque commande doit afficher un numéro de version. Pour Python, tu dois voir `Python 3.13.x`.

### Étape 2 — Installer Flutter

1. Va sur https://docs.flutter.dev/get-started/install/windows et télécharge le fichier **zip** du SDK Flutter (environ 1,8 Go).
2. Fais un clic droit sur le zip → **Extraire tout…** et choisis comme destination `C:\` pour obtenir le dossier `C:\flutter`.
   ⚠️ Évite un dossier avec des espaces ou `Program Files`.
3. Ajoute Flutter à ton PATH (pour que la commande `flutter` soit reconnue partout) :
   ```powershell
   [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\flutter\bin", "User")
   ```
4. **Ferme et rouvre PowerShell**, puis vérifie :
   ```powershell
   flutter doctor
   ```
   La première exécution télécharge des outils (quelques minutes). Il est **normal** que `flutter doctor` affiche des croix pour Android Studio ou Visual Studio : on n'en a pas besoin pour tester dans le navigateur. Ce qui compte : la ligne **Flutter** et la ligne **Connected device** (avec « Edge (web) »).

### Étape 3 — Activer le « Mode développeur » de Windows

Flutter en a besoin pour installer les plugins de l'application.

```powershell
start ms-settings:developers
```
Dans la fenêtre qui s'ouvre, passe **Mode développeur** sur **Activé** et accepte la confirmation.

### Étape 4 — Télécharger le projet

Choisis un dossier où le mettre (par exemple le Bureau) :

```powershell
cd $HOME\Desktop
```
```powershell
git clone https://github.com/Lecasly10/SAE_5.git
```
```powershell
cd SAE_5
```

> Si cette version du projet n'est pas encore sur la branche `main`, passe sur la branche d'intégration : `git switch ia-integration`

Toutes les commandes suivantes se lancent **depuis ce dossier `SAE_5`** (appelé « racine du projet »), sauf indication contraire.

### Étape 5 — Installer l'IA (Python)

On crée un « environnement virtuel » : un dossier à part où s'installent les bibliothèques Python du projet, sans toucher au reste de ton ordinateur.

```powershell
py -3.13 -m venv ai\.venv
```
```powershell
ai\.venv\Scripts\python.exe -m pip install -r requirements.txt
```
⏳ C'est long : TensorFlow seul pèse environ 335 Mo, compte 5 à 10 minutes en tout. Ça ne se fait qu'**une seule fois**.

> 💡 On appelle directement le Python de l'environnement (`ai\.venv\Scripts\python.exe`) au lieu de l'« activer » : ça évite les erreurs de scripts bloqués qu'on rencontre selon le terminal utilisé.

### Étape 6 — Installer le backend (Node.js)

Toujours à la racine du projet :

```powershell
npm install
```

### Étape 7 — Créer le fichier de configuration `.env`

Ce fichier contient les mots de passe : il reste **sur ton ordinateur** et n'est jamais envoyé sur GitHub.

```powershell
Copy-Item backend\.env.example backend\.env
```
Ouvre `backend\.env` (avec le Bloc-notes ou VS Code) et remplis-le :

```
MONGODB_URI=mongodb+srv://UTILISATEUR:MOTDEPASSE@spotitdb.qbodabt.mongodb.net/spotit?retryWrites=true&w=majority
JWT_SECRET=une-longue-phrase-secrete-de-ton-choix
PORT=3000
AI_URL=http://localhost:5000
```

| Variable | Rôle |
|---|---|
| `MONGODB_URI` | Adresse de connexion à la base. Demande-la à l'équipe, ou crée la tienne ([section 6](#6-configurer-la-base-de-données-mongodb-atlas)). Garde bien `/spotit` avant le `?`. |
| `JWT_SECRET` | Clé secrète qui signe les connexions. Mets une longue phrase quelconque. |
| `PORT` | Port du backend. Laisse `3000`. |
| `AI_URL` | Adresse du service IA. Laisse `http://localhost:5000` (facultatif : c'est la valeur par défaut). |

### Étape 8 — Préparer l'application Flutter

```powershell
cd flutter_application_1
```
```powershell
flutter pub get
```
```powershell
cd ..
```

✅ L'installation est terminée. Passe à la [section 7](#7-lancer-lapplication).

---

## 5. Installation — Linux et macOS

> ℹ️ Ces instructions sont l'adaptation des étapes Windows. L'équipe a testé le projet sur **Windows 11 + Edge** ; sous Linux/macOS le principe est identique mais certaines commandes peuvent demander des ajustements.

### Linux (exemple Ubuntu/Debian)

```bash
sudo apt update
sudo apt install -y git curl unzip xz-utils python3 python3-venv nodejs npm
```
- **Python** : TensorFlow 2.21 fonctionne avec Python 3.10 à 3.13. Vérifie avec `python3 --version` (si c'est 3.14, installe une version plus ancienne).
- **Node.js** : si `node -v` affiche une version inférieure à 20, installe une version récente avec [nvm](https://github.com/nvm-sh/nvm) ou NodeSource.
- **Flutter** : suis https://docs.flutter.dev/get-started/install/linux (ou `sudo snap install flutter --classic`), puis vérifie avec `flutter doctor`.
- **Navigateur** : installe Chrome ou Chromium, puis lance l'appli avec `flutter run -d chrome`.

```bash
git clone https://github.com/Lecasly10/SAE_5.git
cd SAE_5
python3 -m venv ai/.venv
ai/.venv/bin/python -m pip install -r requirements.txt
npm install
cp backend/.env.example backend/.env      # puis remplis backend/.env (voir étape 7)
cd flutter_application_1 && flutter pub get && cd ..
```

Lancement (3 terminaux, voir [section 7](#7-lancer-lapplication)) :
```bash
cd ai && .venv/bin/python server.py                  # terminal 1
cd backend && node server.js                         # terminal 2
cd flutter_application_1 && flutter run -d chrome    # terminal 3
```

### macOS

- Installe [Homebrew](https://brew.sh), puis `brew install git node python@3.13` et Flutter (https://docs.flutter.dev/get-started/install/macos).
- Mêmes commandes que Linux (remplace `chrome` par `macos` si tu veux l'application native).
- ⚠️ L'application macOS est en « sandbox » et bloque le réseau par défaut : vérifie que `macos/Runner/DebugProfile.entitlements` et `macos/Runner/Release.entitlements` (dans `flutter_application_1/`) contiennent `com.apple.security.network.client` à `true`.

---

## 6. Configurer la base de données (MongoDB Atlas)

**Si ton équipe te donne déjà le fichier `.env`, tu peux sauter cette section** — il faut juste (une fois) faire autoriser ton IP, voir [Problèmes fréquents](#9-problèmes-fréquents-et-solutions).

Pour créer **ta propre base gratuite** :

1. Crée un compte sur https://www.mongodb.com/cloud/atlas et choisis l'offre gratuite **M0**.
2. **Crée un cluster** (n'importe quelle région proche) et attends qu'il soit prêt.
3. Menu **Database Access** → *Add New Database User* : choisis un nom d'utilisateur et un mot de passe (note-les).
4. Menu **Network Access** → *Add IP Address* → **Add Current IP Address** (ou `0.0.0.0/0` pour autoriser tout le monde, acceptable pour un projet de cours mais pas en production).
5. Menu **Database** → bouton **Connect** → **Drivers** : copie l'adresse qui ressemble à `mongodb+srv://utilisateur:<password>@cluster0.xxxxx.mongodb.net/`.
6. Colle-la dans `backend/.env` (`MONGODB_URI`) en :
   - remplaçant `<password>` par ton mot de passe ;
   - ajoutant le nom de la base `spotit` juste avant le `?`.

> ⚠️ Si ton mot de passe contient des caractères spéciaux (`@`, `#`, `/`, `:`), il faut les « encoder » dans l'adresse (par exemple `@` devient `%40`). Le plus simple : choisis un mot de passe sans caractères spéciaux.

La base et ses collections (`users`, `cars`) sont créées automatiquement au premier usage.

---

## 7. Lancer l'application

Il y a **trois choses à lancer**, chacune dans **son propre terminal**, **dans cet ordre**. Laisse-les ouvertes pendant que tu testes.

> Pour ouvrir un nouveau terminal PowerShell : touche Windows → `PowerShell`. À chaque fois, commence par aller dans le dossier du projet (`cd $HOME\Desktop\SAE_5`).

### Terminal 1 — Le service IA

```powershell
cd ai
```
```powershell
.venv\Scripts\python.exe server.py
```
⏳ Patiente 10 à 30 secondes (TensorFlow charge les modèles) jusqu'à voir :
```
 * Running on http://127.0.0.1:5000
```

### Terminal 2 — Le backend

```powershell
cd backend
```
```powershell
node server.js
```
Tu dois voir :
```
MongoDB OK
Serveur sur le port 3000
```

### Terminal 3 — L'application

```powershell
cd flutter_application_1
```
```powershell
flutter run -d edge
```
⏳ La première compilation prend 1 à 2 minutes. **Edge s'ouvre tout seul** avec l'application.

Pendant que `flutter run` tourne, tu peux taper dans son terminal :
- `r` : recharger après une modification du code ;
- `R` (majuscule) : redémarrer l'application ;
- `q` : quitter.

> 📱 **Autres plateformes** : `flutter devices` liste ce qui est disponible. L'application native Windows (`-d windows`) demande Visual Studio avec la charge de travail « Développement Desktop en C++ » ; un émulateur ou téléphone Android demande Android Studio. Pour ces cas, change l'adresse du serveur dans [`lib/auth_service.dart`](flutter_application_1/lib/auth_service.dart) (constante `host`) : `http://10.0.2.2:3000` pour l'émulateur Android, ou `http://IP_DE_TON_PC:3000` pour un vrai téléphone sur le même Wi-Fi.

### Tout arrêter

Dans chaque terminal, appuie sur **Ctrl + C**. Si un programme reste bloqué en arrière-plan :
```powershell
Get-NetTCPConnection -LocalPort 3000,5000 -State Listen | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
```

---

## 8. Tester que tout fonctionne

### Test de l'application (parcours complet)

1. **Sans compte** : clique sur **Insérer une photo** et choisis `ai/images/f12.jpg` (ou une image de `ai/dataset_small/test/`).
   - Dans l'application web, le bouton « Prendre une photo » ouvre le même sélecteur de fichiers ; sur téléphone il ouvre l'appareil photo.
2. Clique sur **Analyser la photo**.
   - Un **cadre rouge** se dessine sur la voiture.
   - Un **popup** s'ouvre : *FERRARI — F12 Berlinetta*, production *2012 – 2015*, confiance (autour de 50-60 %).
   - Le gros bouton affiche **« Se connecter pour sauvegarder »**.
3. Clique sur **Fermer**, puis sur l'**engrenage** (en haut à droite) → **S'inscrire** (nom, e-mail, mot de passe d'au moins 6 caractères). Reviens à l'accueil avec la flèche.
4. Refais un scan : le gros bouton est maintenant **« Ajouter à la bibliothèque »**. Clique dessus : une bulle te confirme l'ajout.
5. Ouvre la **bibliothèque** (livre en haut à gauche) : ta voiture est là. Clique dessus pour ouvrir sa **fiche** (cadre, production, date de découverte, confiance).
6. Clique sur **Supprimer de la bibliothèque** (puis confirme) : elle disparaît.
7. Déconnecte-toi puis reconnecte-toi : tes voitures sont toujours là (elles sont dans MongoDB).

### Tester chaque partie séparément (utile en cas de problème)

**Service IA** — doit renvoyer un JSON avec `label`, `confidence` et `box` :
```powershell
curl.exe -X POST --data-binary "@ai/images/f12.jpg" http://localhost:5000/predict
```

**Backend** — doit répondre `Email ou mot de passe incorrect` (c'est le bon signe : il fonctionne et lit la base) :
```powershell
curl.exe -X POST http://localhost:3000/api/auth/login -H "Content-Type: application/json" -d "{}"
```

**Chaîne complète sans compte** — le backend demande à l'IA et renvoie la marque, le modèle, les années et la confiance (voir l'API en [section 11](#11-référence-technique-api-base-de-données-ia)).

### Photos de test
- `ai/images/` : 3 photos d'exemple (`f12.jpg`, `mx5.jpg`, `z4.jpg`). `mx5.jpg` et `z4.jpg` ne sont **pas** parmi les 6 voitures connues : l'IA se trompera (c'est attendu, voir les limites).
- `ai/dataset_small/test/<voiture>/` : 186 photos de test des 6 voitures.

### Vérifier la qualité du code Flutter
```powershell
cd flutter_application_1
dart analyze lib
```
Résultat attendu : `No issues found!`. *(Le dépôt ne contient pas encore de tests automatiques : la vérification se fait à la main avec le parcours ci-dessus.)*

---

## 9. Problèmes fréquents et solutions

Les erreurs ci-dessous sont soit **rencontrées pendant le projet**, soit **très probables** pour quelqu'un qui installe le projet pour la première fois.

### Installation et environnement

| Message ou symptôme | Cause | Solution |
|---|---|---|
| `flutter : The term 'flutter' is not recognized…` | Flutter n'est pas dans le PATH, ou le terminal est ancien | Refais l'[étape 2](#étape-2--installer-flutter) puis **ferme et rouvre** le terminal |
| `git`, `node` ou `py` non reconnu | Terminal ouvert avant l'installation | Ferme et rouvre PowerShell |
| `Building with plugins requires symlink support. Please enable Developer Mode` | Mode développeur Windows désactivé | `start ms-settings:developers` puis active **Mode développeur** |
| `Unable to find suitable Visual Studio toolchain` (avec `-d windows`) | Visual Studio n'est pas installé | Utilise `flutter run -d edge`, ou installe Visual Studio avec la charge « Développement Desktop en C++ » |
| `Cannot find Chrome executable` dans `flutter doctor` | Chrome n'est pas installé | Sans importance si tu utilises Edge (`-d edge`) |
| `ERROR: No matching distribution found for tensorflow==2.21.0` | Mauvaise version de Python (3.14) ou `pip` pas lancé dans le bon environnement | Utilise Python **3.13** et lance bien `ai\.venv\Scripts\python.exe -m pip install -r requirements.txt` (voir [étape 5](#étape-5--installer-lia-python)) |
| `Activate.ps1` : erreur de script, ou `Set-ExecutionPolicy is not recognized` | Script d'activation prévu pour PowerShell, lancé dans `cmd` (ou stratégie d'exécution bloquante) | Ne pas activer l'environnement : appelle directement `ai\.venv\Scripts\python.exe` comme dans ce guide |
| `ModuleNotFoundError: No module named 'flask'` (ou `numpy`, `tensorflow`, `matplotlib`) | Tu as lancé le Python global au lieu de celui de l'environnement, ou l'installation n'a pas abouti | Relance avec `.venv\Scripts\python.exe` et refais `pip install -r requirements.txt` |
| Le dossier `ai\.venv` n'est pas dans le projet | Commande lancée depuis un mauvais dossier | Place-toi à la racine du projet (`dir` doit montrer `backend`, `ai`, `flutter_application_1`) puis recrée l'environnement |

### Backend et base de données

| Message ou symptôme | Cause | Solution |
|---|---|---|
| `MongooseError: The uri parameter to openUri() must be a string, got "undefined"` et `injected env (0) from .env` | Le fichier `backend\.env` est absent ou vide | Refais l'[étape 7](#étape-7--créer-le-fichier-de-configuration-env) (le fichier doit être dans `backend\`) |
| `Serveur sur le port undefined` | Il manque la ligne `PORT=3000` dans `.env` | Ajoute `PORT=3000` |
| `Could not connect to any servers in your MongoDB Atlas cluster… IP … isn't whitelisted` | Ton adresse IP n'est pas autorisée dans Atlas (elle change quand tu changes de réseau) | Atlas → **Network Access** → **Add Current IP Address**, attends 1 minute |
| `bad auth` / `Authentication failed` | Mauvais mot de passe dans `MONGODB_URI` | Corrige le mot de passe (et encode les caractères spéciaux) |
| `EADDRINUSE: address already in use :::3000` | Un ancien backend tourne encore | Ferme-le (voir « Tout arrêter » en [section 7](#7-lancer-lapplication)) |
| Les comptes ou voitures n'apparaissent pas dans Atlas | L'adresse de connexion n'a pas `/spotit` | Vérifie que `MONGODB_URI` contient `…mongodb.net/spotit?…` |

### Service IA

| Message ou symptôme | Cause | Solution |
|---|---|---|
| Le terminal IA reste longtemps sans rien afficher | TensorFlow se charge (c'est lent la première fois) | Attends de voir `Running on http://127.0.0.1:5000` |
| `Address already in use` (port 5000) | Un ancien service IA tourne encore | Ferme-le (commande de la [section 7](#7-lancer-lapplication)) |
| `ValueError: File not found: filepath=…spotit_mobilenet.keras` | Le modèle est absent (dépôt incomplet) | Vérifie que `ai/models/spotit_mobilenet.keras` et `ai/models/detector/detect.tflite` existent, sinon `git pull` |
| Le premier scan est lent | Premier passage dans le modèle | Normal : les scans suivants sont plus rapides |

### Dans l'application

| Message ou symptôme | Cause | Solution |
|---|---|---|
| **« Service de reconnaissance indisponible »** | Le service IA (terminal 1) n'est pas lancé ou charge encore | Lance-le et attends `Running on http://127.0.0.1:5000` |
| **« Serveur injoignable. Vérifiez votre connexion. »** | Le backend (terminal 2) n'est pas lancé, ou la constante `host` de `auth_service.dart` ne correspond pas à ta plateforme | Relance le backend ; sur émulateur Android utilise `10.0.2.2` |
| **« Image vide ou trop lourde (6 Mo max) »** | Photo trop grosse ou vide | Choisis une photo plus légère (l'application la réduit déjà à 1280 px de large) |
| **« Email ou mot de passe incorrect »** | Identifiants faux, ou compte créé dans une autre base | Vérifie l'e-mail ; crée un compte si besoin |
| **« Email déjà utilisé ou données invalides »** | Un compte existe déjà avec cet e-mail | Connecte-toi au lieu de t'inscrire |
| **« Session expirée, reconnectez-vous »** | Le token de connexion n'est plus valable (il est aussi perdu quand on ferme l'application) | Reconnecte-toi dans les Réglages |
| Page blanche dans Edge | La compilation n'est pas terminée, ou ancienne version en cache | Patiente, puis tape `R` dans le terminal Flutter, ou recharge avec `Ctrl + F5` |
| Le texte s'affiche avec une police différente | Les polices (Google Fonts) se téléchargent depuis Internet | Vérifie ta connexion Internet |
| « Prendre une photo » ouvre un sélecteur de fichiers | C'est normal dans un navigateur (pas d'appareil photo ici) | Sur un téléphone, il ouvrira l'appareil photo |
| Pas de **cadre rouge** | Le détecteur n'a pas trouvé de voiture (photo d'intérieur, très rapprochée, schéma) | Normal : il trouve une voiture sur environ 82 % des photos de test. Essaie une photo de l'extérieur de la voiture |
| La voiture est mal reconnue (ou **confiance faible**) | L'IA ne connaît que 6 voitures et en répond toujours une ; elle hésite entre voitures qui se ressemblent | Ce n'est pas un bug : voir [Limites connues](#14-limites-connues-et-suite) |

### Git

| Message ou symptôme | Cause | Solution |
|---|---|---|
| `git status` montre plein de fichiers modifiés dans `windows/`, `linux/`, `macos/` ou `analysis_options.yaml` | Flutter les régénère tout seul | Ne les ajoute **pas** au commit. Pour les annuler : `git restore flutter_application_1/analysis_options.yaml flutter_application_1/linux flutter_application_1/macos flutter_application_1/windows` |
| `backend/.env` apparaît dans `git status` | Il ne devrait jamais y apparaître (il est ignoré) | **Ne le commite pas.** Vérifie que `.gitignore` est intact |
| `CONFLICT (…)` pendant une fusion | Deux personnes ont modifié le même fichier | Ouvre le fichier, garde les bonnes parties (supprime les lignes `<<<<<<<`, `=======`, `>>>>>>>`), puis `git add` et `git commit` |

---

## 10. Structure du projet

```
SAE_5/
├── README.md                    ← ce fichier
├── package.json                 ← dépendances du backend (Node.js)
├── requirements.txt             ← dépendances Python (IA + service Flask)
├── .gitignore
├── docs/screenshots/            ← captures d'écran de ce README
│
├── backend/                     ← LE BACKEND (Node.js / Express)
│   ├── server.js                ← point d'entrée : connexion Mongo + routes
│   ├── .env.example             ← modèle du fichier de configuration
│   ├── middleware/
│   │   └── requireAuth.js       ← vérifie le token de connexion
│   ├── models/
│   │   ├── User.js              ← schéma d'un utilisateur
│   │   └── Car.js               ← schéma d'une voiture de la bibliothèque
│   ├── routes/
│   │   ├── auth.js              ← inscription et connexion
│   │   ├── cars.js              ← bibliothèque (ajouter, lister, image, supprimer)
│   │   └── predict.js           ← reconnaissance d'une photo sans compte
│   └── services/
│       ├── imageUpload.js       ← vérifie l'image reçue (type, taille)
│       └── recognition.js       ← appelle l'IA, met en forme marque/modèle/années
│
├── ai/                          ← L'INTELLIGENCE ARTIFICIELLE (Python)
│   ├── server.py                ← service Flask appelé par le backend
│   ├── main.py                  ← menu pour analyser/préparer/entraîner/tester
│   ├── images/                  ← photos d'exemple
│   ├── dataset_small/           ← 920 images (6 voitures : entraînement + test)
│   ├── models/
│   │   ├── spotit_mobilenet.keras   ← classifieur entraîné (6 voitures)
│   │   ├── classes.json             ← noms des 6 voitures
│   │   ├── detector/detect.tflite   ← détecteur de voitures (cadre rouge)
│   │   └── evaluation/              ← résultats d'évaluation (matrice, erreurs…)
│   └── src/
│       ├── predictor.py         ← classe CarPredictor : quelle voiture ?
│       ├── detector.py          ← classe CarDetector : où est la voiture ?
│       ├── trainer.py           ← entraînement du modèle
│       ├── evaluate.py          ← évaluation du modèle sauvegardé
│       ├── dataset_analyzer.py  ← compte les images par voiture
│       └── dataset_preparer.py  ← crée dataset_small à partir du grand dataset
│
└── flutter_application_1/       ← L'APPLICATION (Flutter / Dart)
    ├── pubspec.yaml             ← dépendances de l'application
    └── lib/
        ├── main.dart            ← page d'accueil : photo, analyse, viseur
        ├── car_library_page.dart    ← bibliothèque (grille de voitures)
        ├── car_reveal_dialog.dart   ← popup après un scan (ajouter / se connecter / fermer)
        ├── car_card_dialog.dart     ← fiche d'une voiture + suppression
        ├── car_showcase_dialog.dart ← popup animé commun (titre, stats, confiance)
        ├── framed_image.dart    ← image avec le cadre rouge dessiné dessus
        ├── car_image.dart       ← chargement d'une photo de la bibliothèque
        ├── recognition.dart     ← résultat de l'IA (marque, modèle, années, confiance, cadre)
        ├── scanned_car.dart     ← une voiture de la bibliothèque
        ├── car_service.dart     ← appels au backend (reconnaissance, bibliothèque)
        ├── auth_service.dart    ← connexion, inscription, session, adresse du serveur
        ├── settings_page.dart   ← page du compte
        ├── spot_it_widgets.dart ← widgets partagés (page, en-tête, boutons, confirmation)
        ├── toast.dart           ← petites bulles de message
        └── spot_it_theme.dart   ← couleurs de l'application
```

---

## 11. Référence technique (API, base de données, IA)

### API du backend (`http://localhost:3000`)

Les routes marquées 🔒 demandent l'en-tête `Authorization: Bearer <token>` (le token est renvoyé par `/login`). Les images sont envoyées en **base64** dans du JSON : `{ "image": "<base64>", "contentType": "image/jpeg" }` (formats : JPEG, PNG, WebP ; 6 Mo maximum).

| Méthode | Route | Rôle | Réponses |
|---|---|---|---|
| `POST` | `/api/auth/register` | Crée un compte (`name`, `email`, `password`) | `201` utilisateur · `400` données invalides ou e-mail déjà pris |
| `POST` | `/api/auth/login` | Connexion (`email`, `password`) | `200` `{ token, name, email }` (token valable 7 jours) · `401` |
| `POST` | `/api/predict` | Reconnaît la voiture d'une photo, **sans compte** | `200` `{ brand, model, years, confidence, box }` · `400` image invalide · `503` IA indisponible |
| `GET` | `/api/cars` 🔒 | Liste tes voitures | `200` liste · `401` |
| `POST` | `/api/cars` 🔒 | Reconnaît **et enregistre** la voiture | `201` voiture · `400` · `503` · `500` |
| `GET` | `/api/cars/:id/image` 🔒 | Renvoie la photo d'une de tes voitures | `200` image · `404` |
| `DELETE` | `/api/cars/:id` 🔒 | Supprime une de tes voitures | `204` · `404` |

Le champ `box` est le rectangle de la voiture, en proportions de l'image (0 à 1) : `{ "x": 0.16, "y": 0.37, "width": 0.60, "height": 0.43 }`. Il vaut `null` si aucune voiture n'a été détectée.

### API du service IA (`http://localhost:5000`)

| Méthode | Route | Rôle |
|---|---|---|
| `POST` | `/predict` | Reçoit les octets d'une image, renvoie `{ "label": "FERRARI_F12_Berlinetta_20122015", "confidence": 56.21, "box": {…} }`. Erreurs : `400` image manquante, `422` image illisible. |

### Base de données (MongoDB, base `spotit`)

**`users`** : `name`, `email` (unique), `password` (haché avec bcrypt, jamais en clair).

**`cars`** : une photo de la bibliothèque.

| Champ | Contenu |
|---|---|
| `user` | propriétaire (référence vers `users`) |
| `brand`, `model`, `years` | par exemple `Ferrari`, `F12 Berlinetta`, `2012 – 2015` |
| `confidence` | confiance de l'IA, en % (entier) |
| `box` | rectangle de la voiture (ou `null`) |
| `image` | la photo (données + type) |
| `createdAt` | date d'ajout |

### L'IA en détail

- **Classes** : 6 voitures (`ai/models/classes.json`). Données : sous-ensemble du dataset Kaggle [*Car Model Variants and Images*](https://www.kaggle.com/datasets/eimadevyni/car-model-variants-and-images-dataset) — 920 images dans `ai/dataset_small` (734 pour l'entraînement, 186 pour le test).
- **Classifieur** : MobileNetV3Small (poids ImageNet, couches gelées), images en 224 × 224, *data augmentation* (miroir, rotation, zoom), 10 passes d'entraînement.
- **Résultats mesurés sur les 186 images de test** (`ai/models/evaluation/metrics.json`) :

| Mesure | Valeur |
|---|---|
| Bonne voiture en 1ʳᵉ proposition | **79,6 %** |
| Bonne voiture dans les 3 premières | **96,8 %** |

| Voiture | Part des photos retrouvées |
|---|---|
| Citroën 2CV | 100 % |
| Jeep Grand Cherokee | 95 % |
| Ford Mustang | 83 % |
| Fiat 500 Abarth | 83 % |
| Toyota Hilux | 68 % |
| Ferrari F12 | 47 % *(souvent confondue avec la Mustang)* |

- **Détecteur** : trouve une voiture (ou un pick-up) sur environ 82 % des 172 photos de test au format JPEG, avec un seuil de score de 0,4 (`ai/src/detector.py`).

#### Réentraîner ou évaluer le modèle

Dans le dossier `ai`, le menu de `main.py` propose :

```powershell
cd ai
.venv\Scripts\python.exe main.py
```
| Choix | Action | Besoin |
|---|---|---|
| 1 | Analyser le dataset (nombre d'images par voiture) | le **grand dataset** (≈ 6 Go) dans `ai/dataset/` |
| 2 | Préparer `dataset_small` | le grand dataset |
| 3 | **Entraîner** le modèle (remplace `models/spotit_mobilenet.keras`) | `dataset_small` (déjà dans le dépôt) |
| 4 | Tester l'image `images/f12.jpg` | — |

Pour évaluer le modèle sauvegardé sans le réentraîner (génère matrice de confusion, erreurs, métriques dans `models/evaluation/`) :
```powershell
.venv\Scripts\python.exe src\evaluate.py
```
Le grand dataset n'est **pas** dans le dépôt (trop lourd) : télécharge-le sur Kaggle (lien ci-dessus) et place-le dans `ai/dataset/` (dossiers `train/` et `test/`).

### Sécurité
- Les mots de passe sont **hachés** (bcrypt) ; les connexions utilisent un **token JWT** signé par `JWT_SECRET`.
- Chaque utilisateur ne voit et ne supprime **que ses propres voitures**.
- Le fichier `backend/.env` ne doit **jamais** être commité (il est dans `.gitignore`).
- ⚠️ Points à durcir avant une vraie mise en production : la route publique `/api/predict` n'a pas de limitation de débit, les requêtes sont acceptées de toute origine (CORS ouvert), et le backend/IA ne tournent qu'en local (pas de HTTPS).

---

## 12. Travailler sur le projet (Git, bonnes pratiques)

- **Branches** : `main` (version de référence), `backend-mongodb` (application + bibliothèque en ligne), `test_mobilenet_python_thomas` (travail sur le modèle), `flutter_dev` (ancienne version de l'application), `ia-integration` (fusion application + IA).
- **Récupérer les dernières modifications** : `git pull`, puis, si besoin, relance `npm install`, `ai\.venv\Scripts\python.exe -m pip install -r requirements.txt` et `flutter pub get`.
- **Avant chaque `git add`/commit**, lance `git status` et vérifie :
  - `backend/.env` n'apparaît pas ;
  - les fichiers régénérés par Flutter (`windows/`, `linux/`, `macos/`, `analysis_options.yaml`) ne sont pas ajoutés.
- **Messages de commit** : courts, en anglais, qui disent ce qui a été fait (ex. `Add car detection frame and UI updates`).
- **Code propre** : pas de code mort ni de copier-coller ; les parties communes sont regroupées (widgets partagés dans `spot_it_widgets.dart`, vérification d'image partagée dans `imageUpload.js`).

---

## 13. État d'avancement par rapport au sujet

| Exigence du sujet | État |
|---|---|
| Acquisition d'images (appareil photo, import depuis la galerie) | ✅ photo et galerie (l'appareil photo fonctionne sur téléphone ; en navigateur c'est un sélecteur de fichiers) |
| Modèle pré-entraîné de reconnaissance (MobileNet, SSD…) | ✅ MobileNetV3 + SSD MobileNet |
| Cadres autour des objets détectés et noms | ✅ cadre rouge + marque et modèle |
| Pourcentage de confiance | ✅ jauge colorée |
| Base de données de catégories | 🟡 6 voitures (liste dans `classes.json`) |
| Ajouter de nouvelles catégories | 🟡 possible en réentraînant (menu `main.py`), pas encore depuis l'application |
| Apprentissage personnalisé avec les images de l'utilisateur | ❌ à faire |
| Interface intuitive + historique des reconnaissances | ✅ bibliothèque personnelle avec fiches |
| Sauvegarder les résultats | ✅ photo, résultat et cadre enregistrés |
| Base de données en ligne partagée | ✅ MongoDB Atlas |
| Reconnaissance en temps réel / TensorFlow Lite sur mobile | 🟡 le détecteur est au format TensorFlow Lite mais tourne sur le serveur ; embarquement dans le téléphone à faire |

**Livrables** : push hebdomadaire + rapport court (chaque vendredi 18 h), rapport technique le **06/01/2027**, soutenance avec démonstration le **08/01/2027**.

---

## 14. Limites connues et suite

**Limites actuelles**
- L'IA ne connaît que **6 voitures** et répond **toujours** l'une d'elles, même pour une autre voiture : une Mazda MX-5 est prise pour une Fiat 500 Abarth à 79 %. Il faut ajouter un **seuil de confiance** (« voiture non reconnue »).
- La confiance paraît parfois basse même sur une bonne réponse (voir [section 2](#la--confiance--en-clair)).
- Le détecteur rate certaines photos (intérieur, très rapproché) : alors pas de cadre.
- La connexion n'est gardée qu'**en mémoire** : on doit se reconnecter à chaque redémarrage de l'application.
- Le bouton « Ajouter » relance l'IA côté serveur (analyse en double volontaire : on ne fait pas confiance à un résultat envoyé par l'application).
- Pas de tests automatiques dans le dépôt.
- Le backend et l'IA ne tournent qu'en local.

**Pistes pour la suite**
1. Seuil de confiance et message « voiture non reconnue ».
2. Raretés et points par voiture (« Ferrari = légendaire »), fiche enrichie, filtres, score total.
3. Garder la connexion sur l'appareil (`shared_preferences`).
4. Plus de voitures dans le modèle, et **apprentissage personnalisé**.
5. Piste pour la confiance : à l'entraînement les images sont réduites avec la méthode « bilinear », à la prédiction avec « nearest » (à uniformiser et à tester).
6. Faire tourner l'IA **sur le téléphone** (TensorFlow Lite) et tester sur Android.
7. Héberger le backend et l'IA en ligne.

---

## 15. Mini-lexique

| Mot | Explication simple |
|---|---|
| **Terminal** | Fenêtre où l'on tape des commandes (PowerShell sous Windows). |
| **Dépôt (repo)** | Le dossier du projet suivi par Git, hébergé sur GitHub. |
| **Branche** | Une version parallèle du projet, pour travailler sans casser la version principale. |
| **Commit / push** | Enregistrer une modification / l'envoyer sur GitHub. |
| **Frontend / backend** | La partie visible (l'application) / la partie cachée (le serveur). |
| **API** | Les « portes d'entrée » du serveur, que l'application appelle (ex. `/api/cars`). |
| **Base de données** | Là où sont rangées les informations (comptes, voitures). |
| **Token (JWT)** | Un « ticket » donné à la connexion qui prouve qui tu es. |
| **Variable d'environnement / `.env`** | Réglages et mots de passe gardés hors du code. |
| **Environnement virtuel (venv)** | Dossier Python isolé où l'on installe les bibliothèques du projet. |
| **Modèle d'IA** | Un programme qui a « appris » à partir d'exemples (ici des photos de voitures). |
| **Classification / détection** | Dire *quelle* voiture c'est / dire *où* elle est dans l'image. |
| **Confiance** | À quel point le modèle préfère sa réponse aux autres (pas une garantie qu'il a raison). |
| **TensorFlow / TensorFlow Lite** | Bibliothèque d'IA de Google / sa version légère pour mobiles. |
| **Base64** | Façon de transformer une image en texte pour l'envoyer dans une requête. |

---

## 16. Crédits et licences

- **Équipe** : Matteo LAURI, Evan STILLE, Thomas FREY, Victorien DENOYELLE. Enseignante référente : Lydia Boudjeloud-Assala.
- **Images d'entraînement** : sous-ensemble du dataset Kaggle *Car Model Variants and Images* (les images appartiennent à leurs auteurs ; usage pédagogique).
- **Détecteur d'objets** : modèle *SSD MobileNet v1* quantifié, entraîné sur COCO, publié par TensorFlow (licence Apache 2.0).
- **Classifieur** : MobileNetV3Small (Keras), poids pré-entraînés ImageNet.
- Projet pédagogique, réalisé pour la SAE 5.01. Utilisation de l'IA dans le développement documentée dans les rapports hebdomadaires de l'équipe.
