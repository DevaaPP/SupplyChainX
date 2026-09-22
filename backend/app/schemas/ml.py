from pydantic import BaseModel, Field
from typing import Optional, List, Dict

class ReasonItem(BaseModel):
    feature: str
    value: Optional[str] = None
    impact_minutes: float

class OrderInput(BaseModel):
    """Input features for delivery time prediction matching training distributions."""
    Agent_Age: int = Field(28, ge=20, le=39, description="Delivery agent's age (trained on 20-39)")
    Agent_Rating: float = Field(4.5, ge=1.0, le=5.0, description="Agent performance rating")
    Distance: float = Field(10.0, ge=1.0, le=25.0, description="Distance in km (haversine, trained on 1.5-21 km)")
    Preparation_Time: float = Field(10.0, ge=5.0, le=15.0, description="Prep time in minutes (trained on 5-15 min)")
    Order_Hour: int = Field(14, ge=0, le=23, description="Hour of order (0-23)")
    Peak_Hour: int = Field(0, ge=0, le=1, description="1 if peak hour, 0 otherwise")
    Is_Weekend: int = Field(0, ge=0, le=1, description="1 if weekend, 0 otherwise")
    Is_Quick_Commerce: int = Field(0, ge=0, le=1, description="1 if Grocery, 0 otherwise")
    Weather: str = Field("Sunny", description="Weather condition (Cloudy, Fog, Sandstorms, Stormy, Sunny, Windy)")
    Traffic: str = Field("Medium", description="Traffic condition (High, Jam, Low, Medium)")
    Vehicle: str = Field("motorcycle", description="Vehicle type (motorcycle, scooter, van)")
    Area: str = Field("Urban", description="Delivery area type (Metropolitian, Other, Semi-Urban, Urban)")
    Category: str = Field("Grocery", description="Product category")
    Time_of_Day: str = Field("Afternoon", description="Time of day bucket (Afternoon, Evening, Morning, Night)")

class DelayPredictionRequest(BaseModel):
    product_id: Optional[str] = None
    origin: str = "Guwahati Manufacturing Unit"
    destination: str = "Siliguri Hub"
    weather_condition: Optional[str] = "Normal"
    carrier_type: Optional[str] = "Road Transit"
    distance_km: Optional[float] = 320.0
    season: Optional[str] = "Monsoon"
    category: Optional[str] = "Food & Agriculture"
    traffic_condition: Optional[str] = "Medium"

class DelayPredictionResponse(BaseModel):
    risk_level: str # Low, Medium, High, Critical
    delay_probability_pct: float
    estimated_delay_hours: float
    risk_factor: str
    recommended_action: str
    model_version: str = "v2.0-rf-shap"
    expected_delivery_time_minutes: Optional[float] = None
    baseline_time_minutes: Optional[float] = None
    is_delayed: Optional[bool] = None
    reasons: Optional[List[ReasonItem]] = []
    shap_percentage_breakdown: Optional[Dict[str, float]] = {}

class PredictionResponse(BaseModel):
    expected_delivery_time_minutes: float
    baseline_time_minutes: float
    is_delayed: bool
    delay_minutes: float
    reasons: List[ReasonItem] = []
    shap_percentage_breakdown: Dict[str, float] = {}

class DemandForecastRequest(BaseModel):
    sku: Optional[str] = Field("BAT-2026-T88", description="Product SKU ID")
    current_stock: Optional[int] = Field(15, ge=0, description="Current stock level")
    daily_sales_rate: Optional[float] = Field(5.0, ge=0.1, description="Average daily units sold")
    lead_time_days: Optional[int] = Field(5, ge=1, description="Supplier replenishment lead time in days")
    safety_stock_target: Optional[int] = Field(10, ge=0, description="Minimum safety stock threshold")

class DemandForecastResponse(BaseModel):
    sku: str
    current_stock: int
    daily_sales_rate: float
    lead_time_days: int
    reorder_point_units: int
    safety_stock: int
    days_of_supply_remaining: float
    is_reorder_required: bool
    recommended_reorder_qty: int
    urgency_level: str # Low, Medium, High, Critical
    forecast_model: str = "Time-Series ROP Engine"

class SupplierRiskRequest(BaseModel):
    supplier_id: Optional[str] = Field("SUP-GUW-01", description="Supplier ID")
    supplier_name: Optional[str] = Field("Guwahati Food Corp", description="Supplier Organization Name")

class SupplierRiskResponse(BaseModel):
    supplier_id: str
    supplier_name: str
    composite_risk_score: float # 0 to 100
    risk_tier: str # Low, Medium, High, Critical
    on_time_delivery_pct: float
    quality_defect_rate_pct: float
    weather_vulnerability_score: float
    total_deliveries_analyzed: int
    risk_summary: str
    compliance_recommendation: str


