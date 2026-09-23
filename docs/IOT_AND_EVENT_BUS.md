# SupplyChainX — Real-Time IoT Telemetry & Async EventBus Architecture

## 1. Overview
SupplyChainX implements physical container monitoring (GPS, temperature, humidity, shock, battery level) integrated with a decoupled pub/sub `EventBus` architecture.

## 2. IoT Telemetry Telemetry Stream
- **Ingestion Endpoint**: `POST /api/v1/iot/telemetry`
- **Live Stream Endpoint**: `ws://localhost:8000/api/v1/iot/ws/stream/{shipment_id}`
- **Monitored Sensor Metrics**:
  - 📍 **GPS Coordinates**: Latitude, Longitude, Speed (km/h)
  - 🌡️ **Temperature**: Storage thermal reading (°C)
  - 💧 **Humidity**: Relative humidity (%)
  - 📦 **Shock / Vibration**: G-force impact acceleration
  - 🔋 **Battery**: Sensor node power level (%)

## 3. Cold-Chain Thermal Anomaly Detection
- Thresholds: Cold-chain items (e.g. bio-pharmaceuticals, vaccines, perishable food) trigger an automated `TEMPERATURE_ALERT` event if storage temperature exceeds **`8.0°C`**.

## 4. Async EventBus Pub/Sub Consumers
- **Decoupled Consumers**:
  1. `BlockchainConsumer` — Automatically commits critical threshold breaches onto the blockchain ledger.
  2. `MLEngineConsumer` — Re-executes ETA delay risk forecasts upon abnormal sensor readings.
  3. `AIAgentConsumer` — Updates GenAI assistant context with real-time incident logs.
  4. `WebSocketConsumer` — Broadcasts live telemetry frames to active frontend dashboard clients.
