# Services FastAPI NutriAI

Voir le [README principal](../../README.md) pour l’installation complète, les exemples de requêtes et les tests.

| Service | Dossier courant pour le lancement | Commande après installation |
| --- | --- | --- |
| Analyse alimentaire | `food_server/` | `python -m uvicorn main:app --host 0.0.0.0 --port 8000` |
| Chat nutritionnel | `chatbot_server/` | `python -m uvicorn main:app --host 0.0.0.0 --port 8001` |

Utiliser l’interpréteur de l’environnement virtuel propre au service (`.venv/Scripts/python.exe` sous Windows, `.venv/bin/python` sous Linux/macOS).

- `GET /health` : état du service et disponibilité de son IA.
- `GET /docs` : documentation interactive.
- `POST /analyze-food` : champ multipart `image`, image valide de 12 Mio maximum.
- `POST /nutrition-chat` : message, historique, objectifs et consommation en JSON.

Le checkpoint est conservé dans `application/modelEFF/`. L’analyse signale `efficientnet_b2` ou `heuristic_fallback` dans `source`.

Copier `chatbot_server/.env.example` vers un `.env` local et renseigner sa propre clé Groq. Aucun identifiant personnel n’est fourni. Le `.env` est ignoré par Git ; ne jamais le forcer dans un commit. Les réponses calculées localement utilisent `source: local_rules`, les réponses distantes `source: groq`.
