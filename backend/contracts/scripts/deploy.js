const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("=================================================");
  console.log(" Deploying SupplyChainX OpenZeppelin Smart Contract");
  console.log("=================================================");

  const [deployer, distributorAcc, warehouseAcc, retailerAcc] = await hre.ethers.getSigners();

  console.log("Deployer / Admin Address:", deployer.address);

  // Deploy Contract
  const SupplyChainX = await hre.ethers.getContractFactory("SupplyChainX");
  const contract = await SupplyChainX.deploy();
  await contract.waitForDeployment();

  const contractAddress = await contract.getAddress();
  console.log("[OK] SupplyChainX deployed to address:", contractAddress);

  // Grant Roles
  const DISTRIBUTOR_ROLE = hre.ethers.keccak256(hre.ethers.toUtf8Bytes("DISTRIBUTOR_ROLE"));
  const WAREHOUSE_ROLE   = hre.ethers.keccak256(hre.ethers.toUtf8Bytes("WAREHOUSE_ROLE"));
  const RETAILER_ROLE    = hre.ethers.keccak256(hre.ethers.toUtf8Bytes("RETAILER_ROLE"));

  await contract.grantParticipantRole(distributorAcc.address, DISTRIBUTOR_ROLE);
  console.log(" Assigned DISTRIBUTOR_ROLE to:", distributorAcc.address);

  await contract.grantParticipantRole(warehouseAcc.address, WAREHOUSE_ROLE);
  console.log(" Assigned WAREHOUSE_ROLE to:", warehouseAcc.address);

  await contract.grantParticipantRole(retailerAcc.address, RETAILER_ROLE);
  console.log(" Assigned RETAILER_ROLE to:", retailerAcc.address);

  // Save Contract Address
  const addrPath = path.join(__dirname, "../contract_address.txt");
  fs.writeFileSync(addrPath, contractAddress, "utf8");
  console.log(" Saved contract address to:", addrPath);

  // Copy ABI artifact to SupplyChain_ABI.json
  const artifactPath = path.join(__dirname, "../artifacts/contracts/SupplyChainX.sol/SupplyChainX.json");
  if (fs.existsSync(artifactPath)) {
    const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));
    const abiPath = path.join(__dirname, "../SupplyChain_ABI.json");
    fs.writeFileSync(abiPath, JSON.stringify(artifact.abi, null, 2), "utf8");
    console.log(" Exported ABI to:", abiPath);
  }

  console.log("=================================================");
  console.log(" [SUCCESS] Smart Contract Deployment Complete!");
  console.log("=================================================");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
