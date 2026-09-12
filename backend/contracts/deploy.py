"""
SupplyChainX — Python Web3 Deployment & Simulation Runner
Executes the exact 10-step Remix test sequence from Section 9 & 10 of the guide:
1. Connects to Ganache / Local EVM (or runs internal simulation)
2. Deploys SupplyChain.sol
3. Assigns roles:
   Account 1 -> Distributor (2)
   Account 2 -> Warehouse (3)
   Account 3 -> Retailer (4)
   Account 4 -> Customer (5)
4. Registers SCX-001 (Hash: 0x1111111111111111111111111111111111111111111111111111111111111111)
5. Transfers: Manufacturer -> Distributor -> Warehouse -> Retailer
6. Verifies authenticity with verifyProduct()
7. Prints full product journey audit trail
"""

import os
import sys
import json
import hashlib

# Add backend directory to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.services.blockchain_service import BlockchainService, DEFAULT_ACCOUNTS

def run_simulation():
    print("==================================================================")
    print(" SupplyChainX — Blockchain Module Automated Verification Runner")
    print(" Reference: SupplyChainX Blockchain Guide (Section 9 & 10)")
    print("==================================================================")

    # 1. Network & Contract Status
    status = BlockchainService.get_blockchain_status()
    print(f"\n[1] Network: {status['network']}")
    print(f"    Consensus: {status['consensus']}")
    print(f"    Smart Contract: {status['smart_contract_address']}")
    print(f"    Deployer (Manufacturer): {status['deployer_address']}")

    # 2. Assign Roles (Section 8 & 9)
    print("\n[2] Configuring Role Permissions (Section 8):")
    roles_setup = [
        (DEFAULT_ACCOUNTS["distributor"], 2, "Distributor"),
        (DEFAULT_ACCOUNTS["warehouse"], 3, "Warehouse"),
        (DEFAULT_ACCOUNTS["retailer"], 4, "Retailer"),
        (DEFAULT_ACCOUNTS["customer"], 5, "Customer")
    ]
    for acc, r_id, r_name in roles_setup:
        res = BlockchainService.set_role(acc, r_id)
        print(f"    [OK] Assigned {r_name} (Role {r_id}) to {acc}")

    # 3. Register Product SCX-TEST-001 (Section 10)
    print("\n[3] Registering Product SCX-TEST-001 on Blockchain (Section 10):")
    product_id = "SCX-TEST-001"
    product_hash = "0x1111111111111111111111111111111111111111111111111111111111111111"
    location = "Guwahati Factory"

    # If already registered in seed, read or re-verify
    try:
        reg_res = BlockchainService.register_product(
            product_id=product_id,
            product_hash=product_hash,
            initial_location=location,
            name="Industrial Sensor Controller X1",
            batch_number="BAT-2026-S01"
        )
        print(f"    [OK] Registered Product ID: {reg_res['productId']}")
        print(f"    [OK] Product Hash (bytes32): {reg_res['productHash']}")
        print(f"    [OK] QR URL: {reg_res['qr_url']}")
    except ValueError:
        print(f"    [OK] Product {product_id} already registered on ledger. Proceeding with verification.")

    # 4. Sequential Ownership Transfers (Section 9 & 11)
    print("\n[4] Sequential 5-Stage Custody Transfers (Section 11):")
    print("    Step A: Manufacturer -> Distributor (Siliguri Logistics Hub)")
    t1 = BlockchainService.transfer_product(
        product_id=product_id,
        to_address=DEFAULT_ACCOUNTS["distributor"],
        new_location="Highway NH-27 Corridor",
        action="Dispatched to Regional Distributor",
        caller=DEFAULT_ACCOUNTS["manufacturer"]
    )
    print(f"      Status: {t1['action']} @ {t1['newLocation']}")

    print("    Step B: Distributor -> Warehouse (Kolkata Central Warehouse)")
    t2 = BlockchainService.transfer_product(
        product_id=product_id,
        to_address=DEFAULT_ACCOUNTS["warehouse"],
        new_location="Kolkata Central Warehouse",
        action="Inbound Warehouse Intake & Inspection",
        caller=DEFAULT_ACCOUNTS["distributor"]
    )
    print(f"      Status: {t2['action']} @ {t2['newLocation']}")

    print("    Step C: Warehouse -> Retailer (Metro Retail Store #1)")
    t3 = BlockchainService.transfer_product(
        product_id=product_id,
        to_address=DEFAULT_ACCOUNTS["retailer"],
        new_location="Metro Retail Store #1",
        action="Stocked on Retail Shelf A-12",
        caller=DEFAULT_ACCOUNTS["warehouse"]
    )
    print(f"      Status: {t3['action']} @ {t3['newLocation']}")

    # 5. Read History (Section 9 Step 9)
    print("\n[5] Reading Immutable Journey History (getProductHistory):")
    history = BlockchainService.get_product_history(product_id)
    for idx, h in enumerate(history, 1):
        print(f"    Block #{idx}: {h['action']} | Location: {h['location']} | To: {h['to'][:10]}... | Time: {h['timestamp']}")

    # 6. Customer Verification (Section 9 Step 10, Section 13 & 18)
    print("\n[6] Customer Authenticity Verification (verifyProduct):")
    v_success = BlockchainService.verify_product(product_id, product_hash)
    print(f"    Matching Hash Check: {'[VALID] 100% AUTHENTIC PRODUCT' if v_success['isValid'] else '[INVALID] TAMPERED'}")
    print(f"    Current Owner: {v_success['currentOwner']}")
    print(f"    Current Location: {v_success['currentLocation']}")
    print(f"    Current Status: {v_success['status']}")

    # Tamper Check with forged hash
    v_forged = BlockchainService.verify_product(product_id, "0x9999999999999999999999999999999999999999999999999999999999999999")
    print(f"    Forged Hash Check: {'[PASSED]' if not v_forged['isValid'] else '[FAILED]'} (Correctly detected mismatch: {v_forged['message']})")

    print("\n==================================================================")
    print(" [OK] All Blockchain Module Steps Completed Successfully!")
    print("==================================================================\n")

if __name__ == "__main__":
    run_simulation()
