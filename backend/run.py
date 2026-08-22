import uvicorn
import sys
import os

# Add backend directory to sys.path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

if __name__ == "__main__":
    print("=================================================================")
    print(" SupplyChainX Backend Server Starting...")
    print(" OpenAPI Docs available at: http://localhost:8000/docs")
    print(" API Base URL:              http://localhost:8000/api/v1")
    print("=================================================================")
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
