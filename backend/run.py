import uvicorn
import sys
import os

# Add backend directory to sys.path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

if __name__ == "__main__":
    print("=================================================================")
    print(" SupplyChainX Backend Server Starting...")
    print(" OpenAPI Docs available at: http://127.0.0.1:8000/docs")
    print(" API Base URL:              http://127.0.0.1:8000/api/v1")
    print("=================================================================")
    try:
        uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=False)
    except Exception as exc:
        print("[CRITICAL] Server failed to start:", exc)
