# Vérifications de la version GitHub

Vérifications locales effectuées le **30 octobre 2026**, sous Windows, dans la copie préparée pour GitHub.

## Résultats

| Contrôle | Résultat |
| --- | --- |
| Dépendances Flutter verrouillées | Résolution et téléchargement réussis avec Flutter 3.38.9 / Dart 3.10.8 ; `pubspec.lock` inchangé. Voir la réserve Windows ci-dessous. |
| `flutter analyze --no-pub` | Réussi : aucun problème signalé. |
| `flutter test --no-pub` | Réussi : **2 tests**. |
| URL distinctes + priorité sur `BASE_URL` + démo | Réussi : **1 test supplémentaire** avec paramètres de compilation dédiés. |
| Compatibilité `BASE_URL` pour l’émulateur | Réussi : **1 test supplémentaire** avec `http://10.0.2.2`. |
| Installation Python | Deux environnements virtuels neufs ; installation des exigences de chaque service et des dépendances de test. Python 3.11.9. |
| `python -m pip check` | Réussi pour les deux services : aucune dépendance incohérente. |
| Service alimentaire | **7 tests réussis**, y compris chargement du checkpoint et véritable inférence CPU avec PyTorch 2.5.1+cpu / torchvision 0.20.1+cpu. |
| Entrées alimentaires invalides | Rejet du mauvais type MIME, des fichiers vides, des données corrompues et des images dépassant 12 Mio. |
| Modèle absent | Mode `heuristic_fallback` explicite et état `model_loaded: false` vérifiés. |
| Chatbot | **6 tests réussis**, sans clé : état, calcul local, anciens noms de champs, message vide, données absentes et erreur `503` sur une question distante. |
| Syntaxe Python | Les **15 scripts Python** publiables et les cellules de code des deux notebooks sont analysables. |
| Scripts PowerShell | Syntaxe valide ; arguments Flutter vérifiés avec un substitut local, y compris ports personnalisés et mode démo. |
| Fichiers publiables | 210 fichiers, environ 33 Mo ; contrôle du contenu local et de l’index Git. Cas de contrôle positifs/négatifs vérifiés, y compris un secret synthétique resté dans l’index après nettoyage du fichier local. |
| Clé personnelle d’origine | Recherche exacte dans les fichiers publiables, y compris les binaires : **aucune occurrence**. La valeur n’a pas été affichée. |
| Checkpoint | Copie identique octet par octet à l’original ; empreinte SHA-256 documentée dans le README. |
| Préservation du projet | Aucun changement appliqué au dossier original. Les 174 fichiers repris sans adaptation ont été comparés octet par octet ; les adaptations concernent exclusivement la nouvelle copie. |
| Git | Dépôt local indépendant, branche `main`, aucun dépôt distant configuré. |

Les tests Python utilisent le client ASGI local de FastAPI. Les réponses de chat distantes ne sont pas appelées : le chargement du `.env` et la construction du client Groq sont neutralisés dans les tests. Le test du modèle utilise une image synthétique : il vérifie le fonctionnement technique, pas la précision de classification.

## Réserves connues

- Sur ce poste, `flutter pub get --enforce-lockfile` résout correctement les dépendances puis termine avec l’avertissement **« Building with plugins requires symlink support »**. Le Mode développeur Windows n’a pas été activé automatiquement. L’analyse et les tests ont réussi avec `--no-pub` après cette résolution. Sur un nouveau poste Windows, activer ce mode et relancer la commande complète.
- Les tests Python émettent des avertissements de dépréciation concernant les hooks FastAPI `on_event` et un alias AnyIO utilisé par Starlette. Les tests réussissent ; une modernisation des dépendances pourra être traitée séparément.
- Aucune compilation APK, Windows, iOS, macOS ou web, ni session sur téléphone physique n’a été effectuée. Les autorisations Android/iOS et les scripts ont été préparés, mais le comportement matériel reste à vérifier sur la cible.
- La génération Groq avec un vrai compte n’a pas été testée. Elle dépend d’une clé personnelle, du modèle disponible et du réseau.
- Les notebooks ont été nettoyés et leur syntaxe contrôlée ; aucun téléchargement d’images, entraînement complet ou calcul de métriques n’a été lancé.
- Le workflow GitHub Actions est fourni mais n’a pas encore été exécuté sur GitHub, puisqu’aucun dépôt distant n’a été créé ou alimenté.
- Le contrôle des secrets est une protection complémentaire ; une revue du contenu reste nécessaire pour les futurs ajouts.

## Reproduire les contrôles

Les commandes d’installation et de test figurent dans le [README](README.md). Le workflow [CI](.github/workflows/ci.yml) exécute les mêmes familles de tests sous Linux, avec PyTorch CPU et sans secret à configurer.
