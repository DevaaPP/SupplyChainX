"""
SupplyChainX — RAG knowledge base documents.

Ported from notebooks/04_genai_assistant.ipynb (Step 3).
These are the policy/definition documents that the FAISS retriever
searches over to ground the LLM's response.
"""

from langchain_core.documents import Document

KNOWLEDGE_BASE = [
    Document(
        page_content=(
            "Standard delivery categories (e.g. Electronics, Clothing, Apparel, Home) typically "
            "take around 130 minutes under normal conditions. Grocery orders are handled as "
            "quick-commerce and typically take around 27 minutes. A delivery is considered "
            "delayed if it exceeds the normal-conditions baseline for its category by more than "
            "10 minutes."
        ),
        metadata={"topic": "delivery_time_policy"},
    ),
    Document(
        page_content=(
            "Traffic conditions are recorded as Low, Medium, High, or Jam. Jam conditions "
            "typically add the most time to a delivery, followed by High. Low traffic conditions "
            "are treated as the baseline / normal condition."
        ),
        metadata={"topic": "traffic_definitions"},
    ),
    Document(
        page_content=(
            "Weather conditions are recorded as Sunny, Cloudy, Windy, Fog, Sandstorms, or Stormy. "
            "Sunny weather is treated as the baseline / normal condition. Stormy and Sandstorm "
            "conditions are associated with the largest delivery time increases, since they slow "
            "down rider travel speed and may require more cautious routing."
        ),
        metadata={"topic": "weather_definitions"},
    ),
    Document(
        page_content=(
            "When a delay is caused primarily by Traffic, the recommended customer-facing "
            "explanation is to mention congestion on the route and, where relevant, that the rider "
            "may be rerouted. When a delay is caused primarily by Weather, the recommended "
            "explanation is to mention the specific condition (e.g. heavy rain, storm) and that "
            "rider safety takes priority over speed."
        ),
        metadata={"topic": "mitigation_traffic_weather"},
    ),
    Document(
        page_content=(
            "Agent_Rating reflects a delivery agent's historical performance rating (1.0 to 5.0). "
            "Lower-rated agents are, on average, associated with longer delivery times. This is "
            "reported as a contributing factor only when it meaningfully affects a specific "
            "prediction, not as a general statement about any individual agent."
        ),
        metadata={"topic": "agent_rating_definitions"},
    ),
    Document(
        page_content=(
            "Semi-Urban delivery areas take substantially longer on average than Urban, "
            "Metropolitan, or Other areas, due to longer travel distances and less direct routing. "
            "This is treated as expected variation, not a service failure, when explaining "
            "predictions to customers."
        ),
        metadata={"topic": "area_definitions"},
    ),
    Document(
        page_content=(
            "If a customer's order is flagged as delayed, the assistant should state the expected "
            "delivery time, confirm that it is delayed relative to the normal time for that order "
            "type, and explain the delay using only the specific contributing factors identified "
            "for that order -- not general or speculative reasons."
        ),
        metadata={"topic": "assistant_response_policy"},
    ),
]
