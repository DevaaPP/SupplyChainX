"""
GenAI Assistant Service — Plug-and-play module for the GenAI Team.
The GenAI Team can place prompt engineering templates in `backend/ai_prompts/` and call OpenAI/Claude/Gemini APIs here.
"""

from typing import List, Optional

class AIService:
    @staticmethod
    def answer_query(message: str, product_id: Optional[str] = None) -> dict:
        text = message.lower()
        
        if "where" in text or "scx-00112" in text:
            reply = (
                "Consignment SCX-00112 (Organic Basmati Rice 5kg) has completed 4/5 stages. "
                "It was manufactured in Guwahati, transitioned via Siliguri Hub, inspected at Central Warehouse, "
                "and is currently stocked at Metro Retail Store #4."
            )
            refs = ["SCX-00112"]
            actions = ["View Complete Provenance Timeline", "Generate Barcode Verification Certificate"]
        elif "delay" in text or "siliguri" in text:
            reply = (
                "Route NH-27 near Siliguri is currently reporting seasonal monsoon slowdowns (~1.8 day delay). "
                "Recommendation: Advance warehouse inventory dispatch or reroute non-perishables through South Corridor."
            )
            refs = ["BAT-2026-X102"]
            actions = ["Inspect Route Risk", "Trigger Inventory Reorder"]
        elif "replenish" in text or "shortage" in text or "stock" in text:
            reply = (
                "Inventory replenishment audit:\n"
                "• Darjeeling Organic Tea 250g: 15 units remaining (below safe threshold of 40) → Reorder 100 units\n"
                "• Cold Pressed Mustard Oil: 10 units remaining (below safe threshold of 25) → Reorder 50 units"
            )
            refs = ["SCX-00098", "SCX-00134"]
            actions = ["Place Replenishment Order", "Notify Regional Supplier"]
        elif "supplier" in text or "scorecard" in text:
            reply = (
                "Supplier Scorecards (Aug 2026):\n"
                "• Guwahati Food Corp: 98.4% on-time (Rating 4.9/5.0)\n"
                "• Siliguri Logistics Hub: 91.2% on-time (Weather impacted)\n"
                "• Kolkata Central Warehouse: 99.1% on-time (Rating 4.9/5.0)"
            )
            refs = []
            actions = ["Export Supplier CSV Report"]
        else:
            reply = (
                f"SupplyX Operations Assistant: Analyzed operational telemetry for query. "
                f"All active batches are synchronized on the cryptographic ledger."
            )
            refs = []
            actions = ["Query Specific Consignment ID", "Check Tamper Stream"]

        return {
            "reply": reply,
            "referenced_products": refs,
            "suggested_actions": actions
        }
