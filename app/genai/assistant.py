"""
SupplyChainX — RAG-powered AI Supply Chain Assistant.

Stack: LangChain + Google Gemini (LLM) + HuggingFace (local embeddings) + FAISS.

Architecture:
    User question
        → predict_delivery() → prediction + SHAP reasons
        → FAISS retriever     → relevant policy docs
        → Grounded prompt     → LLM (Google Gemini API)
        → Natural-language answer
"""

import logging
from fastapi import HTTPException
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_community.vectorstores import FAISS
from app.config import GOOGLE_API_KEY, GEMINI_MODEL, HF_EMBEDDING_MODEL
from app.genai.knowledge import KNOWLEDGE_BASE
from app.genai.prompts import ASSISTANT_PROMPT
from app.ml.predictor import predict_delivery
from app.ml.explainer import explain_prediction
import pandas as pd

logger = logging.getLogger(__name__)

# ── Build embeddings + vector store (one-time at startup) ────────────
# Embeddings run LOCALLY — no API call needed.
logger.info("Loading embedding model: %s", HF_EMBEDDING_MODEL)
_embeddings = HuggingFaceEmbeddings(model_name=HF_EMBEDDING_MODEL)
_vector_store = FAISS.from_documents(KNOWLEDGE_BASE, _embeddings)
_retriever = _vector_store.as_retriever(search_kwargs={"k": 2})
logger.info("FAISS vector store built with %d documents", len(KNOWLEDGE_BASE))

import time
import re

# Models to attempt in order if a 429 rate limit or capacity spike is hit
FALLBACK_MODELS = [
    GEMINI_MODEL,
    "gemini-3.5-flash",
    "gemini-flash-latest",
    "gemini-3.1-flash-lite",
]

def _invoke_with_retry_and_fallback(prompt: str):
    """Invoke Gemini with automatic fallback models and rate-limit backoff."""
    last_error = None

    for model_name in FALLBACK_MODELS:
        for attempt in range(2):
            try:
                llm = ChatGoogleGenerativeAI(
                    model=model_name,
                    google_api_key=GOOGLE_API_KEY,
                    temperature=0.3,
                    max_output_tokens=1024,
                )
                response = llm.invoke(prompt)
                content = response.content
                if isinstance(content, list):
                    text_parts = []
                    for part in content:
                        if isinstance(part, str):
                            text_parts.append(part)
                        elif isinstance(part, dict) and "text" in part:
                            text_parts.append(part["text"])
                        elif hasattr(part, "text"):
                            text_parts.append(str(part.text))
                        else:
                            text_parts.append(str(part))
                    return "\n".join(text_parts).strip()
                elif isinstance(content, str):
                    return content.strip()
                else:
                    return str(content).strip()

            except Exception as exc:
                err_str = str(exc)
                last_error = exc
                logger.warning("Attempt %d on model %s failed: %s", attempt + 1, model_name, err_str)

                # If rate limited (429 / RESOURCE_EXHAUSTED), wait briefly or switch model
                if "429" in err_str or "RESOURCE_EXHAUSTED" in err_str:
                    time.sleep(1.5 * (attempt + 1))
                    continue
                elif "503" in err_str or "UNAVAILABLE" in err_str:
                    # Model high demand -> switch to next model immediately
                    break
                else:
                    # Non-recoverable error on this model -> try next
                    break

    # If all models and retries exhausted
    logger.error("All Gemini models exhausted: %s", last_error)
    if "429" in str(last_error) or "RESOURCE_EXHAUSTED" in str(last_error):
        raise HTTPException(
            status_code=429,
            detail="Google Gemini free-tier rate limit reached. Please wait ~15-30 seconds before sending your next request.",
        )
    raise HTTPException(
        status_code=502,
        detail=f"Error communicating with AI service: {str(last_error)}",
    )


# ── Helper ───────────────────────────────────────────────────────────
def _format_reasons(reasons: list[dict]) -> str:
    """Format SHAP reasons into a human-readable string for the prompt."""
    if not reasons:
        return "None -- this order is not delayed."
    return "; ".join(
        f"{r['feature']} = {r['value']} (+{r['impact_minutes']} min)"
        for r in reasons
    )


# ── Public API ───────────────────────────────────────────────────────
def ask_assistant(order: dict, question: str) -> dict:
    """
    Full assistant pipeline: predict → explain → retrieve → LLM → answer.

    Parameters
    ----------
    order : dict
        Raw feature columns (same schema as /predict).
    question : str
        Customer's natural-language question.

    Returns
    -------
    dict with keys: answer (str), prediction (dict)
    """
    if not GOOGLE_API_KEY or GOOGLE_API_KEY.strip() in ("", "YOUR_GEMINI_API_KEY_HERE"):
        raise HTTPException(
            status_code=503,
            detail="GenAI service not configured. Please add a valid GOOGLE_API_KEY to your .env file.",
        )

    # Step 1: Get prediction + delay info
    prediction = predict_delivery(order)

    # Step 2: Get SHAP reasons (only if delayed)
    if prediction["is_delayed"]:
        input_df = pd.DataFrame([order])
        reasons = explain_prediction(input_df)
    else:
        reasons = []

    # Step 3: Retrieve relevant policy context
    retrieved_docs = _retriever.invoke(question)
    context = "\n".join(d.page_content for d in retrieved_docs)

    # Step 4: Fill grounded prompt
    prompt = ASSISTANT_PROMPT.format(
        expected_time=prediction["expected_delivery_time_minutes"],
        baseline_time=prediction["baseline_time_minutes"],
        is_delayed=prediction["is_delayed"],
        delay_minutes=prediction["delay_minutes"],
        reasons=_format_reasons(reasons),
        context=context,
        question=question,
    )

    # Step 5: Call LLM with automatic retry & fallback chain
    answer_text = _invoke_with_retry_and_fallback(prompt)

    return {
        "answer": answer_text,
        "prediction": {**prediction, "reasons": reasons},
    }

