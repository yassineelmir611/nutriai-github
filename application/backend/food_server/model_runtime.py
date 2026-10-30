from __future__ import annotations

from dataclasses import dataclass
from io import BytesIO
import logging
from pathlib import Path
from typing import Any

try:
    import torch
    import torch.nn as nn
    import torchvision
except ImportError:  # pragma: no cover - runtime dependency
    torch = None
    nn = None
    torchvision = None

from PIL import Image


logger = logging.getLogger("nutriai.food_model")

CLASS_NAMES = [
    "apple_pie",
    "assida_zgougou",
    "baby_back_ribs",
    "baklava",
    "bambalouni",
    "beef_carpaccio",
    "beef_tartare",
    "beet_salad",
    "beignets",
    "bibimbap",
    "bread_pudding",
    "breakfast_burrito",
    "brik_oeuf",
    "bruschetta",
    "caesar_salad",
    "cannoli",
    "caprese_salad",
    "carrot_cake",
    "ceviche",
    "chakchouka",
    "chapati_tunisien",
    "cheese_plate",
    "cheesecake",
    "chicken_curry",
    "chicken_quesadilla",
    "chicken_wings",
    "chocolate_cake",
    "chocolate_mousse",
    "chorba",
    "churros",
    "clam_chowder",
    "club_sandwich",
    "couscous",
    "crab_cakes",
    "creme_brulee",
    "croque_madame",
    "cup_cakes",
    "deviled_eggs",
    "donuts",
    "dumplings",
    "edamame",
    "eggs_benedict",
    "escargots",
    "falafel",
    "filet_mignon",
    "fish_and_chips",
    "foie_gras",
    "french_fries",
    "french_onion_soup",
    "french_toast",
    "fricasse_tunisien",
    "fried_calamari",
    "fried_rice",
    "frozen_yogurt",
    "garlic_bread",
    "gnocchi",
    "greek_salad",
    "grilled_cheese_sandwich",
    "grilled_salmon",
    "guacamole",
    "gyoza",
    "hamburger",
    "hot_and_sour_soup",
    "hot_dog",
    "huevos_rancheros",
    "hummus",
    "ice_cream",
    "kaak_warka",
    "kafteji",
    "lablabi",
    "lasagna",
    "lobster_bisque",
    "lobster_roll_sandwich",
    "macaroni_and_cheese",
    "macarons",
    "makroudh",
    "marqa_jelbana",
    "miso_soup",
    "mlawi",
    "mloukhia_tunisienne",
    "mussels",
    "nachos",
    "omelette",
    "onion_rings",
    "oysters",
    "pad_thai",
    "paella",
    "pancakes",
    "panna_cotta",
    "peking_duck",
    "pho",
    "pizza",
    "pork_chop",
    "poutine",
    "prime_rib",
    "pulled_pork_sandwich",
    "ramen",
    "ravioli",
    "red_velvet_cake",
    "risotto",
    "rouz_jerbi",
    "salade_mechouia",
    "samosa",
    "sashimi",
    "scallops",
    "seaweed_salad",
    "shrimp_and_grits",
    "spaghetti_bolognese",
    "spaghetti_carbonara",
    "spring_rolls",
    "steak",
    "strawberry_shortcake",
    "sushi",
    "tacos",
    "tajine_tunisien",
    "takoyaki",
    "tiramisu",
    "tuna_tartare",
    "waffles",
]

NUM_CLASSES = len(CLASS_NAMES)


@dataclass(frozen=True)
class NutritionEstimate:
    calories: float
    protein: float
    fat: float
    carbs: float
    fiber: float
    sugar: float
    sodium: float


@dataclass(frozen=True)
class VitaminEstimate:
    vitamin_a: float
    vitamin_c: float
    vitamin_d: float
    vitamin_b12: float


@dataclass(frozen=True)
class PredictionCandidate:
    label: str
    display_name: str
    confidence: float


@dataclass(frozen=True)
class FoodPrediction:
    raw_label: str
    display_name: str
    confidence: float
    nutrition: NutritionEstimate
    vitamins: VitaminEstimate
    top_predictions: list[PredictionCandidate]


def _n(
    calories: float,
    protein: float,
    fat: float,
    carbs: float,
    fiber: float,
    sugar: float,
    sodium: float,
) -> NutritionEstimate:
    return NutritionEstimate(calories, protein, fat, carbs, fiber, sugar, sodium)


NUTRITION_OVERRIDES: dict[str, NutritionEstimate] = {
    "pizza": _n(266, 11.0, 10.0, 33.0, 2.3, 3.8, 598),
    "hamburger": _n(295, 17.0, 14.0, 29.0, 1.5, 5.1, 480),
    "couscous": _n(156, 5.1, 3.8, 25.1, 2.2, 1.9, 170),
    "assida_zgougou": _n(245, 5.0, 10.0, 34.0, 2.1, 18.0, 65),
    "bambalouni": _n(330, 6.0, 16.0, 42.0, 1.6, 9.0, 260),
    "brik_oeuf": _n(240, 10.0, 14.0, 17.0, 1.5, 0.8, 420),
    "chakchouka": _n(110, 4.2, 6.5, 8.3, 2.4, 4.1, 260),
    "chapati_tunisien": _n(310, 9.0, 9.0, 49.0, 2.2, 2.1, 370),
    "chorba": _n(68, 4.2, 2.1, 8.6, 1.5, 1.1, 240),
    "fricasse_tunisien": _n(290, 8.0, 16.0, 31.0, 2.1, 3.3, 450),
    "kaak_warka": _n(410, 8.0, 19.0, 54.0, 1.6, 26.0, 120),
    "kafteji": _n(145, 3.0, 9.0, 13.5, 3.3, 3.0, 220),
    "lablabi": _n(92, 4.6, 2.3, 13.2, 3.8, 1.2, 310),
    "makroudh": _n(360, 4.5, 14.0, 54.0, 2.5, 24.0, 150),
    "marqa_jelbana": _n(118, 7.2, 5.0, 11.0, 3.8, 3.4, 240),
    "mlawi": _n(323, 8.0, 10.0, 49.0, 2.4, 2.1, 390),
    "mloukhia_tunisienne": _n(130, 7.5, 8.0, 8.0, 4.2, 1.0, 290),
    "rouz_jerbi": _n(180, 6.0, 5.0, 28.0, 2.0, 1.5, 260),
    "salade_mechouia": _n(96, 2.1, 6.7, 8.1, 2.9, 4.0, 200),
    "tajine_tunisien": _n(220, 14.0, 12.0, 14.0, 1.1, 1.9, 360),
    "sushi": _n(143, 6.0, 0.6, 30.0, 0.8, 4.2, 340),
    "tacos": _n(226, 9.0, 12.0, 20.0, 2.1, 1.9, 350),
    "lasagna": _n(163, 9.0, 8.0, 14.0, 1.4, 2.2, 330),
    "spaghetti_bolognese": _n(154, 8.2, 5.7, 18.6, 1.9, 2.6, 280),
    "spaghetti_carbonara": _n(191, 7.5, 8.1, 21.3, 1.2, 1.6, 320),
    "paella": _n(158, 8.8, 4.6, 19.5, 1.1, 1.2, 330),
    "pad_thai": _n(180, 8.9, 6.8, 21.0, 1.7, 4.5, 420),
    "ramen": _n(132, 5.5, 4.7, 17.3, 1.2, 1.7, 460),
    "pho": _n(90, 6.3, 2.1, 10.4, 0.8, 1.6, 390),
    "risotto": _n(166, 4.2, 5.7, 23.7, 0.8, 1.2, 280),
    "pancakes": _n(227, 6.4, 9.7, 28.3, 1.0, 7.6, 439),
    "waffles": _n(291, 7.9, 14.1, 32.5, 1.2, 9.3, 511),
    "french_toast": _n(229, 7.8, 11.4, 23.8, 0.9, 7.2, 337),
    "grilled_salmon": _n(206, 22.1, 12.4, 0.0, 0.0, 0.0, 59),
    "steak": _n(271, 25.0, 19.0, 0.0, 0.0, 0.0, 58),
    "pork_chop": _n(231, 24.5, 14.0, 0.0, 0.0, 0.0, 67),
}

SALAD_KEYWORDS = {
    "salad",
    "guacamole",
    "caprese",
    "bruschetta",
    "edamame",
    "hummus",
}
SOUP_KEYWORDS = {
    "soup",
    "chowder",
    "bisque",
    "chorba",
    "pho",
    "ramen",
    "lablabi",
}
SEAFOOD_KEYWORDS = {
    "salmon",
    "calamari",
    "sashimi",
    "scallops",
    "mussels",
    "oysters",
    "tuna",
    "ceviche",
    "lobster",
    "crab",
    "shrimp",
}
MEAT_KEYWORDS = {
    "beef",
    "steak",
    "ribs",
    "pork",
    "duck",
    "filet",
    "foie_gras",
    "prime_rib",
}
SANDWICH_KEYWORDS = {
    "sandwich",
    "hamburger",
    "burger",
    "hot_dog",
    "burrito",
    "quesadilla",
    "croque",
}
PASTA_RICE_KEYWORDS = {
    "pizza",
    "lasagna",
    "gnocchi",
    "risotto",
    "ravioli",
    "paella",
    "rice",
    "pad_thai",
    "fried_rice",
    "spaghetti",
    "ramen",
    "pho",
    "couscous",
    "macaroni",
    "poutine",
}
FRIED_SNACK_KEYWORDS = {
    "fries",
    "wings",
    "onion_rings",
    "falafel",
    "takoyaki",
    "samosa",
    "spring_rolls",
    "dumplings",
    "gyoza",
}
DESSERT_KEYWORDS = {
    "cake",
    "pie",
    "baklava",
    "beignets",
    "brownie",
    "cannoli",
    "cheesecake",
    "chocolate",
    "churros",
    "creme_brulee",
    "cup_cakes",
    "donuts",
    "frozen_yogurt",
    "ice_cream",
    "macarons",
    "makroudh",
    "mousse",
    "panna_cotta",
    "shortcake",
    "tiramisu",
    "waffles",
    "pancakes",
    "apple_pie",
}
BREAKFAST_KEYWORDS = {
    "egg",
    "omelette",
    "french_toast",
    "waffles",
    "pancakes",
    "huevos",
}


def _humanize_label(label: str) -> str:
    return label.replace("_", " ").title()


def _estimate_nutrition(label: str) -> NutritionEstimate:
    if label in NUTRITION_OVERRIDES:
        return NUTRITION_OVERRIDES[label]

    lowered = label.lower()
    if any(keyword in lowered for keyword in SALAD_KEYWORDS):
        return _n(105, 3.0, 7.0, 8.0, 2.8, 3.8, 180)
    if any(keyword in lowered for keyword in SOUP_KEYWORDS):
        return _n(82, 4.8, 2.8, 9.8, 1.7, 1.5, 310)
    if any(keyword in lowered for keyword in SEAFOOD_KEYWORDS):
        return _n(148, 18.0, 6.1, 6.0, 0.6, 1.0, 290)
    if any(keyword in lowered for keyword in MEAT_KEYWORDS):
        return _n(238, 24.0, 14.0, 2.0, 0.2, 0.6, 210)
    if any(keyword in lowered for keyword in SANDWICH_KEYWORDS):
        return _n(265, 12.0, 12.0, 27.0, 1.8, 3.0, 430)
    if any(keyword in lowered for keyword in PASTA_RICE_KEYWORDS):
        return _n(172, 6.9, 5.8, 22.8, 1.6, 1.8, 290)
    if any(keyword in lowered for keyword in FRIED_SNACK_KEYWORDS):
        return _n(287, 9.0, 16.0, 26.0, 2.1, 2.2, 420)
    if any(keyword in lowered for keyword in DESSERT_KEYWORDS):
        return _n(332, 4.8, 15.5, 43.0, 1.4, 24.0, 170)
    if any(keyword in lowered for keyword in BREAKFAST_KEYWORDS):
        return _n(186, 10.5, 10.8, 12.8, 1.1, 2.4, 260)

    return _n(178, 8.2, 7.4, 20.6, 1.8, 2.6, 260)


def _estimate_vitamins(label: str) -> VitaminEstimate:
    lowered = label.lower()
    if any(keyword in lowered for keyword in SALAD_KEYWORDS):
        return VitaminEstimate(0.34, 0.24, 0.01, 0.03)
    if any(keyword in lowered for keyword in SEAFOOD_KEYWORDS):
        return VitaminEstimate(0.06, 0.02, 0.18, 0.52)
    if any(keyword in lowered for keyword in SOUP_KEYWORDS):
        return VitaminEstimate(0.11, 0.05, 0.02, 0.08)
    if any(keyword in lowered for keyword in DESSERT_KEYWORDS):
        return VitaminEstimate(0.07, 0.01, 0.03, 0.05)
    if any(keyword in lowered for keyword in MEAT_KEYWORDS | BREAKFAST_KEYWORDS):
        return VitaminEstimate(0.06, 0.01, 0.05, 0.38)
    if label in {"lablabi", "falafel", "hummus", "edamame"}:
        return VitaminEstimate(0.08, 0.03, 0.0, 0.0)
    return VitaminEstimate(0.10, 0.04, 0.03, 0.11)


class FoodModelRuntime:
    def __init__(self, model_dir: Path | None = None) -> None:
        self._root_dir = model_dir or Path(__file__).resolve().parents[2] / "modelEFF"
        self._model_path: Path | None = None
        self._device: Any = None
        self._model: Any = None
        self._transforms: Any = None
        self._load_error: str | None = None

    @property
    def is_loaded(self) -> bool:
        return self._model is not None and self._transforms is not None

    @property
    def load_error(self) -> str | None:
        return self._load_error

    @property
    def model_path(self) -> str | None:
        return None if self._model_path is None else str(self._model_path)

    def load(self) -> bool:
        if self.is_loaded:
            return True

        if torch is None or torchvision is None or nn is None:
            self._load_error = "torch/torchvision are not installed in the food server environment."
            raise RuntimeError(self._load_error)

        self._model_path = self._find_model_path()
        self._device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        weights = torchvision.models.EfficientNet_B2_Weights.DEFAULT
        self._transforms = weights.transforms()

        model = torchvision.models.efficientnet_b2(weights=None)
        model.classifier = nn.Sequential(
            nn.Dropout(p=0.3, inplace=True),
            nn.Linear(1408, NUM_CLASSES),
        )

        raw_state = self._load_checkpoint()
        state_dict = self._extract_state_dict(raw_state)
        model.load_state_dict(state_dict, strict=True)
        model.to(self._device)
        model.eval()

        self._model = model
        self._load_error = None
        logger.info(
            "Food model loaded successfully from %s on device %s",
            self._model_path,
            self._device,
        )
        return True

    def predict(self, image_bytes: bytes) -> FoodPrediction:
        if not self.is_loaded:
            self.load()

        with Image.open(BytesIO(image_bytes)) as image:
            tensor = self._transforms(image.convert("RGB")).unsqueeze(0).to(self._device)

        with torch.inference_mode():
            logits = self._model(tensor)
            probabilities = torch.softmax(logits, dim=1)[0]
            top_count = min(3, probabilities.shape[0])
            confidences, indices = torch.topk(probabilities, k=top_count)

        top_predictions = [
            PredictionCandidate(
                label=CLASS_NAMES[index.item()],
                display_name=_humanize_label(CLASS_NAMES[index.item()]),
                confidence=round(confidence.item(), 4),
            )
            for confidence, index in zip(confidences, indices)
        ]

        best_label = top_predictions[0].label
        return self.build_prediction(
            label=best_label,
            confidence=top_predictions[0].confidence,
            top_predictions=top_predictions,
        )

    def build_prediction(
        self,
        label: str,
        confidence: float,
        top_predictions: list[PredictionCandidate] | None = None,
    ) -> FoodPrediction:
        nutrition = _estimate_nutrition(label)
        vitamins = _estimate_vitamins(label)
        return FoodPrediction(
            raw_label=label,
            display_name=_humanize_label(label),
            confidence=round(confidence, 4),
            nutrition=nutrition,
            vitamins=vitamins,
            top_predictions=top_predictions or [],
        )

    def _find_model_path(self) -> Path:
        if not self._root_dir.exists():
            raise FileNotFoundError(f"Model directory not found: {self._root_dir}")

        model_paths = sorted(
            list(self._root_dir.glob("*.pth")) + list(self._root_dir.glob("*.pt"))
        )
        if not model_paths:
            raise FileNotFoundError(f"No .pth or .pt model file found in {self._root_dir}")

        return model_paths[0]

    def _load_checkpoint(self) -> Any:
        return torch.load(
            self._model_path,
            map_location=self._device,
            weights_only=True,
        )

    def _extract_state_dict(self, raw_state: Any) -> dict[str, Any]:
        if isinstance(raw_state, dict):
            for candidate_key in ("state_dict", "model_state_dict", "model"):
                nested = raw_state.get(candidate_key)
                if isinstance(nested, dict):
                    raw_state = nested
                    break

        if not isinstance(raw_state, dict):
            raise RuntimeError("Unsupported model checkpoint format.")

        normalized: dict[str, Any] = {}
        for key, value in raw_state.items():
            normalized_key = key[7:] if key.startswith("module.") else key
            normalized[normalized_key] = value
        return normalized
