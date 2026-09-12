import os
import sys
import pytest
from fastapi.testclient import TestClient

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.main import app
from app.services.blockchain_service import BlockchainService, DEFAULT_ACCOUNTS

client = TestClient(app)

def test_blockchain_status():
    """Verify blockchain status endpoint returns EVM compatibility & contract address."""
    response = client.get("/api/v1/blockchain/status")
    assert response.status_code == 200
    data = response.json()
    assert "network" in data
    assert "node_status" in data
    assert "smart_contract_address" in data
    assert data["evm_compatibility"] == "Solidity ^0.8.20"

def test_blockchain_abi():
    """Verify smart contract ABI is exposed and contains main contract functions."""
    response = client.get("/api/v1/blockchain/abi")
    assert response.status_code == 200
    abi = response.json()
    assert isinstance(abi, list)
    assert len(abi) > 0
    func_names = [item.get("name") for item in abi if item.get("type") == "function"]
    assert "setRole" in func_names
    assert "registerProduct" in func_names
    assert "transferProduct" in func_names
    assert "updateLocation" in func_names
    assert "verifyProduct" in func_names
    assert "getProduct" in func_names
    assert "getProductHistory" in func_names

def test_role_assignment_and_permissions():
    """Verify setRole assigns correct roles and rejects unauthorized callers."""
    # Test valid assignment by manufacturer
    res = BlockchainService.set_role(DEFAULT_ACCOUNTS["distributor"], 2)
    assert res["success"] is True
    assert res["role_id"] == 2

    # Test unauthorized assignment by non-manufacturer
    with pytest.raises(PermissionError):
        BlockchainService.set_role(DEFAULT_ACCOUNTS["retailer"], 4, caller=DEFAULT_ACCOUNTS["customer"])

def test_register_and_transfer_lifecycle():
    """
    Test complete lifecycle from guide (Section 9, 10, 11):
    Register SCX-TEST-99 -> Transfer to Distributor -> Transfer to Warehouse -> Transfer to Retailer.
    """
    pid = "SCX-TEST-99"
    test_hash = "0x1111111111111111111111111111111111111111111111111111111111111111"
    
    # 1. Register
    reg = BlockchainService.register_product(
        product_id=pid,
        product_hash=test_hash,
        initial_location="Guwahati Factory",
        name="Test Sensor Batch 99",
        batch_number="BAT-99"
    )
    assert reg["success"] is True
    assert reg["productId"] == pid
    assert reg["productHash"] == test_hash
    assert "https://supplychainx.app/verify/SCX-TEST-99" == reg["qr_url"]

    # Duplicate registration should fail
    with pytest.raises(ValueError):
        BlockchainService.register_product(product_id=pid, product_hash=test_hash)

    # 2. Transfer: Manufacturer -> Distributor
    t1 = BlockchainService.transfer_product(
        product_id=pid,
        to_address=DEFAULT_ACCOUNTS["distributor"],
        new_location="Highway NH-27 Corridor",
        action="Carrier Picked Up",
        caller=DEFAULT_ACCOUNTS["manufacturer"]
    )
    assert t1["success"] is True
    assert t1["to"] == DEFAULT_ACCOUNTS["distributor"]

    # Unauthorized transfer: Manufacturer no longer owns it
    with pytest.raises(PermissionError):
        BlockchainService.transfer_product(
            product_id=pid,
            to_address=DEFAULT_ACCOUNTS["retailer"],
            new_location="Retail Store",
            caller=DEFAULT_ACCOUNTS["manufacturer"]
        )

    # 3. Transfer: Distributor -> Warehouse
    t2 = BlockchainService.transfer_product(
        product_id=pid,
        to_address=DEFAULT_ACCOUNTS["warehouse"],
        new_location="Kolkata Central Warehouse",
        action="Inbound Warehouse Intake",
        caller=DEFAULT_ACCOUNTS["distributor"]
    )
    assert t2["success"] is True

    # 4. Transfer: Warehouse -> Retailer
    t3 = BlockchainService.transfer_product(
        product_id=pid,
        to_address=DEFAULT_ACCOUNTS["retailer"],
        new_location="Metro Store Shelf",
        action="Stocked for Sale",
        caller=DEFAULT_ACCOUNTS["warehouse"]
    )
    assert t3["success"] is True

    # 5. Verify Product
    v_ok = BlockchainService.verify_product(pid, test_hash)
    assert v_ok["isValid"] is True
    assert v_ok["exists"] is True
    assert v_ok["currentOwner"] == DEFAULT_ACCOUNTS["retailer"]

    # Verify forged hash mismatch
    v_forged = BlockchainService.verify_product(pid, "0x9999999999999999999999999999999999999999999999999999999999999999")
    assert v_forged["isValid"] is False
    assert v_forged["exists"] is True

    # 6. Audit Trail History
    history = BlockchainService.get_product_history(pid)
    assert len(history) == 4  # Genesis + 3 transfers
    assert history[0]["action"] == "Product Registered"
    assert history[-1]["action"] == "Stocked for Sale"

def test_section_15_direct_api_endpoints():
    """
    Test direct REST endpoints specified in Section 15 of guide:
    POST /api/products
    POST /api/products/:id/transfer
    PUT /api/products/:id/location
    GET /api/products/:id
    GET /api/products/:id/history
    GET /api/products/:id/verify
    """
    test_pid = "SCX-API-77"
    
    # 1. POST /api/products
    res = client.post("/api/products", json={
        "product_id": test_pid,
        "name": "Direct API Test Product",
        "batch_number": "BAT-API-77",
        "initial_location": "Guwahati Hub"
    })
    assert res.status_code == 200
    assert res.json()["productId"] == test_pid

    # 2. GET /api/products/:id
    res_get = client.get(f"/api/products/{test_pid}")
    assert res_get.status_code == 200
    assert res_get.json()["productId"] == test_pid

    # 3. PUT /api/products/:id/location
    res_loc = client.put(f"/api/products/{test_pid}/location", json={
        "location": "Transit Waypoint Siliguri",
        "status": "In Transit"
    })
    assert res_loc.status_code == 200
    assert res_loc.json()["newLocation"] == "Transit Waypoint Siliguri"

    # 4. POST /api/products/:id/transfer
    res_tr = client.post(f"/api/products/{test_pid}/transfer", json={
        "to_address": DEFAULT_ACCOUNTS["distributor"],
        "location": "Regional Hub Siliguri",
        "action": "Handover to Distributor"
    })
    assert res_tr.status_code == 200
    assert res_tr.json()["to"] == DEFAULT_ACCOUNTS["distributor"]

    # 5. GET /api/products/:id/history
    res_hist = client.get(f"/api/products/{test_pid}/history")
    assert res_hist.status_code == 200
    assert len(res_hist.json()) >= 3

    # 6. GET /api/products/:id/verify
    res_ver = client.get(f"/api/products/{test_pid}/verify")
    assert res_ver.status_code == 200
    assert res_ver.json()["isValid"] is True
    assert res_ver.json()["exists"] is True

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
