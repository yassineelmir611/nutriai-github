# NutriAI — Assistant nutritionnel avec intelligence artificielle

NutriAI est un projet académique qui associe une application **Flutter**, un modèle de reconnaissance alimentaire **EfficientNet-B2** et un assistant conversationnel utilisant **Groq**. Il permet de photographier un repas, d’estimer ses apports nutritionnels et de suivre ses objectifs quotidiens.

Cette version rassemble le code nécessaire au lancement et les travaux d’entraînement dans un dépôt nettoyé. Le dossier original a été conservé séparément. **Aucune clé API personnelle n’est fournie.**

## Sommaire

- [Fonctionnalités](#fonctionnalités)
- [Architecture et contenu](#architecture-et-contenu)
- [Prérequis](#prérequis)
- [Démarrage rapide sans clé API](#démarrage-rapide-sans-clé-api)
- [Installation des services Python](#installation-des-services-python)
- [Lancement complet](#lancement-complet)
- [Configuration des connexions](#configuration-des-connexions)
- [API](#api)
- [Modèle et estimations nutritionnelles](#modèle-et-estimations-nutritionnelles)
- [Données et entraînement](#données-et-entraînement)
- [Tests et intégration continue](#tests-et-intégration-continue)
- [Dépannage](#dépannage)
- [Publication sur GitHub](#publication-sur-github)
- [Limites et licence](#limites-et-licence)

## Fonctionnalités

- Création d’un profil : nom, taille, poids et objectifs nutritionnels.
- Tableau de bord : calories, protéines, lipides et suivi des repas.
- Analyse d’une photo provenant de la caméra ou de la galerie.
- Affichage des trois meilleures prédictions du modèle alimentaire.
- Ajustement des apports selon la quantité consommée en grammes.
- Historique, galerie, modification et suppression des repas.
- Chat nutritionnel utilisant les objectifs et la consommation du jour.
- Compteur de pas sur les appareils compatibles, avec autorisation système.
- Persistance locale avec Hive et préférences de thème.

L’interface de l’application est principalement en anglais. Le chatbot adapte ses réponses à la langue du message.

## Architecture et contenu

```text
Flutter
  ├── photo ───────────────► FastAPI food_server :8000
  │                              └── EfficientNet-B2 + estimations nutritionnelles
  ├── message + objectifs ─► FastAPI chatbot_server :8001
  │                              ├── règles locales pour certaines questions chiffrées
  │                              └── API Groq pour les autres questions
  └── profil / repas / historique ─► stockage Hive sur l’appareil
```

```text
nutriai-github/
├── README.md
├── .github/workflows/ci.yml        # Contrôles GitHub Actions
├── scripts/check_publication.py   # Contrôle des fichiers publiables
├── requirements-dev.txt          # pytest et client HTTP pour les tests
├── application/
│   ├── lib/                      # Application Flutter : écrans, état, services, modèles
│   ├── test/                     # Tests Flutter
│   ├── android/ ios/ windows/    # Projets natifs
│   ├── linux/ macos/ web/        # Autres cibles conservées, avec limites ci-dessous
│   ├── backend/
│   │   ├── food_server/          # main.py, model_runtime.py, requirements.txt, tests/
│   │   └── chatbot_server/       # main.py, .env.example, requirements.txt, tests/
│   ├── modelEFF/
│   │   └── effnetb2_food101 (3).pth
│   ├── pubspec.yaml
│   ├── pubspec.lock
│   ├── start_all.ps1             # Lancement Windows ; Ctrl+C pour arrêter
│   └── connect_phone.ps1         # Connexion Android par USB
├── data/                         # Collecte, dédoublonnage et renommage des images
└── train/                        # Notebooks Kaggle/Colab et utilitaires historiques
```

Les jeux d’images, documents de soutenance, installateurs, SDK, environnements virtuels, journaux et compilations sont exclus. Les dépendances doivent être installées sur chaque poste.

## Prérequis

| Élément | Version utilisée pour la préparation | Remarque |
| --- | --- | --- |
| Flutter | **3.38.9 stable** | La CI utilise cette version. |
| Dart | **3.10.8**, inclus dans Flutter | Les dépendances verrouillées demandent Dart ≥ 3.10.3 et Flutter ≥ 3.38.4. |
| Python | **3.11.9** | Python 3.11 est utilisé dans la CI. |
| PyTorch / torchvision | **2.5.1 / 0.20.1** | Installation CPU possible ; GPU facultatif pour l’inférence. |
| FastAPI / Uvicorn | **0.115.0 / 0.30.6** | Versions fixées dans les services. |
| Groq SDK | **0.31.0** | Clé nécessaire uniquement pour les réponses distantes du chatbot. |
| Git | Installation locale | Nécessaire à Flutter et à la publication. |

Installer également les outils correspondant à la cible : Android SDK et appareil/émulateur pour Android ; Visual Studio avec les outils C++ pour Windows ; Xcode sur macOS pour iOS. Le projet Android utilise Java 17 et le NDK `27.3.13750724`, téléchargé par les outils Android si nécessaire.

```powershell
flutter --version
flutter doctor
python --version
git --version
```

Sur Windows, activer le **Mode développeur Windows** si Flutter demande la prise en charge des liens symboliques. Aucun SDK Android ou Flutter n’est embarqué dans le dépôt.

## Démarrage rapide sans clé API

Dans le dossier du dépôt :

```powershell
cd application
flutter pub get --enforce-lockfile
flutter devices
flutter run --dart-define=USE_MOCK_API=true
```

Choisir un appareil Android ou une cible de bureau disponible. On peut préciser `-d windows` ou l’identifiant affiché par `flutter devices`.

Avec `USE_MOCK_API=true`, l’analyse des repas et le chat utilisent des réponses simulées locales : **aucun serveur Python, modèle chargé ou compte Groq n’est nécessaire**. Les résultats sont des exemples et ne correspondent pas au contenu de la photo. Le mode normal utilise les services réels par défaut.

## Installation des services Python

Les commandes suivantes partent de la racine du dépôt. Elles ne nécessitent pas d’activer les environnements virtuels.

### Windows — PowerShell

Service d’analyse alimentaire, version CPU :

```powershell
python -m venv application/backend/food_server/.venv
application/backend/food_server/.venv/Scripts/python.exe -m pip install torch==2.5.1 torchvision==0.20.1 --index-url https://download.pytorch.org/whl/cpu
application/backend/food_server/.venv/Scripts/python.exe -m pip install -r application/backend/food_server/requirements.txt
```

Service de chat :

```powershell
python -m venv application/backend/chatbot_server/.venv
application/backend/chatbot_server/.venv/Scripts/python.exe -m pip install -r application/backend/chatbot_server/requirements.txt
Copy-Item application/backend/chatbot_server/.env.example application/backend/chatbot_server/.env
```

Si `.env` existe déjà, conserver son contenu plutôt que le remplacer. Éditer le fichier **local** `application/backend/chatbot_server/.env` :

```dotenv
GROQ_API_KEY=
GROQ_MODEL=llama-3.3-70b-versatile
```

Renseigner la clé après `GROQ_API_KEY=` uniquement sur son propre poste. Le modèle Groq doit être disponible dans le compte utilisé ; changer `GROQ_MODEL` si nécessaire. Une variable d’environnement du processus a priorité sur le `.env`. **La clé reste côté Python et ne doit jamais être placée dans le code Flutter ou dans `--dart-define`.**

Sans clé, les règles locales peuvent répondre à certaines questions sur les calories, protéines ou lipides restants. Les autres questions renvoient une erreur `503`. Pour essayer l’ensemble de l’interface sans clé, utiliser le mode démo.

### Linux / macOS — terminal

```bash
python3.11 -m venv application/backend/food_server/.venv
application/backend/food_server/.venv/bin/python -m pip install -r application/backend/food_server/requirements.txt

python3.11 -m venv application/backend/chatbot_server/.venv
application/backend/chatbot_server/.venv/bin/python -m pip install -r application/backend/chatbot_server/requirements.txt
cp -n application/backend/chatbot_server/.env.example application/backend/chatbot_server/.env
```

Sous Linux, on peut installer d’abord les versions CPU de PyTorch avec la commande Windows ci-dessus en remplaçant le chemin de l’interpréteur par `.venv/bin/python`. Sous macOS, utiliser les paquets du registre PyPI par défaut. L’entraînement GPU demande une configuration CUDA adaptée à la machine.

## Lancement complet

### Windows — script de lancement

Après installation des deux environnements Python :

```powershell
cd application
.\start_all.ps1 -Device windows
```

Le script démarre les services en arrière-plan, affiche leur état, puis lance Flutter dans le terminal courant. Il s’arrête si un port est déjà occupé. À la fermeture de Flutter ou avec Ctrl+C, il arrête uniquement les services qu’il a lui-même démarrés.

Variantes :

```powershell
# Services uniquement ; laisser ce terminal ouvert.
.\start_all.ps1 -NoFlutter

# Démo sans services Python.
.\start_all.ps1 -Device windows -UseMockApi

# Émulateur Android : remplacer l’identifiant par celui de flutter devices.
.\start_all.ps1 -Device emulator-5554 -BaseUrl http://10.0.2.2

# Téléphone en Wi-Fi : remplacer l’adresse d’exemple par l’IPv4 du PC.
.\start_all.ps1 -Device IDENTIFIANT_APPAREIL -BaseUrl http://192.168.1.10

# Services déjà démarrés avec d’autres ports.
.\start_all.ps1 -NoBackend -FoodPort 8100 -ChatPort 8101
```

Si PowerShell bloque les scripts téléchargés, consulter la stratégie d’exécution de son poste ou utiliser les commandes manuelles ci-dessous.

### Commandes manuelles — trois terminaux

Depuis la racine du dépôt, dans le premier terminal Windows :

```powershell
cd application/backend/food_server
.\.venv\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000
```

Dans le deuxième :

```powershell
cd application/backend/chatbot_server
.\.venv\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8001
```

Dans le troisième :

```powershell
cd application
flutter run --dart-define=FOOD_API_URL=http://127.0.0.1:8000 --dart-define=CHAT_API_URL=http://127.0.0.1:8001
```

Sous Linux/macOS, utiliser `.venv/bin/python` à la place de `.venv/Scripts/python.exe`. Les répertoires courants restent les mêmes : chaque serveur est lancé depuis son propre dossier.

## Configuration des connexions

La configuration Flutter est définie à la compilation ; relancer l’application avec les bons arguments après un changement.

| Option `--dart-define` | Valeur par défaut | Usage |
| --- | --- | --- |
| `FOOD_API_URL` | `http://127.0.0.1:8000` | URL complète du service alimentaire, sans `/` final. |
| `CHAT_API_URL` | `http://127.0.0.1:8001` | URL complète du service de chat, sans `/` final. |
| `BASE_URL` | `http://127.0.0.1` | Compatibilité : hôte sans port ; les ports 8000 et 8001 sont ajoutés. |
| `USE_MOCK_API` | `false` | `true` active les réponses simulées pour les deux services. |

Une URL spécifique a priorité sur `BASE_URL` pour le service correspondant. Ces URL désignent la base du service ; ne pas y ajouter `/analyze-food` ou `/nutrition-chat`.

| Cible | Adresse des services |
| --- | --- |
| Application sur le même ordinateur | `http://127.0.0.1:8000` et `:8001` |
| Émulateur Android standard | `http://10.0.2.2:8000` et `:8001` |
| Téléphone sur le même Wi-Fi | IPv4 locale du PC, ports 8000 et 8001 ; autoriser ces connexions dans le pare-feu. |
| Téléphone Android en USB avec `adb reverse` | `http://127.0.0.1:8000` et `:8001` vus depuis le téléphone. |
| Services hébergés séparément | Par exemple `https://food.example.test` et `https://chat.example.test` à remplacer par les domaines réels. |

Pour Android par USB, activer le débogage USB et autoriser le PC. Démarrer les services dans un premier terminal avec `start_all.ps1 -NoFlutter`, puis dans un autre terminal situé dans `application/` :

```powershell
.\connect_phone.ps1 -RebuildApk -InstallApk
```

Le script utilise `adb` disponible dans le PATH, `ANDROID_SDK_ROOT`, `ANDROID_HOME` ou l’emplacement Android habituel de Windows. Il configure les deux redirections et installe un APK de débogage. Il ne démarre pas les serveurs. Avec des ports personnalisés, fournir `-FoodPort` et `-ChatPort` et reconstruire l’APK.

## API

La documentation interactive est disponible lorsque les services tournent :

- Analyse : [Swagger local](http://127.0.0.1:8000/docs), [état](http://127.0.0.1:8000/health).
- Chat : [Swagger local](http://127.0.0.1:8001/docs), [état](http://127.0.0.1:8001/health).

### `POST /analyze-food` — port 8000

Envoyer une requête multipart avec le champ **`image`** :

```powershell
curl.exe -X POST http://127.0.0.1:8000/analyze-food -F "image=@repas.jpg"
```

Sous Linux/macOS, utiliser `curl`. Le fichier doit être une image décodable, non vide, d’au plus **12 Mio**. Les fichiers invalides renvoient `400` et les fichiers trop volumineux `413`.

La réponse comprend `food_name`, `raw_label`, `confidence`, `top_predictions`, `nutrition`, `vitamins`, `portion_unit`, `timestamp` et `source`. Les valeurs nutritionnelles correspondent à **100 g** (`portion_unit: per_100g`) ; l’application ajuste les quantités selon le poids saisi.

### `POST /nutrition-chat` — port 8001

Exemple de corps JSON à envoyer depuis Swagger :

```json
{
  "name": "Demo",
  "msg_history": ["user:Bonjour", "ai:Bonjour !"],
  "foods": ["Couscous"],
  "meal_summaries": [],
  "new_msg": "Combien de protéines me reste-t-il aujourd’hui ?",
  "nutritional_goals": {"calories": 2000, "protein": 100, "fat": 70},
  "current_consumption": {"calories": 1000, "protein": 40, "fat": 30}
}
```

La réponse contient `response`, `remaining_goals`, `timestamp`, `source` et `model`. `source` distingue `local_rules` de `groq`. Les anciens noms `Nutritional goals`, `Current_consumption` et les clés de macros avec majuscules restent acceptés.

Un message vide renvoie `400`, des données obligatoires absentes `422`, et une génération distante indisponible `503`. Une réponse `200` à `/health` signifie que le processus répond : vérifier aussi `model_loaded` côté analyse et `llm_ready` côté chat.

## Modèle et estimations nutritionnelles

Le checkpoint `application/modelEFF/effnetb2_food101 (3).pth` est inclus dans le dépôt : **31 932 825 octets**, soit environ 32 Mo. Git LFS n’est pas nécessaire pour ce fichier.

Empreinte SHA-256 :

```text
f21dae4472fac66af4c53f9a1187bf6319c23ffbb2b4ba4673903fae795e32be
```

Le service reconstruit EfficientNet-B2 avec la liste de classes définie dans `model_runtime.py`, puis charge les poids sur CUDA si disponible, sinon sur CPU. Le chargement utilise `weights_only=True`. Aucun réentraînement n’est nécessaire pour démarrer l’application.

Conserver **un seul checkpoint compatible** dans `modelEFF/` : le service prend le premier fichier `.pth` ou `.pt` par ordre alphabétique. Une erreur d’architecture ou d’ordre des classes rend les prédictions incompatibles. Aucun taux de précision n’est annoncé ici : il faudrait l’évaluer sur un jeu de test identifié.

La reconnaissance d’aliments et l’estimation nutritionnelle sont deux étapes distinctes. Les calories et macronutriments proviennent de valeurs et règles codées dans le service. Les vitamines sont également estimées ; leurs valeurs ne constituent pas un dosage mesuré ni une table de référence validée. La photo ne mesure pas le poids du repas : l’utilisateur saisit sa portion.

Si le modèle manque ou échoue, le service conserve un **mode de secours heuristique** fondé sur le nom du fichier et la couleur moyenne de l’image. La réponse indique `source: heuristic_fallback` et une confiance de `0.55`. Ce mode permet une démonstration mais ne remplace pas la reconnaissance du modèle. Vérifier `/health` pour confirmer `model_loaded: true` et `source: efficientnet_b2` dans une analyse réelle.

## Données et entraînement

Les images brutes ne sont pas distribuées. Créer son propre dossier local, ignoré par Git :

```text
datasets/tunisian/
├── couscous/
│   ├── 000001.jpg
│   └── ...
├── brik_oeuf/
└── ...
```

### Outils de préparation

Depuis la racine du dépôt, dans un environnement Python réservé à ces outils :

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r data/requirements.txt

# Prévisualiser les doublons exacts et visuels sans toucher aux images.
.\.venv\Scripts\python.exe data/dedupe_images.py --data-path datasets/tunisian --dry-run
.\.venv\Scripts\python.exe data/dedupe_images_visual.py --data-path datasets/tunisian --dry-run
.\.venv\Scripts\python.exe data/renumber_images.py --data-path datasets/tunisian --dry-run
```

Le dédoublonnage déplace normalement les doublons dans un sous-dossier ; l’option `--delete` les supprime définitivement. Le renommage modifie les noms sans `--dry-run`. Travailler sur une copie de ses données.

`food_scraper.py --data-path datasets/tunisian` collecte des images à partir des recherches définies dans le script. Le lancer volontairement seulement après vérification des sources : il télécharge des fichiers et peut supprimer des doublons ou des images excédentaires. Aucun scraping n’est exécuté par les tests ou la CI.

### Notebooks

- `Copie_de_Untitled43.ipynb` : préparation des jeux de données Kaggle/Drive, entraînement et évaluation.
- `kaggle_t4x2_drive_datasets.ipynb` : variante Kaggle/Colab avec fusion et échantillonnage des données, gestion GPU et cache Drive. Son nom historique ne garantit pas une configuration multi-GPU ; consulter les paramètres effectifs.

Les deux notebooks sont fournis sans sorties, historique d’exécution ou métadonnées personnelles. Ils référencent le jeu public [Food-101 sur Kaggle](https://www.kaggle.com/datasets/kmader/food41). Ajouter ses propres données tunisiennes et configurer `DATASET_ROOT`, `KAGGLE_DATASET_ROOT`, `DRIVE_DATASET_ROOT` ou un lien ZIP personnel dans son environnement. Les liens Drive personnels ont été retirés.

Sur Kaggle, ajouter les données avec **Add Input** et sélectionner un accélérateur adapté. Sur Colab, importer le notebook, choisir un runtime GPU et configurer les données avant de lancer les cellules. Les identifiants Kaggle éventuels doivent être renseignés dans les secrets de la plateforme ou dans un `kaggle.json` local ignoré par Git. Ne jamais les écrire dans une cellule publiée.

`train/requirements.txt` liste les dépendances pour explorer les notebooks localement. Les paquets propres à Colab sont fournis par son runtime. Les cellules d’installation GPU peuvent modifier PyTorch : vérifier la compatibilité CUDA/GPU avant exécution. Un entraînement complet n’est pas exécuté par la CI.

L’ordre des classes et le nombre de sorties du modèle entraîné doivent correspondre à `CLASS_NAMES` dans le serveur. En particulier, la variante Colab limite Food-101 à 50 classes par défaut : son checkpoint ne peut pas remplacer automatiquement celui fourni.

### Utilitaires historiques

`inspect_vf_gpu.py`, `update_vf_dataset_root.py`, `update_vf_eval.py` et `revert_kaggle_drive.py` visaient un ancien fichier **`VF.ipynb`, absent du projet fourni**. Ils sont conservés comme outils historiques et demandent désormais explicitement le chemin d’un notebook. Les outils `update_*` et `revert_*` modifient ce fichier : leur donner une copie de travail, jamais une version à conserver.

```powershell
python train/inspect_vf_gpu.py chemin/vers/copie.ipynb
python train/update_vf_dataset_root.py chemin/vers/copie.ipynb --data-path datasets/tunisian
```

Ces scripts ne sont nécessaires ni au lancement de NutriAI ni à l’inférence du modèle inclus.

## Tests et intégration continue

### Flutter

```powershell
cd application
flutter pub get --enforce-lockfile
flutter analyze
flutter test
```

Les tests vérifient le démarrage de l’application et la configuration des URL. La CI vérifie aussi deux services sur des domaines distincts, la priorité sur `BASE_URL`, le mode démo et l’adresse de l’émulateur Android.

### Services Python

Depuis la racine du dépôt :

```powershell
application/backend/food_server/.venv/Scripts/python.exe -m pip install -r requirements-dev.txt
application/backend/chatbot_server/.venv/Scripts/python.exe -m pip install -r requirements-dev.txt

cd application/backend/food_server
.\.venv\Scripts\python.exe -m pip check
.\.venv\Scripts\python.exe -m pytest -q

cd ../chatbot_server
.\.venv\Scripts\python.exe -m pip check
.\.venv\Scripts\python.exe -m pytest -q
```

Les tests alimentaires chargent le **checkpoint inclus sur CPU** et effectuent une inférence sur une image synthétique. Ils couvrent aussi le modèle absent, les images invalides et la limite d’envoi. Les tests du chatbot désactivent le chargement du `.env`, retirent la clé du processus de test et interdisent la création d’un client Groq distant. Aucun appel payant n’est effectué.

Le workflow `.github/workflows/ci.yml` exécute ces contrôles à chaque push, pull request ou lancement manuel, sans secret GitHub à configurer. Les téléchargements de dépendances nécessitent Internet ; leur disponibilité reste extérieure au projet. Le compte rendu local figure dans [VALIDATION.md](VALIDATION.md).

## Dépannage

| Symptôme | Vérification ou solution |
| --- | --- |
| Flutter demande le support des symlinks | Activer le Mode développeur Windows, puis relancer `flutter pub get`. |
| SDK Dart incompatible | Utiliser Flutter 3.38.9 avec son Dart intégré ; conserver `pubspec.lock`. |
| Service inaccessible depuis Android | Utiliser `10.0.2.2` pour l’émulateur ou l’IPv4 du PC pour le Wi-Fi ; vérifier le pare-feu et les ports. |
| Android bloque une connexion HTTP | Le HTTP local est autorisé dans la variante **debug** ; utiliser HTTPS pour une distribution release. |
| Chat en erreur `503` | Vérifier `GROQ_API_KEY`, `GROQ_MODEL`, la connexion Internet et les journaux. Sinon utiliser `USE_MOCK_API=true`. |
| `/health` répond mais l’IA n’est pas prête | Vérifier `model_loaded` ou `llm_ready`, puis `load_error`. |
| Résultat alimentaire toujours approximatif | Vérifier `source` : `heuristic_fallback` signale que le modèle n’a pas pu être utilisé. |
| Port déjà occupé | Arrêter soi-même le service concerné ou choisir d’autres ports ; le script ne ferme aucun processus existant. |
| Caméra ou podomètre indisponible | Vérifier les permissions et le support matériel ; le compteur de pas n’est pas disponible sur toutes les cibles. |
| Compilation Windows impossible | Installer les outils C++ de Visual Studio et consulter `flutter doctor`. |
| Serveur lancé depuis la racine | Se placer dans `application/backend/food_server` ou `chatbot_server` avant `uvicorn main:app`. |

## Publication sur GitHub

Le dépôt local est indépendant et utilise la branche `main`. Il n’est associé à aucun dépôt distant. Depuis sa racine :

```powershell
python scripts/check_publication.py
git status --short
git add .
git diff --cached --stat
git commit -m "Préparer NutriAI pour GitHub"
```

Si Git demande une identité, configurer son nom et son adresse de commit localement. Sur GitHub, créer un **dépôt vide**, sans README ni licence générés, puis remplacer `TON_COMPTE` et éventuellement le nom du dépôt :

```powershell
git remote add origin https://github.com/TON_COMPTE/nutriai.git
git push -u origin main
```

Ces commandes sont à exécuter lorsqu’on souhaite effectivement publier. Aucun compte GitHub, jeton ou dépôt distant n’est préconfiguré. Le README et le modèle sont envoyés avec le code ; aucune clé Groq n’est requise pour la publication ou la CI.

Le `.gitignore` exclut les secrets courants, les données et les fichiers générés. `scripts/check_publication.py` contrôle les fichiers suivis et ceux que Git pourrait ajouter : formats de clés reconnus, identifiants littéraux, configuration privée, chemins personnels, sorties de notebooks et fichiers ≥ 100 Mio. Il vérifie aussi les versions déjà placées dans l’index Git, même si le fichier local a ensuite été nettoyé. Ce contrôle complète une revue humaine ; il ne reconnaît pas tous les secrets possibles. Ne jamais forcer l’ajout d’un `.env`. Si une clé a déjà été partagée ailleurs, la révoquer auprès de son fournisseur : supprimer un fichier ne révoque pas une clé.

## Limites et licence

- Le livrable est un **dépôt prêt à publier**, pas un service déjà hébergé. GitHub Pages ne peut pas exécuter les services Python.
- Android et les cibles de bureau constituent les parcours de lancement documentés. Les sources web sont conservées, mais plusieurs flux utilisent `dart:io` et `File` : une adaptation est nécessaire pour garantir une application web fonctionnelle.
- iOS et macOS nécessitent une validation sur un Mac. Les déclarations de permissions caméra/photos iOS sont incluses ; les réglages réseau et la signature restent à adapter à la distribution choisie.
- Le projet Android conserve l’identifiant d’exemple `com.example.nutriai` et la signature de développement. Préparer une identité et une signature propres avant publication sur un magasin.
- Les services utilisent une configuration de démonstration, sans authentification applicative et avec CORS permissif. Avant exposition publique, prévoir authentification, HTTPS, contrôle des origines, limites de requêtes et journalisation adaptée. Les messages et photos sont des données utilisateur ; les requêtes du chatbot peuvent être envoyées à Groq.
- Les estimations alimentaires et objectifs sont ceux d’un prototype académique ; ils ne constituent pas une mesure nutritionnelle ou un avis médical validé.
- Aucune licence de redistribution n’a été ajoutée automatiquement. Les droits du code, du checkpoint et des données doivent être clarifiés par leurs auteurs avant réutilisation ou redistribution par des tiers. Les dépendances et jeux de données conservent leurs conditions propres.
