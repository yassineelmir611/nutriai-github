# Application NutriAI

La documentation complète se trouve dans le [README principal](../README.md).

Depuis ce dossier, pour essayer l’application sans services ni clé API :

```powershell
flutter pub get --enforce-lockfile
flutter run --dart-define=USE_MOCK_API=true
```

Le mode normal utilise les deux services FastAPI par défaut. Voir le README principal pour installer les environnements Python, configurer les URL et connecter un téléphone.
