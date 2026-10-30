import importlib

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def client(monkeypatch):
    # Disable dotenv before importing the app: tests never read a local API key.
    import dotenv

    monkeypatch.setattr(dotenv, "load_dotenv", lambda *args, **kwargs: False)
    monkeypatch.delenv("GROQ_API_KEY", raising=False)
    main = importlib.import_module("main")
    monkeypatch.setattr(main, "chatbot", main.GroqNutritionChatbot())

    def forbid_network(*args, **kwargs):
        raise AssertionError("Tests must not construct a remote Groq client")

    monkeypatch.setattr(main, "Groq", forbid_network)
    with TestClient(main.app) as session:
        yield session


def payload(message="How much protein do I still need today?"):
    return {
        "name": "Demo",
        "msg_history": ["user:hello", "ai:hello"],
        "new_msg": message,
        "nutritional_goals": {"calories": 2000, "protein": 100, "fat": 70},
        "current_consumption": {"calories": 1000, "protein": 40, "fat": 30},
    }


def test_health_without_key(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["llm_ready"] is False


def test_direct_nutrition_answer_without_key(client):
    response = client.post("/nutrition-chat", json=payload())
    assert response.status_code == 200
    assert response.json()["remaining_goals"]["protein"] == 60
    assert "60" in response.json()["response"]
    assert response.json()["source"] == "local_rules"


def test_legacy_payload_keys(client):
    data = payload()
    data["Nutritional goals"] = data.pop("nutritional_goals")
    data["Current_consumption"] = data.pop("current_consumption")
    response = client.post("/nutrition-chat", json=data)
    assert response.status_code == 200
    assert response.json()["remaining_goals"]["calories"] == 1000


def test_empty_message(client):
    assert client.post("/nutrition-chat", json=payload("  ")).status_code == 400


def test_general_question_without_key(client):
    response = client.post("/nutrition-chat", json=payload("Bonjour, comment vas-tu ?"))
    assert response.status_code == 503


def test_missing_required_data(client):
    assert client.post("/nutrition-chat", json={"new_msg": "hello"}).status_code == 422
