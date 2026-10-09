# SPOT'IT — Prototype IA MobileNetV3

Ce dossier contient le premier prototype de reconnaissance de modèles de voitures de SPOT'IT.

Le modèle utilise **MobileNetV3Small** avec du **Transfer Learning** à partir des poids pré-entraînés sur ImageNet.

## Modèles actuellement reconnus

Le prototype a été entraîné sur 6 classes :

- BMW Z4 Coupé E86 (2006–2009)
- BMW Z4 M Roadster E85 (2006–2009)
- BMW Z4 Roadster E89 (2009–2013)
- BMW Z4 Roadster LCI E89 (2013–2016)
- BMW Z4 G29 (2018–présent)
- Mazda MX-5 Miata (2015–présent)

Il s'agit pour l'instant d'un prototype permettant de valider le fonctionnement de MobileNetV3.

## Structure

```text
ai/
├── images/
│   ├── mx5.jpg
│   └── z4.jpg
│
├── models/
│   ├── classes.json
│   └── spotit_mobilenet.keras
│
├── src/
│   ├── predict.py
│   ├── prepare_dataset.py
│   ├── test_mobilenet.py
│   └── train.py
│
└── README.md
```

## Installation

### 1. Se placer dans le dossier IA

Depuis la racine du projet :

```bash
cd ai
```

### 2. Créer un environnement virtuel Python

```bash
python -m venv .venv
```

### 3. Activer l'environnement

Sous PowerShell :

```powershell
.\.venv\Scripts\Activate.ps1
```

Si PowerShell bloque l'exécution du script :

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

Puis :

```powershell
.\.venv\Scripts\Activate.ps1
```

### 4. Installer les dépendances

```bash
pip install -r requirements.txt
```

## Tester le modèle déjà entraîné

Le modèle entraîné est disponible dans :

```text
models/spotit_mobilenet.keras
```

Les classes associées au modèle sont stockées dans :

```text
models/classes.json
```

Pour tester le modèle, placer une image dans :

```text
images/
```

Par défaut, `predict.py` utilise :

```text
images/z4.jpg
```

Pour utiliser une autre image, modifier dans `src/predict.py` :

```python
IMAGE_PATH = "images/z4.jpg"
```

Puis lancer :

```bash
python src/predict.py
```

Le programme affiche le modèle de voiture prédit ainsi que le niveau de confiance.

Exemple :

```text
Voiture détectée : BMW_Z4_M_Roadster_E85_20062009
Confiance : 78.42 %
```

## Entraînement

Le modèle utilise :

- MobileNetV3Small
- poids pré-entraînés ImageNet
- images 224 × 224
- data augmentation
- Transfer Learning
- couche finale Softmax pour les différentes classes

Pour le premier prototype, les couches de MobileNetV3 sont gelées :

```python
base_model.trainable = False
```

Seule la nouvelle tête de classification est entraînée.

Le premier entraînement a été effectué pendant 10 epochs.

Résultat obtenu lors du premier test :

```text
accuracy     ≈ 75 %
val_accuracy ≈ 63 %
```

Ces performances sont expérimentales et le modèle doit encore être amélioré.

## Dataset

Le dataset complet n'est pas stocké sur Git en raison de sa taille.

Dataset utilisé :

**Car Model Variants and Images Dataset (Kaggle)**

Le dataset contient environ :

- 3 778 classes
- 152 895 images d'entraînement
- 40 115 images de test

Pour ce prototype, seules 6 classes ont été sélectionnées.

La structure attendue est :

```text
dataset/
├── train/
│   ├── classe_1/
│   ├── classe_2/
│   └── ...
│
└── test/
    ├── classe_1/
    ├── classe_2/
    └── ...
```

Le script :

```text
src/prepare_dataset.py
```

permet de créer `dataset_small/` contenant uniquement les classes utilisées pour le prototype.

## Scripts

### `test_mobilenet.py`

Vérifie que TensorFlow et MobileNetV3 fonctionnent correctement.

### `prepare_dataset.py`

Sélectionne les classes utilisées pour le prototype depuis le dataset complet.

### `train.py`

Charge les images et entraîne la tête de classification basée sur MobileNetV3.

Le modèle obtenu est sauvegardé dans :

```text
models/spotit_mobilenet.keras
```

### `predict.py`

Charge le modèle déjà entraîné et effectue une prédiction sur une nouvelle image.

## Limitations actuelles

Le prototype est encore expérimental.

Des erreurs de classification ont notamment été observées entre des générations proches de BMW Z4.

Les prochaines pistes d'amélioration sont :

- évaluer précisément les performances classe par classe ;
- créer une matrice de confusion ;
- équilibrer davantage les classes ;
- améliorer la data augmentation ;
- effectuer du fine-tuning sur les dernières couches de MobileNetV3 ;
- augmenter progressivement le nombre de modèles reconnus.