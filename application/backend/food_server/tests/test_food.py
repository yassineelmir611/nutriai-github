from io import BytesIO

import pytest
import torch
from fastapi.testclient import TestClient
from PIL import Image

import main
from model_runtime import FoodModelRuntime


@pytest.fixture(scope="module")
def client():
    torch.set_num_threads(2)
    with TestClient(main.app) as session:
        yield session


def image_bytes():
    buffer = BytesIO()
    Image.new("RGB", (64, 64), (180, 100, 60)).save(buffer, format="PNG")
    return buffer.getvalue()


def test_included_model_loads_and_predicts(client):
    health = client.get("/health").json()
    assert health["model_loaded"] is True, health["load_error"]
    response = client.post(
        "/analyze-food", files={"image": ("meal.png", image_bytes(), "image/png")}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["source"] == "efficientnet_b2"
    assert data["portion_unit"] == "per_100g"
    assert 0 <= data["confidence"] <= 1
    assert len(data["top_predictions"]) == 3
    assert data["nutrition"]["calories"] >= 0


@pytest.mark.parametrize(
    "filename,content,mime,status",
    [
        ("file.txt", b"hello", "text/plain", 400),
        ("meal.png", b"", "image/png", 400),
        ("pizza.png", b"not an image", "image/png", 400),
        ("large.png", b"x" * (12 * 1024 * 1024 + 1), "image/png", 413),
    ],
    ids=["wrong-mime", "empty", "corrupt", "too-large"],
)
def test_rejects_invalid_uploads(client, filename, content, mime, status):
    response = client.post("/analyze-food", files={"image": (filename, content, mime)})
    assert response.status_code == status


def test_missing_model_uses_explicit_fallback(tmp_path, monkeypatch):
    monkeypatch.setattr(main, "food_model", FoodModelRuntime(tmp_path))
    with TestClient(main.app) as client:
        assert client.get("/health").json()["model_loaded"] is False
        response = client.post(
            "/analyze-food", files={"image": ("pizza.png", image_bytes(), "image/png")}
        )
    assert response.status_code == 200
    assert response.json()["source"] == "heuristic_fallback"
    assert response.json()["raw_label"] == "pizza"


def test_corrupt_image_is_rejected_even_without_model(tmp_path, monkeypatch):
    monkeypatch.setattr(main, "food_model", FoodModelRuntime(tmp_path))
    with TestClient(main.app) as client:
        response = client.post(
            "/analyze-food", files={"image": ("pizza.png", b"invalid", "image/png")}
        )
    assert response.status_code == 400
