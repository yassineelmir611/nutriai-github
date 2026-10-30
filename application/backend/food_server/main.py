from __future__ import annotations

from datetime import datetime, timezone
from io import BytesIO
import logging
from typing import Any

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

try:
    from PIL import Image
except ImportError:  # pragma: no cover - optional runtime dependency
    Image = None

from model_runtime import FoodModelRuntime, PredictionCandidate


app = FastAPI(title="NutriAI Food Analysis Server", version="2.0.0")
logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")
logger = logging.getLogger("nutriai.food_server")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict this list in production.
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class Nutrition(BaseModel):
    calories: float
    protein: float
    fat: float
    carbs: float
    fiber: float
    sugar: float
    sodium: float


class Vitamins(BaseModel):
    vitaminA: float
    vitaminC: float
    vitaminD: float
    vitaminB12: float


class TopPrediction(BaseModel):
    label: str
    display_name: str
    confidence: float
    nutrition: Nutrition
    vitamins: Vitamins


class FoodResponse(BaseModel):
    food_name: str
    nutrition: Nutrition
    vitamins: Vitamins
    confidence: float
    portion_unit: str
    timestamp: str
    raw_label: str | None = None
    source: str = "unknown"
    top_predictions: list[TopPrediction] = Field(default_factory=list)


food_model = FoodModelRuntime()


def _utc_timestamp() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


@app.on_event("startup")
def preload_food_model() -> None:
    try:
        food_model.load()
    except Exception as exc:  # pragma: no cover - runtime branch
        logger.exception("Food model failed to load, server will use fallback mode: %s", exc)


def _serialize_top_predictions(
    candidates: list[PredictionCandidate],
) -> list[TopPrediction]:
    serialized: list[TopPrediction] = []
    for item in candidates:
        prediction = food_model.build_prediction(
            label=item.label,
            confidence=item.confidence,
        )
        serialized.append(
            TopPrediction(
                label=item.label,
                display_name=item.display_name,
                confidence=item.confidence,
                nutrition=Nutrition(
                    calories=prediction.nutrition.calories,
                    protein=prediction.nutrition.protein,
                    fat=prediction.nutrition.fat,
                    carbs=prediction.nutrition.carbs,
                    fiber=prediction.nutrition.fiber,
                    sugar=prediction.nutrition.sugar,
                    sodium=prediction.nutrition.sodium,
                ),
                vitamins=Vitamins(
                    vitaminA=prediction.vitamins.vitamin_a,
                    vitaminC=prediction.vitamins.vitamin_c,
                    vitaminD=prediction.vitamins.vitamin_d,
                    vitaminB12=prediction.vitamins.vitamin_b12,
                ),
            )
        )
    return serialized


def _build_response(prediction: Any, source: str) -> FoodResponse:
    return FoodResponse(
        food_name=prediction.display_name,
        nutrition=Nutrition(
            calories=prediction.nutrition.calories,
            protein=prediction.nutrition.protein,
            fat=prediction.nutrition.fat,
            carbs=prediction.nutrition.carbs,
            fiber=prediction.nutrition.fiber,
            sugar=prediction.nutrition.sugar,
            sodium=prediction.nutrition.sodium,
        ),
        vitamins=Vitamins(
            vitaminA=prediction.vitamins.vitamin_a,
            vitaminC=prediction.vitamins.vitamin_c,
            vitaminD=prediction.vitamins.vitamin_d,
            vitaminB12=prediction.vitamins.vitamin_b12,
        ),
        confidence=prediction.confidence,
        portion_unit="per_100g",
        timestamp=_utc_timestamp(),
        raw_label=prediction.raw_label,
        source=source,
        top_predictions=_serialize_top_predictions(prediction.top_predictions),
    )


def _fallback_label_from_filename(filename: str) -> str | None:
    lowered = filename.lower()
    keyword_map = {
        "pizza": "pizza",
        "salad": "greek_salad",
        "mechouia": "salade_mechouia",
        "chicken": "chicken_curry",
        "burger": "hamburger",
        "sandwich": "club_sandwich",
        "spaghetti": "spaghetti_bolognese",
        "pasta": "spaghetti_carbonara",
        "couscous": "couscous",
        "tajine": "tajine_tunisien",
        "lablabi": "lablabi",
        "sushi": "sushi",
        "ramen": "ramen",
        "tacos": "tacos",
        "brik": "brik_oeuf",
        "kafteji": "kafteji",
        "mloukhia": "mloukhia_tunisienne",
    }

    for keyword, label in keyword_map.items():
        if keyword in lowered:
            return label
    return None


def _fallback_label_from_image(content: bytes) -> str | None:
    if Image is None:
        return None

    try:
        with Image.open(BytesIO(content)) as raw_image:
            image = raw_image.convert("RGB")
            image.thumbnail((96, 96))
            pixels = list(image.getdata())
    except Exception as exc:  # pragma: no cover - defensive runtime branch
        logger.warning("Could not inspect image for fallback mode: %s", exc)
        return None

    if not pixels:
        return None

    pixel_count = len(pixels)
    avg_r = sum(pixel[0] for pixel in pixels) / pixel_count
    avg_g = sum(pixel[1] for pixel in pixels) / pixel_count
    avg_b = sum(pixel[2] for pixel in pixels) / pixel_count
    brightness = (avg_r + avg_g + avg_b) / 3

    logger.info(
        "Fallback image heuristic stats: avg_r=%.1f avg_g=%.1f avg_b=%.1f brightness=%.1f",
        avg_r,
        avg_g,
        avg_b,
        brightness,
    )

    if avg_g > avg_r * 1.08 and avg_g > avg_b * 1.18:
        return "greek_salad"
    if avg_r > avg_g * 1.08 and avg_r > avg_b * 1.38 and brightness > 95:
        return "pizza"
    if avg_r > avg_b * 1.15 and avg_g > avg_b * 1.05 and 95 <= brightness <= 190:
        return "chicken_curry"
    if avg_r > 130 and avg_g > 105 and avg_b < 125:
        return "couscous"

    return "tajine_tunisien"


def _fallback_prediction(filename: str, content: bytes) -> Any:
    label = _fallback_label_from_filename(filename) or _fallback_label_from_image(content) or "pizza"
    return food_model.build_prediction(label=label, confidence=0.55)


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "status": "ok",
        "model_loaded": food_model.is_loaded,
        "model_path": food_model.model_path,
        "load_error": food_model.load_error,
    }


@app.post("/analyze-food", response_model=FoodResponse)
async def analyze_food(image: UploadFile = File(...)) -> FoodResponse:
    logger.info("Incoming request /analyze-food")

    if image.content_type is None or not image.content_type.startswith("image/"):
        logger.warning("Rejected file: filename=%s content_type=%s", image.filename, image.content_type)
        raise HTTPException(status_code=400, detail="Uploaded file must be an image.")

    content = await image.read(12 * 1024 * 1024 + 1)
    if not content:
        logger.warning("Rejected empty image: filename=%s", image.filename)
        raise HTTPException(status_code=400, detail="Uploaded image is empty.")

    if len(content) > 12 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Uploaded image is too large.")

    # Check the actual image even when the model is unavailable. A MIME type or
    # a filename is not sufficient to accept arbitrary bytes as a food photo.
    try:
        with Image.open(BytesIO(content)) as decoded:
            decoded.verify()
    except Exception as exc:
        raise HTTPException(status_code=400, detail="Uploaded file is not a valid image.") from exc

    logger.info(
        "Image received successfully: filename=%s content_type=%s bytes=%s",
        image.filename,
        image.content_type,
        len(content),
    )

    filename = image.filename or "uploaded-image.jpg"

    if food_model.is_loaded:
        try:
            prediction = food_model.predict(content)
            logger.info(
                "Model prediction completed: label=%s confidence=%.3f",
                prediction.raw_label,
                prediction.confidence,
            )
            return _build_response(prediction, source="efficientnet_b2")
        except Exception as exc:  # pragma: no cover - runtime branch
            logger.exception("Model prediction failed, using fallback mode: %s", exc)

    fallback_prediction = _fallback_prediction(filename, content)
    logger.info(
        "Fallback prediction completed: label=%s confidence=%.3f",
        fallback_prediction.raw_label,
        fallback_prediction.confidence,
    )
    return _build_response(fallback_prediction, source="heuristic_fallback")
