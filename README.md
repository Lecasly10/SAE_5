# Spot'It — Scanne une voiture, l'IA la reconnaît, collectionne-la

> Application mobile (Flutter) qui reconnaît une voiture à partir d'une photo grâce à l'intelligence artificielle, l'entoure d'un cadre rouge et l'ajoute à une bibliothèque personnelle, comme un Pokédex.

Projet réalisé en équipe dans le cadre de la **SAE 5.01 — Développement avancé** (BUT Informatique) : *« Développement d'une application mobile de reconnaissance et de classification d'objets avec IA »*.

| | |
|---|---|
| **Dépôt** | https://github.com/Lecasly10/SAE_5 |
| **Équipe** | Matteo LAURI, Evan STILLE, Thomas FREY, Victorien DENOYELLE |
| **Suivi des tâches** | https://trello.com/b/TlcXJrDZ/sae5 |
| **Testé sur** | Windows 11, Docker Desktop 29 (Docker Compose 5), Node.js 26, Python 3.13, TensorFlow 2.21, Flutter 3.47, navigateur Edge |

<p align="center">
  <img src="docs/screenshots/home.png" alt="Écran d'accueil" width="190">
  <img src="docs/screenshots/scan-result.png" alt="Résultat d'un scan avec cadre rouge" width="190">
  <img src="docs/screenshots/library.png" alt="Bibliothèque" width="190">
  <img src="docs/screenshots/car-card.png" alt="Fiche d'une voiture" width="190">
</p>

---

## Démarrage rapide avec Docker (recommandé)

**C'est le moyen le plus simple pour essayer l'application.** Docker fabrique et lance tout à ta place (l'IA, le serveur, la base de données et l'application), chacun dans sa « boîte » appelée *conteneur*. **Tu n'as besoin d'installer que Docker Desktop** : ni Node.js, ni Python, ni Flutter, ni compte MongoDB, ni fichier `.env`.

```
Installer Docker Desktop  →  télécharger le projet  →  docker compose up --build  →  http://localhost:8080
```

### Étape A — Installer Docker Desktop (une seule fois)

**Ce qu'il faut :** Windows 10 ou 11 (64 bits), **8 Go de mémoire (RAM) minimum**, environ **10 Go de disque libre**, et la virtualisation activée (c'est le cas sur presque tous les PC récents).

1. Ouvre **PowerShell** (touche **Windows**, tape `PowerShell`, Entrée) et tape :
   ```powershell
   winget install -e --id Docker.DockerDesktop
   ```
   *(Si `winget` n'existe pas, télécharge « Docker Desktop for Windows » sur https://www.docker.com/products/docker-desktop/ et lance l'installateur.)*
2. **Redémarre l'ordinateur** si l'installateur le demande.
3. **Lance « Docker Desktop »** depuis le menu Démarrer, accepte les conditions d'utilisation, et garde l'option **WSL 2** cochée. Si Windows te demande d'installer WSL, tape dans un PowerShell ouvert **en administrateur** `wsl --install`, puis redémarre.
4. **Attends** que Docker Desktop affiche **« Engine running »** (moteur démarré) en bas à gauche.
5. Vérifie dans PowerShell :
   ```powershell
   docker --version
   docker compose version
   ```
   Chaque commande doit afficher un numéro de version.

> ⚠️ **Docker Desktop doit rester ouvert** tant que tu utilises l'application.

### Étape B — Télécharger le projet

**Sans Git (le plus simple)** : clique sur ce lien pour télécharger le projet, puis fais un clic droit sur le fichier → **Extraire tout…** :
https://github.com/Lecasly10/SAE_5/archive/refs/heads/main.zip

**Avec Git** :
```powershell
git clone https://github.com/Lecasly10/SAE_5.git
```
```powershell
cd SAE_5
```

Ensuite, **ouvre PowerShell dans le dossier du projet** : dans l'Explorateur de fichiers, ouvre le dossier (celui où se trouve `docker-compose.yml`), fais un clic droit dans un espace vide → **« Ouvrir dans le Terminal »**.

### Étape C — Tout lancer (une seule commande)

```powershell
docker compose up --build
```

- ⏳ **La toute première fois, compte 10 à 25 minutes selon ta connexion** : Docker télécharge et construit tout (environ 3 Go à télécharger : TensorFlow, Flutter, etc.). Ça ne se fait qu'**une seule fois**. Les fois suivantes, le démarrage prend moins d'une minute.
- Le terminal affiche beaucoup de texte : c'est normal. Ne le ferme pas.
- C'est prêt quand tu vois dans les messages `Serveur sur le port 3000` (l'IA met 20 à 60 secondes à se charger). Tu peux aussi vérifier avec `docker compose ps` : les conteneurs `ai`, `backend` et `mongo` doivent être **healthy**.
- **Ouvre ensuite ton navigateur sur : http://localhost:8080**

### Utiliser l'application

Suis le parcours de la [section 8](#8-tester-que-tout-fonctionne). En résumé : **Insérer une photo** → choisis `ai/images/f12.jpg` (dans le dossier du projet) → **Analyser la photo** → un cadre rouge entoure la voiture et un popup donne la marque, le modèle et la confiance. Crée un compte (engrenage en haut à droite) pour ajouter la voiture à ta bibliothèque.

> 💾 Les comptes et les voitures créés avec Docker sont enregistrés **sur ton ordinateur** (une base MongoDB locale), pas dans la base partagée de l'équipe. Ils sont conservés d'un lancement à l'autre.

### Arrêter, relancer, réinitialiser

| Je veux… | Commande |
|---|---|
| **Arrêter** | `Ctrl + C` dans le terminal, puis `docker compose down` |
| **Relancer** (rapide) | `docker compose up` |
| **Relancer après une mise à jour du projet** (`git pull` ou nouveau ZIP) | `docker compose up --build` |
| **Lancer en arrière-plan** (sans garder le terminal) | `docker compose up --build -d`, puis `docker compose down` pour arrêter |
| **Voir l'état des conteneurs** | `docker compose ps` |
| **Voir les messages d'un conteneur** (en cas de souci) | `docker compose logs ai` (ou `backend`, `app`, `mongo`) |
| **Tout effacer et repartir de zéro** (comptes et voitures aussi) | `docker compose down -v` |

### Le fichier `.env` : facultatif

**Avec Docker, tu n'as rien à écrire** : tout fonctionne avec des valeurs par défaut prévues pour tester en local. Le fichier `.env` sert seulement si tu veux **changer un réglage**.

Pour en créer un, depuis le dossier du projet :
```powershell
Copy-Item .env.example .env
```
Ouvre `.env` (Bloc-notes ou VS Code), **enlève le `#`** au début de la ligne que tu veux modifier, change la valeur, puis relance avec `docker compose up --build`.

| Réglage | Valeur par défaut | À quoi ça sert |
|---|---|---|
| `JWT_SECRET` | clé aléatoire à chaque démarrage | Clé qui signe les connexions. Sans elle, tout le monde est déconnecté à chaque redémarrage. Mets une longue valeur aléatoire (voir `.env.example`) dès que tu veux garder les sessions. |
| `MONGODB_URI` | base locale lancée par Docker | Mets ton adresse **MongoDB Atlas** (avec `/spotit` avant le `?`) pour utiliser la base partagée de l'équipe. Voir [section 6](#6-configurer-la-base-de-données-mongodb-atlas). |
| `APP_PORT` | `8080` | Port de l'application dans le navigateur. Mets `8081` si le 8080 est déjà pris. |
| `API_HOST` | `http://localhost:3000` | Adresse du serveur vue par le navigateur. À changer seulement pour ouvrir l'application depuis un autre ordinateur. |
| `CORS_ORIGIN` | toutes les origines | Adresses autorisées à appeler l'API, séparées par des virgules (par exemple `http://localhost:8080`). |

Le même fichier `.env` sert aussi à l'[installation manuelle](#4-installation-pas-à-pas--windows-de-zéro) (le backend le lit à la racine du projet).

### Ce que Docker lance

| Conteneur | Rôle | Accessible sur |
|---|---|---|
| `app` | L'application Flutter (compilée en site web, servie par nginx) | http://localhost:8080 |
| `backend` | Le serveur Node.js (comptes, bibliothèque, appels à l'IA) | http://localhost:3000 |
| `ai` | Le service IA Python (détecteur + classifieur) | interne (pas ouvert) |
| `mongo` | La base de données MongoDB locale | interne (pas ouvert) |
| `trainer` | Entraînement de l'IA sur carte graphique, lancé seulement à la demande (`docker compose run --rm trainer …`) | — |

Ils démarrent dans le bon ordre : la base et l'IA d'abord, puis le serveur, puis l'application.

### Problèmes Docker fréquents

| Message ou symptôme | Cause | Solution |
|---|---|---|
| `docker : The term 'docker' is not recognized…` | Docker Desktop n'est pas installé, ou le terminal a été ouvert avant | Installe-le (étape A), puis **ferme et rouvre** PowerShell |
| `failed to connect to the docker API at npipe:////./pipe/dockerDesktopLinuxEngine… cannot find the file` | **Docker Desktop n'est pas lancé** | Ouvre Docker Desktop et attends « Engine running » |
| Docker Desktop ne démarre pas, parle de **virtualisation** ou de **WSL** | La virtualisation est désactivée, ou WSL 2 n'est pas installé | Dans un PowerShell **administrateur** : `wsl --install`, puis redémarre. Si besoin, active la virtualisation dans le BIOS de l'ordinateur |
| Au démarrage de Docker Desktop : `Ingest server … sailor-ingest.sock … The file cannot be accessed by the system` | Un vieux fichier temporaire de Docker bloque un petit service interne (télémétrie) | **Sans gravité** si le moteur démarre. Sinon : quitte complètement Docker Desktop (clic droit sur l'icône → Quit), supprime les fichiers `*.stale` du dossier `%LOCALAPPDATA%\Docker\run`, puis relance |
| `Bind for 127.0.0.1:8080 failed: port is already allocated` | Un autre programme (ou un autre projet Docker) utilise déjà le port 8080 | Crée un `.env` avec `APP_PORT=8081` (voir plus haut) et ouvre http://localhost:8081. Pour le port 3000, arrête le programme qui l'utilise (`docker ps` te montre les conteneurs en cours) |
| Le téléchargement est très long ou semble bloqué | Première construction (≈ 3 Go) ou connexion lente | Patiente. Si ça s'interrompt, relance `docker compose up --build` : Docker reprend où il s'est arrêté |
| `no space left on device` | Plus assez de disque pour Docker (la première construction occupe jusqu'à ≈ 10 Go) | Libère de la place. Après la première construction, `docker builder prune` récupère environ 7 Go de fichiers temporaires sans rien casser |
| `dependency failed to start: container … ai … is unhealthy`, ou le conteneur `ai` s'arrête (code 137, « Killed ») | L'IA manque de mémoire ou n'a pas fini de charger | Docker Desktop → **Settings → Resources** : donne au moins **4 Go** de mémoire. Puis `docker compose logs ai` |
| L'application affiche **« Serveur injoignable »** | Le backend n'est pas prêt, ou `API_HOST` est faux | `docker compose ps` (le backend doit être « healthy »), puis `docker compose logs backend` |
| **« Service de reconnaissance indisponible »** | Le conteneur `ai` n'est pas encore prêt (TensorFlow charge pendant 30 à 60 s) | Attends un peu, vérifie avec `docker compose ps` |
| Erreur `Could not connect to any servers in your MongoDB Atlas cluster` | Tu as mis `MONGODB_URI` (Atlas) et ton IP n'est pas autorisée | Autorise ton IP dans Atlas (voir [section 6](#6-configurer-la-base-de-données-mongodb-atlas)), ou supprime la ligne `MONGODB_URI` du `.env` pour revenir à la base locale |
| J'ai modifié le code mais je ne vois pas la différence | Docker utilise l'ancienne version construite | Relance avec `docker compose up --build` |
| Après une mise à jour, le navigateur affiche encore l'ancienne application | Le navigateur garde une copie de l'ancienne version | Sur la page, **F12**, puis clic droit sur le bouton d'actualisation → **« Vider le cache et effectuer une actualisation forcée »** (une seule fois) |

> 🛠️ **Tu veux modifier le code ?** Docker sert à **essayer** le projet. Pour développer (rechargement à chaud, débogage), utilise plutôt l'[installation manuelle](#4-installation-pas-à-pas--windows-de-zéro).

---

## Sommaire

**➡️ Pressé ? Va directement au [Démarrage rapide avec Docker](#démarrage-rapide-avec-docker-recommandé).**

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

**L'IA connaît 1 002 voitures de 64 marques** : toutes les générations du dataset qui ont au moins 50 photos (Renault, Peugeot, Citroën, BMW, Audi, Mercedes, Toyota, Porsche, Ferrari…). La liste complète est dans `ai/models/cars.json`. Si l'IA n'est pas sûre d'elle, elle répond « voiture non reconnue » au lieu de deviner (voir [Limites connues](#14-limites-connues-et-suite)).

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
    opt Utilisateur connecté et d'accord qui corrige la voiture sans l'ajouter
        App->>API: POST /api/training-photos (photo + voiture choisie)
        API->>DB: garde la photo pour le prochain entraînement
    end
```

**Corriger l'IA** : quand l'IA n'est pas sûre ou se trompe (bouton « Ce n'est pas la bonne voiture ? »), l'utilisateur touche la bonne voiture dans les suggestions. La fenêtre s'affiche alors avec cette voiture (« VOITURE CORRIGÉE »), et c'est elle qui est ajoutée à la bibliothèque. Si la bonne voiture n'est pas dans les suggestions, le bouton « Aider l'IA » (à côté de « Réessayer ») ouvre la liste des 1 002 voitures avec une recherche (« bmw m4 ») pour la choisir. Le backend n'accepte qu'une voiture de cette liste.

**L'IA apprend avec les photos de l'application**, seulement pour les utilisateurs qui l'ont accepté dans les paramètres (« Autoriser l'entraînement de l'IA avec mes photos », désactivé par défaut, consentement RGPD). Chaque voiture ajoutée à leur bibliothèque, et chaque correction, est une photo dont la réponse est connue. Ces photos sont gardées dans MongoDB, puis ajoutées à l'entraînement suivant par `python main.py retrain` (voir [Réentraîner ou évaluer le modèle](#réentraîner-ou-évaluer-le-modèle)). Si l'utilisateur retire son accord, ses photos de correction sont supprimées et `collect` efface ses photos de `ai/dataset_user/`. Les photos sans réponse confirmée ne sont jamais utilisées : l'IA apprendrait ses propres erreurs.

**Plusieurs voitures sur la photo** : l'IA reconnaît la voiture au premier plan, c'est-à-dire la plus grande sur l'image.

### Les deux modèles d'IA

1. **Le détecteur** (`ai/models/detector/detect.tflite`) : un modèle *SSD MobileNet* déjà entraîné sur la base d'images COCO. Il sait trouver des voitures dans une photo et renvoie un rectangle. C'est lui qui permet de dessiner le **cadre rouge**.
2. **Le classifieur** (`ai/models/spotit_classifier.keras`) : un modèle *EfficientNetV2-B3* entraîné par l'équipe sur 1 002 voitures plus une classe « autre » (technique du *transfer learning* : on réutilise un modèle qui sait déjà reconnaître des formes et on lui apprend à choisir entre nos voitures). Il ne regarde que la voiture découpée dans le cadre rouge (avec un peu de marge), pas le décor autour. C'est lui qui donne la **marque, le modèle et la confiance**. Les années de production viennent de la fiche de la voiture (`ai/models/cars.json`).

#### La « confiance » en clair
La confiance n'est **pas** « la probabilité d'avoir raison ». C'est la part de préférence du modèle pour cette voiture **par rapport aux 1 002 autres**. Si deux voitures se ressemblent (Peugeot 3008 et 5008), le modèle hésite et la confiance se partage.

#### « Voiture non reconnue »
L'IA ne répond que si elle remplit **deux conditions** (réglées dans `ai/models/recognition.json`) :
- sa meilleure réponse n'est pas la classe « autre » (les voitures hors liste) ;
- sa confiance est d'au moins **30 %**.

Sinon l'application affiche « Voiture non reconnue » avec les 3 voitures les plus proches, ou « Aucune voiture détectée » quand le détecteur ne voit rien. Ces seuils sont calculés automatiquement à la fin de l'entraînement pour que l'IA ait raison environ 9 fois sur 10 quand elle répond.

La jauge de l'application est verte à partir de 70 %, orange à partir de 40 %, rouge en dessous.

---

## 3. Ce qu'il faut avant de commencer (prérequis)

> 💡 **Avec Docker, tu n'as besoin de rien de tout ça** (ni Node.js, ni Python, ni Flutter) : seulement Docker Desktop, voir le [Démarrage rapide](#démarrage-rapide-avec-docker-recommandé). Cette liste concerne l'**installation manuelle**, pour développer.

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
- **Accès à la base MongoDB du groupe** : demande le fichier `.env` à un membre de l'équipe (il contient des mots de passe et n'est jamais sur GitHub).
  *Sans ça, tu peux créer ta propre base gratuite : voir [section 6](#6-configurer-la-base-de-données-mongodb-atlas).*

---

## 4. Installation pas à pas — Windows (de zéro)

> 💡 Cette installation est destinée à **développer** le projet. Pour simplement l'essayer, le [Démarrage rapide avec Docker](#démarrage-rapide-avec-docker-recommandé) est beaucoup plus court.

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

Toutes les commandes suivantes se lancent **depuis ce dossier `SAE_5`** (appelé « racine du projet »), sauf indication contraire.

### Étape 5 — Installer l'IA (Python)

On crée un « environnement virtuel » : un dossier à part où s'installent les bibliothèques Python du projet, sans toucher au reste de ton ordinateur.

```powershell
py -3.13 -m venv ai\.venv
```
```powershell
ai\.venv\Scripts\python.exe -m pip install -r ai\requirements.txt
```
⏳ C'est long : TensorFlow seul pèse environ 335 Mo, compte 5 à 10 minutes en tout. Ça ne se fait qu'**une seule fois**.

> 💡 On appelle directement le Python de l'environnement (`ai\.venv\Scripts\python.exe`) au lieu de l'« activer » : ça évite les erreurs de scripts bloqués qu'on rencontre selon le terminal utilisé.

### Étape 6 — Installer le backend (Node.js)

```powershell
cd backend
```
```powershell
npm install
```
```powershell
cd ..
```

### Étape 7 — Créer le fichier de configuration `.env`

> ℹ️ Ce fichier concerne l'installation manuelle uniquement : **Docker n'en a pas besoin**.

Ce fichier contient les mots de passe : il reste **sur ton ordinateur** et n'est jamais envoyé sur GitHub.

```powershell
Copy-Item .env.example .env
```
Ouvre `.env` (avec le Bloc-notes ou VS Code), enlève le `#` devant les lignes dont tu as besoin et remplis-les :

```
MONGODB_URI=mongodb+srv://UTILISATEUR:MOTDEPASSE@cluster0.xxxxx.mongodb.net/spotit?retryWrites=true&w=majority
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
ai/.venv/bin/python -m pip install -r ai/requirements.txt
(cd backend && npm install)
cp .env.example .env      # puis remplis .env (voir étape 7)
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
6. Colle-la dans `.env` (`MONGODB_URI`) en :
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
MongoDB connecté
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

> 📱 **Autres plateformes** : `flutter devices` liste ce qui est disponible. L'application native Windows (`-d windows`) demande Visual Studio avec la charge de travail « Développement Desktop en C++ » ; un émulateur ou téléphone Android demande Android Studio. Pour ces cas, indique l'adresse du serveur au lancement : `flutter run --dart-define=API_HOST=http://10.0.2.2:3000` pour l'émulateur Android, ou `flutter run --dart-define=API_HOST=http://IP_DE_TON_PC:3000` pour un vrai téléphone sur le même Wi-Fi (par défaut : `http://localhost:3000`).

### Tout arrêter

Dans chaque terminal, appuie sur **Ctrl + C**. Si un programme reste bloqué en arrière-plan :
```powershell
Get-NetTCPConnection -LocalPort 3000,5000 -State Listen | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
```

---

## 8. Tester que tout fonctionne

### Test de l'application (parcours complet)

1. **Sans compte** : clique sur **Insérer une photo** et choisis `ai/images/f12.jpg` (ou une photo de voiture trouvée sur Internet).
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

**Service IA** — doit renvoyer un JSON avec `recognized`, `confidence`, `car`, `suggestions` et `box` :
```powershell
curl.exe -X POST --data-binary "@ai/images/f12.jpg" http://localhost:5000/predict
```

**Backend** — doit répondre `Email ou mot de passe incorrect` (c'est le bon signe : il fonctionne et lit la base) :
```powershell
curl.exe -X POST http://localhost:3000/api/auth/login -H "Content-Type: application/json" -d "{}"
```

**Chaîne complète sans compte** — le backend demande à l'IA et renvoie la marque, le modèle, les années et la confiance (voir l'API en [section 11](#11-référence-technique-api-base-de-données-ia)).

### Photos de test
- `ai/images/` : 3 photos d'exemple. `f12.jpg` est reconnue (Ferrari F12). `mx5.jpg` (Mazda MX-5) et `z4.jpg` (BMW Z4) font partie de la liste, mais l'IA n'est pas assez sûre d'elle sur ces photos : elle répond « voiture non reconnue », avec la bonne voiture en 1ʳᵉ suggestion (voir section 14).
- `ai/dataset_small/test/<voiture>/` : photos de test, créées par `python main.py prepare` (voir [Réentraîner ou évaluer le modèle](#réentraîner-ou-évaluer-le-modèle)). Le dossier n'est pas dans le dépôt.

### Tests automatiques
```powershell
cd backend
npm test
```
Teste le backend (validation, erreurs, limitation des requêtes, appel à l'IA). Pour l'IA (fiches, préparation du dataset, seuils), dans le dossier du projet :
```powershell
docker run --rm -v "${PWD}/ai:/app" -w /app spotit-ai python -m unittest discover -s tests -t .
```
(l'image `spotit-ai` existe après un `docker compose up --build`). Pour l'application Flutter : `flutter analyze` puis `flutter test` dans `flutter_application_1`.

**Sur GitHub** : à chaque push et à chaque pull request, GitHub Actions lance automatiquement les trois séries de tests (backend, IA, Flutter), voir `.github/workflows/tests.yml`. Le résultat apparaît dans l'onglet **Actions** du dépôt et à côté de chaque commit (✅ ou ❌). Si un test échoue, il faut le corriger avant de fusionner dans `main`.

### Vérifier la qualité du code Flutter
```powershell
cd flutter_application_1
dart analyze lib
```
Résultat attendu : `No issues found!`.

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
| `ValueError: File not found: filepath=…spotit_classifier.keras` | Le modèle est absent (dépôt incomplet) | Vérifie que `ai/models/spotit_classifier.keras` et `ai/models/detector/detect.tflite` existent, sinon `git pull` |
| Le premier scan est lent | Premier passage dans le modèle | Normal : les scans suivants sont plus rapides |

### Dans l'application

| Message ou symptôme | Cause | Solution |
|---|---|---|
| **« Service de reconnaissance indisponible »** | Le service IA (terminal 1) n'est pas lancé ou charge encore | Lance-le et attends `Running on http://127.0.0.1:5000` |
| **« Serveur injoignable. Vérifiez votre connexion. »** | Le backend (terminal 2) n'est pas lancé, ou l'adresse `API_HOST` ne correspond pas à ta plateforme | Relance le backend ; sur émulateur Android lance l'appli avec `--dart-define=API_HOST=http://10.0.2.2:3000` |
| **« Image vide ou trop lourde (6 Mo max) »** | Photo trop grosse ou vide | Choisis une photo plus légère (l'application la réduit déjà à 1280 px de large) |
| **« Email ou mot de passe incorrect »** | Identifiants faux, ou compte créé dans une autre base | Vérifie l'e-mail ; crée un compte si besoin |
| **« Email déjà utilisé ou données invalides »** | Un compte existe déjà avec cet e-mail | Connecte-toi au lieu de t'inscrire |
| **« Session expirée, reconnectez-vous »** | Le token de connexion n'est plus valable (il est aussi perdu quand on ferme l'application) | Reconnecte-toi dans les Réglages |
| Page blanche dans Edge | La compilation n'est pas terminée, ou ancienne version en cache | Patiente, puis tape `R` dans le terminal Flutter, ou recharge avec `Ctrl + F5` |
| Le texte s'affiche avec une police différente | Les polices (Google Fonts) se téléchargent depuis Internet | Vérifie ta connexion Internet |
| « Prendre une photo » ouvre un sélecteur de fichiers | C'est normal dans un navigateur (pas d'appareil photo ici) | Sur un téléphone, il ouvrira l'appareil photo |
| Pas de **cadre rouge** | Le détecteur n'a pas trouvé de voiture (photo d'intérieur, très rapprochée, schéma) | Normal : il trouve une voiture sur environ 82 % des photos de test. Essaie une photo de l'extérieur de la voiture |
| La voiture est mal reconnue (ou **confiance faible**) | L'IA ne connaît que certaines voitures et hésite entre celles qui se ressemblent (3008 et 5008, 207 et 206…) | Ce n'est pas un bug : voir [Limites connues](#14-limites-connues-et-suite) |

### Git

| Message ou symptôme | Cause | Solution |
|---|---|---|
| `git status` montre plein de fichiers modifiés dans `windows/`, `linux/`, `macos/` ou `analysis_options.yaml` | Flutter les régénère tout seul | Ne les ajoute **pas** au commit. Pour les annuler : `git restore flutter_application_1/analysis_options.yaml flutter_application_1/linux flutter_application_1/macos flutter_application_1/windows` |
| `.env` apparaît dans `git status` | Il ne devrait jamais y apparaître (il est ignoré) | **Ne le commite pas.** Vérifie que `.gitignore` est intact |
| `CONFLICT (…)` pendant une fusion | Deux personnes ont modifié le même fichier | Ouvre le fichier, garde les bonnes parties (supprime les lignes `<<<<<<<`, `=======`, `>>>>>>>`), puis `git add` et `git commit` |

---

## 10. Structure du projet

```
SAE_5/
├── README.md                    ← ce fichier
├── rapports/                    ← rapports de chaque semaine (PDF)
├── docker-compose.yml           ← lance tout avec Docker (une commande)
├── .env.example                 ← modèle du fichier .env (réglages facultatifs)
├── .gitignore
├── .gitattributes               ← fins de ligne identiques sur tous les ordinateurs
├── .github/workflows/tests.yml  ← tests lancés automatiquement par GitHub à chaque push
├── docs/screenshots/            ← captures d'écran de ce README
│
├── backend/                     ← LE BACKEND (Node.js / Express)
│   ├── server.js                ← démarrage : connexion Mongo puis écoute du port
│   ├── app.js                   ← l'application Express (sécurité, routes, erreurs)
│   ├── config.js                ← réglages lus dans l'environnement
│   ├── database.js              ← connexion à MongoDB (toujours la base spotit)
│   ├── errors.js                ← erreur HTTP (code + message)
│   ├── validation.js            ← règles du nom et de l'e-mail (inscription et compte)
│   ├── package.json             ← dépendances et scripts (npm start, npm test)
│   ├── Dockerfile
│   ├── middleware/
│   │   ├── requireAuth.js       ← vérifie le token de connexion
│   │   ├── uploadedImage.js     ← vérifie l'image reçue (type, taille, contenu)
│   │   ├── rateLimits.js        ← limite le nombre de requêtes
│   │   └── errorHandler.js      ← transforme les erreurs en réponses JSON
│   ├── models/
│   │   ├── User.js              ← schéma d'un utilisateur (avec son accord RGPD)
│   │   ├── Car.js               ← schéma d'une voiture de la bibliothèque
│   │   ├── TrainingPhoto.js     ← photo corrigée gardée pour l'entraînement
│   │   └── imageField.js        ← champ « image » commun aux deux

│   ├── routes/
│   │   ├── auth.js              ← inscription et connexion
│   │   ├── account.js           ← compte : modifier, accord RGPD, supprimer
│   │   ├── cars.js              ← bibliothèque (ajouter, lister, image, supprimer)
│   │   ├── catalog.js           ← liste des voitures connues (bouton « Aider l'IA »)
│   │   ├── trainingPhotos.js    ← photos corrigées pour l'entraînement
│   │   └── predict.js           ← reconnaissance d'une photo sans compte
│   ├── services/
│   │   └── recognition.js       ← appelle l'IA, liste des voitures, voiture choisie
│   └── tests/                   ← tests automatiques (npm test)
│
├── ai/                          ← L'INTELLIGENCE ARTIFICIELLE (Python)
│   ├── server.py                ← service Flask appelé par le backend
│   ├── main.py                  ← commandes : analyser, catalogue, préparer, entraîner, évaluer, tester
│   ├── requirements.txt         ← dépendances Python
│   ├── requirements-gpu.txt     ← les mêmes + TensorFlow pour carte graphique NVIDIA
│   ├── Dockerfile
│   ├── images/                  ← photos d'exemple
│   ├── models/
│   │   ├── spotit_classifier.keras  ← classifieur entraîné
│   │   ├── classes.json             ← classes du modèle, dans l'ordre de ses sorties
│   │   ├── cars.json                ← fiches : marque, modèle, années, dossiers du dataset
│   │   ├── recognition.json         ← seuils du « voiture non reconnue »
│   │   ├── detector/detect.tflite   ← détecteur de voitures (cadre rouge)
│   │   └── evaluation/              ← résultats d'évaluation (metrics.json…)
│   ├── src/
│   │   ├── config.py            ← chemins, taille des images, classe « autre »
│   │   ├── catalog.py           ← lit les fiches (cars.json)
│   │   ├── catalog_builder.py   ← crée les fiches à partir du dataset (générations)
│   │   ├── recognition.py       ← décide « reconnue ou non » et calcule les seuils
│   │   ├── predictor.py         ← quelle voiture ?
│   │   ├── detector.py          ← où est la voiture ? (celle au premier plan)
│   │   ├── user_photos.py       ← récupère les photos confirmées dans l'application
│   │   ├── trainer.py           ← entraînement du modèle
│   │   ├── evaluate.py          ← évaluation du modèle sauvegardé
│   │   ├── images.py            ← liste les images d'un dossier, recadre sur la voiture
│   │   ├── dataset_analyzer.py  ← compte les images par voiture
│   │   └── dataset_preparer.py  ← crée dataset_small (voitures regroupées + « autre »)
│   └── tests/                   ← tests automatiques
│
└── flutter_application_1/       ← L'APPLICATION (Flutter / Dart)
    ├── pubspec.yaml             ← dépendances de l'application
    ├── Dockerfile               ← compile l'application en site web (nginx)
    ├── nginx.conf               ← réglages du serveur web de l'application
    ├── test/                    ← tests de l'application
    └── lib/
        ├── main.dart            ← démarrage de l'application
        ├── models/              ← recognition.dart (résultat de l'IA), scanned_car.dart
        ├── services/            ← api.dart (appels au backend, erreurs), auth_service.dart (compte), car_service.dart (voitures)
        ├── theme/               ← spot_it_theme.dart (couleurs)
        ├── pages/               ← home_page.dart, car_library_page.dart, settings_page.dart
        ├── dialogs/             ← popups : résultat, non reconnue, choix d'une voiture, fiche d'une voiture
        └── widgets/             ← viseur, boutons, image avec cadre, bulles de message
```

---

## 11. Référence technique (API, base de données, IA)

### API du backend (`http://localhost:3000`)

Les routes marquées 🔒 demandent l'en-tête `Authorization: Bearer <token>` (le token est renvoyé par `/login`). Les images sont envoyées en **base64** dans du JSON : `{ "image": "<base64>", "contentType": "image/jpeg" }` (formats : JPEG, PNG, WebP ; 6 Mo maximum). Le serveur vérifie que le contenu correspond vraiment au format annoncé (premiers octets du fichier).

| Méthode | Route | Rôle | Réponses |
|---|---|---|---|
| `POST` | `/api/auth/register` | Crée un compte (`name`, `email`, `password` de 8 caractères minimum) | `201` utilisateur · `400` données invalides · `409` e-mail déjà pris · `429` trop de tentatives |
| `POST` | `/api/auth/login` | Connexion (`email`, `password`) | `200` `{ token, name, email, trainingConsent }` (token valable 7 jours) · `400` · `401` · `429` |
| `GET` | `/api/account` 🔒 | Ton compte | `200` `{ name, email, trainingConsent }` · `401` |
| `PATCH` | `/api/account` 🔒 | Change `name`, `email` (mêmes règles que l'inscription) et/ou l'accord pour entraîner l'IA (`trainingConsent` : `true`/`false`). Le retrait de l'accord supprime tes photos de correction | `200` compte · `400` · `401` · `409` e-mail déjà pris · `429` |
| `DELETE` | `/api/account` 🔒 | Supprime ton compte, tes voitures et tes photos | `204` · `401` · `404` |
| `POST` | `/api/predict` | Reconnaît la voiture d'une photo, **sans compte** | `200` `{ recognized, confidence, box, carId, brand, model, years, suggestions }` si reconnue, sinon `{ recognized: false, reason, confidence, box, suggestions }` · `400` image invalide · `422` image illisible ou abîmée · `503` IA indisponible |
| `POST` | `/api/training-photos` 🔒 | Garde une photo dont l'utilisateur a choisi la bonne voiture (`carId`), pour le prochain entraînement | `201` · `400` image ou voiture invalide · `401` · `403` accord non donné · `429` |
| `GET` | `/api/catalog` | Toutes les voitures que l'IA connaît `[{ carId, brand, model, years }]`, pour choisir la bonne à la main | `200` · `503` IA indisponible |
| `GET` | `/api/cars` 🔒 | Liste tes voitures | `200` liste · `401` |
| `POST` | `/api/cars` 🔒 | Reconnaît **et enregistre** la voiture. `carId` (facultatif) : la voiture choisie par l'utilisateur, dans les suggestions ou dans `/api/catalog` (confiance `0` dans ce cas) | `201` voiture · `400` · `422` voiture non reconnue ou inconnue (rien n'est enregistré) · `503` · `500` |
| `GET` | `/api/cars/:id/image` 🔒 | Renvoie la photo d'une de tes voitures | `200` image · `404` |
| `DELETE` | `/api/cars/:id` 🔒 | Supprime une de tes voitures | `204` · `404` |
| `GET` | `/api/health` | Vérifie que le serveur tourne (utilisé par Docker) | `200` |

Le champ `box` est le rectangle de la voiture, en proportions de l'image (0 à 1) : `{ "x": 0.16, "y": 0.37, "width": 0.60, "height": 0.43 }`. Il vaut `null` si aucune voiture n'a été détectée. Quand la voiture n'est pas reconnue, `reason` vaut `unknown` (l'IA n'est pas assez sûre) ou `no_car` (rien de détecté) et `suggestions` contient les 5 voitures les plus proches `{ carId, brand, model, years, confidence }` (envoyées aussi quand la voiture est reconnue, pour pouvoir la corriger).

### API du service IA (`http://localhost:5000`)

| Méthode | Route | Rôle |
|---|---|---|
| `GET` | `/health` | Vérifie que le service tourne (utilisé par Docker). |
| `GET` | `/cars` | Toutes les voitures de `cars.json`, triées par marque et modèle. |
| `POST` | `/predict` | Reçoit les octets d'une image, renvoie `{ "recognized": true, "reason": null, "confidence": 96.1, "car": { "id": "ferrari_f12_berlinetta_2012_2015", "brand": "Ferrari", "model": "F12 Berlinetta", "from_year": 2012, "to_year": 2015 }, "suggestions": [ … ], "box": {…} }`. `to_year` vaut `null` pour une voiture encore produite. Erreurs : `400` image manquante, `422` image illisible. |

### Base de données (MongoDB, base `spotit`)

**`users`** : `name`, `email` (unique), `password` (haché avec bcrypt, jamais en clair), `trainingConsent` (accord pour entraîner l'IA, `false` par défaut) et `trainingConsentAt` (date de l'accord).

**`cars`** : une photo de la bibliothèque.

| Champ | Contenu |
|---|---|
| `user` | propriétaire (référence vers `users`) |
| `carId` | identifiant de la voiture dans `ai/models/cars.json` |
| `brand`, `model`, `years` | par exemple `Ferrari`, `F12 Berlinetta`, `2012 – 2015` |
| `confidence` | confiance de l'IA, en % (entier) |
| `box` | rectangle de la voiture (ou `null`) |
| `image` | la photo (données + type) |
| `createdAt` | date d'ajout |

**`trainingphotos`** : une photo dont l'utilisateur a choisi la bonne voiture parmi les suggestions (`user`, `carId`, `image`, `createdAt`).

### L'IA en détail

- **Classes** : 1 002 voitures + « autre » (1 003 classes). Données : dataset Kaggle [*Car Model Variants and Images*](https://www.kaggle.com/datasets/eimadevyni/car-model-variants-and-images-dataset) (≈ 3 800 modèles). Une voiture de l'application regroupe plusieurs dossiers du dataset qui sont la même génération (par exemple Clio IV : 5 portes, break, GT, RS), pour avoir assez d'images. Les regroupements sont faits par `python main.py catalog` et écrits dans `ai/models/cars.json`.
- **Images** : toutes les photos du dataset pour chaque voiture (50 au minimum), dont 60 au maximum gardées pour le test, plus les photos confirmées dans l'application ; soit 86 238 images d'entraînement et 22 182 de test. La classe « autre » contient 975 images d'entraînement, prises dans des voitures absentes de la liste.
- **Classifieur** : EfficientNetV2-B3 (poids ImageNet), images en 300 × 300, *data augmentation* qui imite des photos de téléphone (miroir, rotation, zoom, décalage, perspective, luminosité, contraste, saturation, teinte, flou) sur une photo sur deux, l'autre restant intacte, précision mixte 16 bits. Le modèle sauvegardé ne contient pas ces transformations, entraînement en deux temps (nouvelle tête, puis affinage de tout le modèle) sur carte graphique, 15 % des images d'entraînement gardées pour régler les seuils.
- **Résultats mesurés sur 22 182 photos de test** (`ai/models/evaluation/metrics.json`) :

| Mesure | Valeur |
|---|---|
| Bonne voiture en 1ʳᵉ proposition (parmi 1 003 classes) | **80,1 %** |
| Bonne voiture dans les 3 premières | **88,1 %** |
| Réponses justes **quand l'IA répond** (seuil 30 %) | **92,8 %** |
| Voitures de la liste trouvées **et** justes | 74,2 % |
| Voitures hors liste prises à tort pour une voiture connue | 17,3 % |

Pour comparaison, avec 68 voitures et MobileNetV3, l'IA trouvait la bonne en 1ʳᵉ proposition 67,2 % du temps ; avec 979 voitures et MobileNetV3, 55,3 %. Le passage à EfficientNetV2, aux images en 300 × 300 et à l'affinage de tout le modèle a fait gagner plus de 20 points. Le premier entraînement EfficientNetV2 (78,8 %) a duré environ 3 h 30 sur une RTX 4080 SUPER ; le second, avec toutes les photos et l'augmentation « téléphone », a duré environ 5 h 30 (une nuit) et a atteint 80,1 %. Un nouveau modèle n'est gardé que s'il fait mieux que l'ancien sur le test.

Quelques voitures de la première version, part de photos retrouvées : Citroën 2CV 96 %, Ferrari F12 90 %, Fiat 500 Abarth 86 %, Toyota Hilux 89 %. Les voitures françaises sont retrouvées 84 % du temps en moyenne. Le détail de chaque voiture est dans `ai/models/evaluation/metrics_by_class.csv`.

- **Détecteur** : trouve une voiture (ou un pick-up) sur environ 82 % des 172 photos de test au format JPEG, avec un seuil de score de 0,4 (`ai/src/detector.py`).

#### Réentraîner ou évaluer le modèle

Le grand dataset n'est **pas** dans le dépôt (≈ 6 Go) : télécharge-le sur Kaggle (lien ci-dessus) et décompresse-le pour obtenir un dossier contenant `train/` et `test/` (par exemple `ai/dataset/`).

Le plus simple est de passer par Docker (rien à installer). Le grand dataset doit être dans le dossier `archive/` à la racine du projet.

**Entraînement complet de nuit (carte graphique NVIDIA)** : une seule commande, depuis la racine du projet. Elle récupère les photos confirmées dans l'application, prépare le dataset avec **toutes** les photos, entraîne, évalue, puis redémarre le service IA avec le nouveau modèle :

```powershell
docker compose run --rm trainer retrain --source /dataset; docker compose up -d --build ai
```
Compter environ 4 à 6 heures sur une RTX 4080 (sans jouer en même temps). Le nouveau modèle ne remplace l'ancien que s'il fait **au moins aussi bien** sur les photos de test ; sinon l'ancien est gardé et le message « Le nouveau modèle est moins bon » s'affiche. Pour que l'ordinateur ne se mette pas en veille pendant la nuit : Paramètres Windows → Système → Alimentation → mise en veille sur « Jamais ».

**Étape par étape, avec la carte graphique** :

```powershell
docker compose run --rm trainer collect
docker compose run --rm trainer catalog --source /dataset
docker compose run --rm trainer prepare --source /dataset
docker compose run --rm trainer train
docker compose run --rm trainer evaluate
```
Le service `trainer` utilise une image à part (`spotit-ai-gpu`, environ 7 Go à cause des bibliothèques NVIDIA) : il faut un pilote NVIDIA récent et assez de place sur le disque. Au début de l'entraînement, le message « Entraînement sur la carte graphique » confirme que la carte est utilisée ; les calculs se font alors en *précision mixte* (16 bits), environ deux fois plus vite. Le processeur sert encore à lire les photos, mais tous les calculs du modèle sont faits par la carte graphique. Pour suivre l'entraînement en direct dans un autre terminal : `docker logs -f (docker ps -q --filter name=spotit-trainer)`.

**Sans carte graphique**, avec l'image normale (`spotit-ai`) :

```powershell
docker run --rm -v "${PWD}/ai:/app" -v "${PWD}/archive:/dataset" -w /app spotit-ai python main.py prepare --source /dataset
docker run --rm -v "${PWD}/ai:/app" -w /app spotit-ai python main.py train
docker run --rm -v "${PWD}/ai:/app" -w /app spotit-ai python main.py evaluate
```
⚠️ Sur le processeur, l'entraînement l'utilise à fond pendant longtemps (plus d'une heure avec toutes les voitures) : l'ordinateur chauffe et les ventilateurs tournent à fond, c'est normal.

`prepare` ne copie pas les photos : il crée des liens vers celles du grand dataset, ce qui ne prend presque pas de place (une copie n'est faite que si les deux dossiers sont sur des disques différents).

| Commande | Action | Besoin |
|---|---|---|
| `python main.py analyze --source …` | Compte les images par voiture du grand dataset | le grand dataset |
| `python main.py catalog --source …` | Complète `cars.json` avec toutes les voitures du dataset qui ont au moins 50 photos (les fiches déjà présentes sont gardées) | le grand dataset |
| `python main.py collect` | Récupère dans MongoDB les photos confirmées (voitures ajoutées à une bibliothèque, corrections) des utilisateurs qui l'ont accepté, dans `ai/dataset_user/`, recadrées sur la voiture. Efface celles qui ont été supprimées ou dont l'accord a été retiré | `MONGODB_URI` |
| `python main.py prepare --source …` | Crée `dataset_small` à partir de `cars.json` (remplace l'ancien) : toutes les photos du dataset, 60 photos de test par voiture, et les photos de `dataset_user` | le grand dataset |
| `python main.py train` | **Entraîne** le modèle ; s'il est au moins aussi bon que l'actuel, calcule les seuils et écrit `spotit_classifier.keras`, `classes.json`, `recognition.json` | `dataset_small` |
| `python main.py retrain --source …` | `collect`, `prepare`, `train` puis `evaluate` : l'entraînement complet de la nuit | le grand dataset |
| `python main.py evaluate` | Évalue le modèle sauvegardé (métriques, erreurs, grosses confusions) dans `models/evaluation/` | `dataset_small` |
| `python main.py predict` | Tente l'image `images/f12.jpg` | — |
| `python main.py` | Menu interactif avec les mêmes choix | — |

**Comment `catalog` choisit les voitures** : chaque dossier du dataset est une variante (Clio 5 portes 2012-2016, Clio Estate 2013-2016, Clio RS…). Le script enlève la carrosserie et la finition du nom (5 portes, break, coupé, RS, GT…), le code de châssis en fin de nom (« 3 Series E90 » et « 3 Series Touring E91 » sont la même voiture) et rassemble les doublons d'écriture (« GLK-Klasse » et « GLK »). Il regroupe ensuite les variantes d'un même modèle sorties à 2 ans d'écart au plus : c'est une génération. Deux modèles différents (206 et 207, 3008 et 5008) ne sont jamais regroupés. Les années affichées viennent du fichier `data_full.csv` du dataset.

**Ajouter une voiture à la main** : ajoute une fiche dans `ai/models/cars.json` (`id`, `brand`, `model`, `from_year`, `to_year` (`null` si encore produite), et la liste des dossiers du dataset dans `sources`), puis refais `prepare`, `train`, `evaluate`.

### Sécurité
- Les mots de passe sont **hachés** (bcrypt, 8 caractères minimum). Les connexions utilisent un **token JWT** signé par `JWT_SECRET` ; sans cette variable, une clé aléatoire est créée à chaque démarrage.
- Les données reçues sont vérifiées (types, format de l'e-mail, taille des images, et contenu des images comparé au format annoncé) avant d'être utilisées, ce qui évite les injections dans les requêtes MongoDB.
- Les connexions, les modifications du compte et les analyses de photos sont **limitées en nombre** (protection contre les essais en boucle). Le service IA refuse aussi les envois de plus de 8 Mo et les images abîmées.
- Le backend ajoute des en-têtes de sécurité (`helmet`) et accepte toutes les origines par défaut ; `CORS_ORIGIN` permet de les restreindre.
- Chaque utilisateur ne voit et ne supprime **que ses propres voitures**. La suppression du compte efface aussi toutes ses voitures et ses photos.
- Les conteneurs du backend et de l'IA ne tournent pas en administrateur.
- Le fichier `.env` ne doit **jamais** être commité (il est dans `.gitignore`).
- Pour une vraie mise en production il resterait à ajouter : HTTPS, une limitation de débit derrière un proxy, et la rotation des clés.

---

## 12. Travailler sur le projet (Git, bonnes pratiques)

- **Branches** : `main` (version de référence, avec l'application, l'IA et les rapports), `backend-mongodb` (application + bibliothèque en ligne), `test_mobilenet_python_thomas` (travail sur le modèle), `flutter_dev` (ancienne version de l'application), `ia-integration` (fusion application + IA).
- **Récupérer les dernières modifications** : `git pull`, puis, si besoin, relance `npm install` dans `backend`, `ai\.venv\Scripts\python.exe -m pip install -r ai\requirements.txt` et `flutter pub get`.
- **Avant chaque `git add`/commit**, lance `git status` et vérifie :
  - `.env` n'apparaît pas ;
  - les fichiers régénérés par Flutter (`windows/`, `linux/`, `macos/`, `analysis_options.yaml`) ne sont pas ajoutés.
- **Messages de commit** : courts, en anglais, qui disent ce qui a été fait (ex. `Add car detection frame and UI updates`).
- **Avec Docker** : après une modification du code, relance `docker compose up --build` pour reconstruire les conteneurs.
- **Code propre** : pas de code mort ni de copier-coller ; les parties communes sont regroupées (widgets partagés dans `widgets/spot_it_widgets.dart`, vérification d'image dans `backend/middleware/uploadedImage.js`, chemins de l'IA dans `ai/src/config.py`).

---

## 13. État d'avancement par rapport au sujet

| Exigence du sujet | État |
|---|---|
| Acquisition d'images (appareil photo, import depuis la galerie) | ✅ photo et galerie (l'appareil photo fonctionne sur téléphone ; en navigateur c'est un sélecteur de fichiers) |
| Modèle pré-entraîné de reconnaissance (MobileNet, SSD…) | ✅ EfficientNetV2 + SSD MobileNet |
| Cadres autour des objets détectés et noms | ✅ cadre rouge + marque et modèle |
| Pourcentage de confiance | ✅ jauge colorée |
| Base de données de catégories | ✅ 1 002 voitures de 64 marques (fiches dans `cars.json`) |
| Ajouter de nouvelles catégories | 🟡 possible en réentraînant (fiche dans `cars.json` puis `main.py`), pas encore depuis l'application |
| Apprentissage personnalisé avec les images de l'utilisateur | ✅ photos confirmées ou corrigées dans l'application, ajoutées à chaque réentraînement |
| Interface intuitive + historique des reconnaissances | ✅ bibliothèque personnelle avec fiches |
| Sauvegarder les résultats | ✅ photo, résultat et cadre enregistrés |
| Base de données en ligne partagée | ✅ MongoDB Atlas |
| Reconnaissance en temps réel / TensorFlow Lite sur mobile | 🟡 le détecteur est au format TensorFlow Lite mais tourne sur le serveur ; embarquement dans le téléphone à faire |

**Livrables** : push hebdomadaire + rapport court (chaque vendredi 18 h), rapport technique le **06/01/2027**, soutenance avec démonstration le **08/01/2027**.

---

## 14. Limites connues et suite

**Limites actuelles**
- L'IA connaît **1 002 voitures**, mais beaucoup ont seulement 50 à 100 photos. Ses erreurs sont surtout des années : elle confond une voiture avant et après restylage (Audi A5 2007 et 2011, Volvo XC90 2014 et 2019, Mercedes GLK 2008 et 2012) ; la marque et le modèle sont alors justes. Environ 17 % des voitures hors liste sont prises pour une voiture connue.
- Les photos du dataset sont des photos de presse, propres et bien cadrées : sur des photos prises au téléphone, l'IA est moins sûre d'elle et répond plus souvent « non reconnue », mais sa 1ʳᵉ suggestion est souvent la bonne voiture.
- Elle hésite entre voitures qui se ressemblent (Peugeot 3008 et 5008, 206 et 307…) : 67,2 % de bonnes réponses en 1ʳᵉ proposition, 53,5 % des voitures trouvées avec les seuils actuels. Plusieurs voitures n'ont que 50 à 100 photos d'entraînement.
- La confiance paraît parfois basse même sur une bonne réponse (voir [section 2](#la--confiance--en-clair)).
- Le détecteur rate certaines photos (intérieur, très rapproché) : alors pas de cadre.
- La connexion n'est gardée qu'**en mémoire** : on doit se reconnecter à chaque redémarrage de l'application.
- Le bouton « Ajouter » relance l'IA côté serveur (analyse en double volontaire : on ne fait pas confiance à un résultat envoyé par l'application).
- Les tests automatiques couvrent les fiches, la préparation du dataset, les seuils, le serveur IA, le backend et la lecture des réponses dans l'application ; il n'y a pas encore de test des écrans.
- Le backend et l'IA ne tournent qu'en local.

**Pistes pour la suite**
1. Constituer un petit jeu de vraies photos prises au téléphone pour régler le seuil « non reconnue » sur des conditions réelles.
2. Raretés et points par voiture (« Ferrari = légendaire »), fiche enrichie, filtres, score total.
3. Garder la connexion sur l'appareil (`shared_preferences`).
4. Corriger une voiture qui n'est pas dans les 5 suggestions (recherche dans toute la liste), et lancer le réentraînement automatiquement chaque nuit (tâche planifiée).
5. Faire tourner l'IA **sur le téléphone** (TensorFlow Lite) et tester sur Android.
6. Héberger le backend et l'IA en ligne.

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
- **Classifieur** : EfficientNetV2-B3 (Keras), poids pré-entraînés ImageNet.
- Projet pédagogique, réalisé pour la SAE 5.01. Utilisation de l'IA dans le développement documentée dans les rapports hebdomadaires de l'équipe.
