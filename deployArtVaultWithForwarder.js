// Sample deployment script for ArtVault with Gelato ERC2771Context support
// Usage: npx hardhat run deployArtVaultWithForwarder.js --network sepolia

const hre = require("hardhat");

async function main() {
    // Gelato Sepolia trusted forwarder address
    const trustedForwarder = "0x61F2976610970AFeDc1d83229e1E21bdc3D5cbE4";

    // Deploy ArtVault with the trusted forwarder
    const ArtVault = await hre.ethers.getContractFactory("ArtVault");
    const artVault = await ArtVault.deploy(trustedForwarder);
    await artVault.deployed();

    console.log("ArtVault deployed to:", artVault.address);
    console.log("Trusted forwarder:", trustedForwarder);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
}); 