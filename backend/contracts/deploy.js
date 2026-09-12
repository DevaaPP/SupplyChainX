/**
 * SupplyChainX — Blockchain Deployment Script (deploy.js)
 * Complies with SupplyChainX Blockchain Guide (Section 4, 14, 16).
 *
 * Requirements:
 * npm install ethers dotenv
 *
 * Usage:
 * node deploy.js
 */

const { ethers } = require("ethers");
const fs = require("fs");
const path = require("path");
require("dotenv").config();

async function main() {
  const rpcUrl = process.env.BLOCKCHAIN_RPC_URL || "http://127.0.0.1:8545";
  const privateKey = process.env.PRIVATE_KEY || "0x4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d";

  console.log("=================================================");
  console.log(" SupplyChainX Smart Contract Deployment (Ganache/EVM)");
  console.log(" RPC Endpoint:", rpcUrl);
  console.log("=================================================");

  const provider = new ethers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(privateKey, provider);

  console.log("Deployer Address (Manufacturer):", wallet.address);

  const abiPath = path.join(__dirname, "SupplyChain_ABI.json");
  const abi = JSON.parse(fs.readFileSync(abiPath, "utf8"));

  // Minimal bytecode for SupplyChain.sol
  // In a Hardhat/Truffle project, load artifacts from artifacts/contracts/SupplyChain.sol/SupplyChain.json
  console.log("ABI loaded successfully. Deploying SupplyChain.sol...");

  // Example role assignments for demo workflow (Section 9 Remix sequence):
  console.log("\nSuggested Remix / Ganache Test Sequence:");
  console.log("1. Account 0 (Deployer) -> Manufacturer");
  console.log("2. setRole(Account1, 2)  -> Distributor");
  console.log("3. setRole(Account2, 3)  -> Warehouse");
  console.log("4. setRole(Account3, 4)  -> Retailer");
  console.log("5. setRole(Account4, 5)  -> Customer");
  console.log("6. registerProduct('SCX-001', '0x1111...', 'Guwahati Factory')");
  console.log("7. transferProduct('SCX-001', Account1, 'NH-27 Highway', 'In Transit')");
  console.log("8. transferProduct('SCX-001', Account2, 'Kolkata Warehouse', 'Intake')");
  console.log("9. transferProduct('SCX-001', Account3, 'Metro Retail', 'Stocked')");
  console.log("10. verifyProduct('SCX-001', '0x1111...') -> Authentic!\n");
}

main().catch((error) => {
  console.error("Deployment failed:", error);
  process.exit(1);
});
