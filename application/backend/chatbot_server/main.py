from __future__ import annotations

from datetime import datetime, timezone
import logging
import os
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from groq import Groq
from pydantic import BaseModel, ConfigDict, Field, model_validator


load_dotenv(Path(__file__).resolve().parent / ".env")

app = FastAPI(title="NutriAI Chatbot Server", version="2.1.0")
logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")
logger = logging.getLogger("nutriai.chat_server")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict this list in production.
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class Macros(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="ignore")

    calories: float
    protein: float
    fat: float

    @model_validator(mode="before")
    @classmethod
    def normalize_macro_keys(cls, data: Any) -> Any:
        if not isinstance(data, dict):
            return data
        normalized = dict(data)
        key_map = {
            "Calories": "calories",
            "Protein": "protein",
            "Fat": "fat",
        }
        for old_key, new_key in key_map.items():
            if old_key in normalized and new_key not in normalized:
                normalized[new_key] = normalized[old_key]
        return normalized


class ChatHistoryMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="ignore")

    name: str
    msg_history: list[dict | str] = Field(default_factory=list)
    foods: list[str] = Field(default_factory=list)
    meal_summaries: list[str] = Field(default_factory=list)
    new_msg: str
    nutritional_goals: Macros
    current_consumption: Macros

    @model_validator(mode="before")
    @classmethod
    def normalize_payload_keys(cls, data: Any) -> Any:
        if not isinstance(data, dict):
            return data
        normalized = dict(data)
        key_map = {
            "Nutritional goals": "nutritional_goals",
            "Current_consumption": "current_consumption",
            "food": "foods",
            "meals": "meal_summaries",
        }
        for old_key, new_key in key_map.items():
            if old_key in normalized and new_key not in normalized:
                normalized[new_key] = normalized[old_key]
        return normalized


class ChatResponse(BaseModel):
    response: str
    remaining_goals: Macros
    timestamp: str
    source: str
    model: str


class AgentState(BaseModel):
    name: str
    messages: list[str]
    food: list[str]
    meal_summaries: list[str]
    calories_totale: float
    calories: float
    protine_totale: float
    protine: float
    lipide_totale: float
    lipide: float
    user_msg: str


def _utc_timestamp() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _normalize_history(raw_history: list[dict | str]) -> list[ChatHistoryMessage]:
    normalized: list[ChatHistoryMessage] = []
    for item in raw_history:
        if isinstance(item, dict):
            role = str(item.get("role", "user")).strip().lower()
            content = str(item.get("content", "")).strip()
            if content:
                normalized.append(ChatHistoryMessage(role=role, content=content))
            continue

        text = str(item).strip()
        if not text:
            continue
        if ":" in text:
            role, content = text.split(":", 1)
            normalized.append(ChatHistoryMessage(role=role.strip().lower(), content=content.strip()))
        else:
            normalized.append(ChatHistoryMessage(role="user", content=text))
    return normalized


def _normalize_foods(raw_foods: list[str]) -> list[str]:
    seen: set[str] = set()
    normalized: list[str] = []
    for item in raw_foods:
        food = str(item).strip()
        key = food.lower()
        if not food or key in seen:
            continue
        normalized.append(food)
        seen.add(key)
    return normalized


def _history_to_state_messages(history: list[ChatHistoryMessage]) -> list[str]:
    role_map = {
        "assistant": "AI",
        "ai": "AI",
        "bot": "AI",
        "user": "User",
    }
    output: list[str] = []
    for message in history:
        role = role_map.get(message.role, "User")
        output.append(f"{role}: {message.content}")
    return output


def _history_to_llm_messages(history: list[ChatHistoryMessage]) -> list[dict[str, str]]:
    role_map = {
        "assistant": "assistant",
        "ai": "assistant",
        "bot": "assistant",
        "user": "user",
    }
    messages: list[dict[str, str]] = []
    for item in history[-8:]:
        role = role_map.get(item.role, "user")
        messages.append({"role": role, "content": item.content})
    return messages


def _recent_context(history: list[ChatHistoryMessage]) -> str:
    if not history:
        return "No previous conversation."

    role_map = {
        "assistant": "Assistant",
        "ai": "Assistant",
        "bot": "Assistant",
        "user": "User",
    }
    lines: list[str] = []
    for item in history[-4:]:
        role = role_map.get(item.role, "User")
        lines.append(f"{role}: {item.content}")
    return " | ".join(lines)


def _is_follow_up_message(text: str) -> bool:
    lowered = text.strip().lower()
    if not lowered:
        return False

    follow_up_starters = (
        "and ",
        "what about",
        "like what",
        "like ",
        "how about",
        "what else",
        "can you make it",
        "how can i make it",
        "step by step",
        "and protein",
        "and calories",
        "and fat",
        "yes",
        "no",
        "it",
        "that",
        "this",
    )
    word_count = len(lowered.split())
    return word_count <= 5 or any(lowered.startswith(prefix) for prefix in follow_up_starters)


def _timeframe_hint(text: str) -> str:
    lowered = text.lower()
    if "tonight" in lowered:
        return "The user asked about tonight. Stay focused on tonight."
    if "today" in lowered:
        return "The user asked about today. Stay focused on today."
    if "tomorrow" in lowered:
        return "The user asked about tomorrow. Stay focused on tomorrow."
    if "ce soir" in lowered:
        return "L'utilisateur parle de ce soir. Reste sur ce soir."
    if "aujourd" in lowered:
        return "L'utilisateur parle d'aujourd'hui. Reste sur aujourd'hui."
    if "demain" in lowered:
        return "L'utilisateur parle de demain. Reste sur demain."
    return "Keep the time frame exactly aligned with the user's wording."


def _is_french(text: str) -> bool:
    lowered = text.lower()
    french_markers = (
        "bonjour",
        "merci",
        "besoin",
        "sommeil",
        "manger",
        "aujourd",
        "pourquoi",
        "comment",
        "je ",
        "j'",
        "tu ",
        "il me",
        "aide",
        "est ce",
        "qu'est",
        "peux tu",
    )
    return any(marker in lowered for marker in french_markers) or any(
        char in lowered for char in "àâçéèêëîïôûùüÿœ"
    )


def _nutrition_snapshot(state: AgentState) -> str:
    calories_gap = round(state.calories_totale - state.calories)
    protein_gap = round(state.protine_totale - state.protine, 1)
    fat_gap = round(state.lipide_totale - state.lipide, 1)
    return (
        f"Calories: target={state.calories_totale}, consumed={state.calories}, gap={calories_gap}. "
        f"Protein: target={state.protine_totale}, consumed={state.protine}, gap={protein_gap}. "
        f"Fat: target={state.lipide_totale}, consumed={state.lipide}, gap={fat_gap}."
    )


def _decorate_with_emojis(answer: str, user_msg: str) -> str:
    text = answer.strip()
    if not text:
        return text

    question_lower = user_msg.lower()
    answer_lower = answer.lower()
    emojis: list[str] = []

    def add_if_question(match_words: tuple[str, ...], emoji: str) -> None:
        if any(word in question_lower for word in match_words) and emoji not in emojis:
            emojis.append(emoji)

    add_if_question(("sleep", "tired", "sommeil", "dorm"), "\U0001F634")
    add_if_question(("fat", "lipid", "lipide", "gras", "graisse"), "\U0001F951")
    add_if_question(("protein", "proteine", "proteines", "muscle", "snack"), "\U0001F4AA")
    add_if_question(("calorie", "kcal", "meal", "food", "dinner", "eat", "repas", "manger"), "\U0001F37D")

    if any(word in answer_lower for word in ("healthy", "balanced", "equilibre", "goal", "objectif")):
        emojis.append("\u2728")

    if not emojis:
        emojis.append("\U0001F642")

    lead = emojis[0]
    tail = emojis[1] if len(emojis) > 1 else ""
    return f"{lead} {text}{(' ' + tail) if tail else ''}"


def _direct_goal_answer(state: AgentState) -> str | None:
    question = state.user_msg.lower()
    is_french = _is_french(state.user_msg)
    calories_gap = round(state.calories_totale - state.calories)
    protein_gap = round(state.protine_totale - state.protine, 1)
    fat_gap = round(state.lipide_totale - state.lipide, 1)

    if any(keyword in question for keyword in ("fat", "lipid", "lipide", "gras", "graisse")):
        if fat_gap < -0.05:
            return (
                f"Oui, tu es au-dessus de ton objectif de lipides d'environ {abs(fat_gap):g} g aujourd'hui. "
                "Rien de grave, mais pour la suite de la journee des choix plus legers comme des legumes, du yaourt ou une proteine maigre seraient parfaits."
                if is_french
                else f"You're about {abs(fat_gap):g} g over your fat target today, so just a little. "
                "For the rest of the day, a lighter choice like vegetables, yogurt, or lean protein would balance things out nicely."
            )
        if fat_gap > 0.05:
            return (
                f"Non, tu as encore environ {fat_gap:g} g de marge avant ton objectif de lipides. "
                "Si tu veux en ajouter, vise plutot de petites portions de bonnes graisses."
                if is_french
                else f"No, you still have about {fat_gap:g} g left before reaching your fat target. "
                "If you want to add some, small portions of healthier fats would be the nicest option."
            )
        return (
            "Tu es tres proche de ton objectif de lipides aujourd'hui, donc c'est plutot bien equilibre."
            if is_french
            else "You're sitting very close to your fat target today, which is a nice balanced spot."
        )

    if any(keyword in question for keyword in ("protein", "proteine", "proteins", "prot")):
        if protein_gap > 0.05:
            return (
                f"Il te manque encore environ {protein_gap:g} g de proteines aujourd'hui. "
                "Un yaourt grec, des oeufs, du thon ou du poulet seraient des options simples et efficaces."
                if is_french
                else f"You still have about {protein_gap:g} g of protein to go today. "
                "A simple win would be Greek yogurt, eggs, tuna, or chicken."
            )
        if protein_gap < -0.05:
            return (
                f"Tu as deja depasse ton objectif de proteines d'environ {abs(protein_gap):g} g. "
                "Ce n'est pas un souci pour une journee, donc tu peux juste garder la suite un peu plus legere."
                if is_french
                else f"You've already gone about {abs(protein_gap):g} g over your protein target. "
                "That's not a big issue for one day, so keeping the rest a bit lighter would be enough."
            )
        return (
            "Tu es pile sur ton objectif de proteines aujourd'hui, joli rythme."
            if is_french
            else "You're right on your protein target today, which is a great place to be."
        )

    if any(keyword in question for keyword in ("calorie", "kcal")):
        if calories_gap > 0:
            return (
                f"Il te reste encore environ {calories_gap:g} kcal aujourd'hui. "
                "Tu as donc encore de la place pour quelque chose de rassasiant, idealement avec des proteines et un peu de fibres."
                if is_french
                else f"You still have about {calories_gap:g} kcal left today. "
                "So you still have room for something satisfying, ideally with protein and a bit of fiber."
            )
        if calories_gap < 0:
            return (
                f"Tu depasses ton objectif calorique d'environ {abs(calories_gap):g} kcal aujourd'hui. "
                "Pas besoin de stresser, mais pour la suite des choix simples et legers te feront te sentir mieux."
                if is_french
                else f"You're about {abs(calories_gap):g} kcal over your calorie target today. "
                "No stress, but lighter choices for the rest of the day would probably feel best."
            )
        return (
            "Tu es pile sur ton objectif calorique aujourd'hui, bien joue."
            if is_french
            else "You're right on your calorie target today, nice work."
        )

    return None


def _build_agent_state(payload: ChatRequest, history: list[ChatHistoryMessage]) -> AgentState:
    foods = _normalize_foods(payload.foods)
    meal_summaries = [item.strip() for item in payload.meal_summaries if item.strip()]
    return AgentState(
        name=payload.name.strip() or "User",
        messages=_history_to_state_messages(history),
        food=foods,
        meal_summaries=meal_summaries,
        calories_totale=payload.nutritional_goals.calories,
        calories=payload.current_consumption.calories,
        protine_totale=payload.nutritional_goals.protein,
        protine=payload.current_consumption.protein,
        lipide_totale=payload.nutritional_goals.fat,
        lipide=payload.current_consumption.fat,
        user_msg=payload.new_msg.strip(),
    )


class GroqNutritionChatbot:
    def __init__(self) -> None:
        self.model_name = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile")
        self._client: Groq | None = None
        self._load_error: str | None = None

    @property
    def is_ready(self) -> bool:
        return self._client is not None

    @property
    def load_error(self) -> str | None:
        return self._load_error

    def load(self) -> bool:
        if self.is_ready:
            return True

        api_key = os.getenv("GROQ_API_KEY", "").strip()
        if not api_key:
            self._load_error = "GROQ_API_KEY is not configured for the chatbot server."
            logger.warning(self._load_error)
            return False

        self._client = Groq(api_key=api_key)
        self._load_error = None
        logger.info("Groq chatbot client initialized with model=%s", self.model_name)
        return True

    def respond(self, state: AgentState, history: list[ChatHistoryMessage]) -> str:
        if not self.load():
            raise RuntimeError(self._load_error or "Groq client is not available.")

        completion = self._client.chat.completions.create(
            model=self.model_name,
            temperature=0.3,
            max_tokens=320,
            messages=self._build_messages(state, history),
        )

        content = completion.choices[0].message.content
        if not content:
            raise RuntimeError("Groq returned an empty answer.")
        if isinstance(content, str):
            return content.strip()

        return str(content).strip()

    def _build_messages(
        self,
        state: AgentState,
        history: list[ChatHistoryMessage],
    ) -> list[dict[str, str]]:
        foods_line = ", ".join(state.food) if state.food else "No foods logged today yet."
        meals_line = "; ".join(state.meal_summaries) if state.meal_summaries else "No detailed meals logged today yet."
        recent_context = _recent_context(history)
        follow_up_hint = (
            "The latest user message is a follow-up. Continue the same topic instead of starting a new one."
            if _is_follow_up_message(state.user_msg)
            else "Treat the latest user message as a fresh request unless the history clearly continues it."
        )
        timeframe_hint = _timeframe_hint(state.user_msg)
        system_prompt = (
            "You are an AI nutrition assistant that helps the user track and improve their daily diet and nutrition.\n"
            "Sound like a warm, polished, encouraging nutrition coach.\n"
            "Be short, clear, practical, and supportive. Never judge the user.\n"
            "Reply in the same language as the user's latest message when possible.\n"
            "Answer the user's latest question directly first.\n"
            "Stay tightly aligned with the exact question the user asked.\n"
            "Use the nutrition data only to support the answer, not to dominate it.\n"
            "Do not start every reply with the same nutrition summary.\n"
            "Vary the wording across turns.\n"
            "Make the answer feel friendly and attractive, not robotic.\n"
            "Celebrate small wins when they exist.\n"
            "For food suggestions, make them sound appealing and easy to imagine.\n"
            "For recipe or cooking questions, give concrete and useful steps.\n"
            "Do not change today into tomorrow, or tonight into another time, unless the user explicitly asks for that.\n"
            "Do not add exact numbers unless the user asks for them or they are already provided in context.\n"
            "Mention only the most relevant nutrition comparison for the current question, or two at most.\n"
            "If the user asks something slightly outside nutrition, answer briefly and connect it to daily habits or nutrition when helpful.\n"
            "Do not invent foods that were not provided.\n"
            "Return only 2 or 3 short sentences.\n"
            "You may use 1 or 2 emojis max, and only when they feel natural.\n\n"
            f"follow-up guidance: {follow_up_hint}\n"
            f"timeframe guidance: {timeframe_hint}\n"
            f"name: {state.name}\n"
            f"food user ate today: {foods_line}\n"
            f"meal details today: {meals_line}\n"
            f"nutrition snapshot: {_nutrition_snapshot(state)}\n"
            f"recent conversation: {recent_context}\n"
            f"messages: {state.messages}\n"
        )

        messages = [{"role": "system", "content": system_prompt}]
        messages.extend(_history_to_llm_messages(history))
        messages.append({"role": "user", "content": state.user_msg})
        return messages


chatbot = GroqNutritionChatbot()


@app.on_event("startup")
def preload_chatbot() -> None:
    chatbot.load()


@app.get("/health")
def health() -> dict[str, Any]:
    chatbot.load()
    return {
        "status": "ok",
        "llm_ready": chatbot.is_ready,
        "model": chatbot.model_name,
        "load_error": chatbot.load_error,
    }


@app.post("/nutrition-chat", response_model=ChatResponse)
def nutrition_chat(payload: ChatRequest) -> ChatResponse:
    logger.info("Incoming request /nutrition-chat")
    if not payload.new_msg.strip():
        logger.warning("Rejected empty message for user=%s", payload.name)
        raise HTTPException(status_code=400, detail="new_msg must not be empty.")

    normalized_history = _normalize_history(payload.msg_history)
    remaining = Macros(
        calories=max(payload.nutritional_goals.calories - payload.current_consumption.calories, 0),
        protein=max(payload.nutritional_goals.protein - payload.current_consumption.protein, 0),
        fat=max(payload.nutritional_goals.fat - payload.current_consumption.fat, 0),
    )
    state = _build_agent_state(payload, normalized_history)

    logger.info(
        "Chat message received: user=%s foods=%s history_count=%s new_msg=%s",
        payload.name,
        len(state.food),
        len(normalized_history),
        payload.new_msg.strip(),
    )

    answer = _direct_goal_answer(state)
    source = "local_rules" if answer is not None else "groq"
    if answer is None:
        try:
            answer = chatbot.respond(state, normalized_history).strip()
        except Exception as exc:
            logger.exception("Groq chatbot generation failed: %s", exc)
            raise HTTPException(
                status_code=503,
                detail="Chatbot service is unavailable. Verify GROQ_API_KEY and server logs.",
            ) from exc

    answer = _decorate_with_emojis(answer, state.user_msg)

    logger.info(
        "Chat response generated: user=%s remaining_cal=%.0f remaining_protein=%.1f remaining_fat=%.1f",
        payload.name,
        remaining.calories,
        remaining.protein,
        remaining.fat,
    )

    return ChatResponse(
        response=answer,
        remaining_goals=remaining,
        timestamp=_utc_timestamp(),
        source=source,
        model="local_rules" if source == "local_rules" else chatbot.model_name,
    )
