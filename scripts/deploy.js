const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  const isAmoy = hre.network.name === "amoy";

  const treasuryWallet = "0xaA4B354481a5a95A5378c0d1076D472de4061A17";
  const initialOwner = "0x846D4e6BA2F39111b23f01eB310fb638A8677d00";

  console.log("📤 Deploying contracts with account:", deployer.address);
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("💰 Account balance:", hre.ethers.formatEther(balance), "POL");

  // Deploy or use existing USDT
  let usdtAddress;
  if (isAmoy) {
    console.log("🚀 Deploying MockUSDT...");
    const MockUSDT = await hre.ethers.getContractFactory("MockUSDT");
    const usdt = await MockUSDT.deploy(deployer.address);
    await usdt.waitForDeployment();
    usdtAddress = await usdt.getAddress();
    console.log("✅ MockUSDT deployed at:", usdtAddress);
  } else {
    usdtAddress = "0xYourMainnetUSDTAddress"; // Replace with real USDT for mainnet
    console.log("📎 Using existing USDT at:", usdtAddress);
  }

  // Deploy GraceToken
  console.log("🚀 Deploying GraceToken...");
  const GraceToken = await hre.ethers.getContractFactory("GraceToken");
  const graceToken = await GraceToken.deploy(deployer.address);
  await graceToken.waitForDeployment();
  const graceTokenAddress = await graceToken.getAddress();
  console.log("✅ GraceToken deployed at:", graceTokenAddress);

  // Deploy GraceDonation
  console.log("🚀 Deploying GraceDonation...");
  const GraceDonation = await hre.ethers.getContractFactory("GraceDonation");
  const graceDonation = await GraceDonation.deploy(
    treasuryWallet,         // treasuryWallet
    graceTokenAddress,      // GRACE token
    usdtAddress,            // USDT token
    initialOwner            // initial owner
  );
  await graceDonation.waitForDeployment();
  const graceDonationAddress = await graceDonation.getAddress();
  console.log("✅ GraceDonation deployed at:", graceDonationAddress);

  // Link donation contract to GraceToken
  console.log("🔗 Setting donation contract in GraceToken...");
  const setTx = await graceToken.setDonationContract(graceDonationAddress);
  await setTx.wait();
  console.log("✅ Donation contract set:", graceDonationAddress);

  // Optional: Verify on PolygonScan
  if (isAmoy) {
    console.log("\n🔍 Verifying contracts on PolygonScan...");
    try {
      await hre.run("verify:verify", {
        address: usdtAddress,
        constructorArguments: [deployer.address],
      });
      await hre.run("verify:verify", {
        address: graceTokenAddress,
        constructorArguments: [deployer.address],
      });
      await hre.run("verify:verify", {
        address: graceDonationAddress,
        constructorArguments: [
          treasuryWallet,
          graceTokenAddress,
          usdtAddress,
          initialOwner,
        ],
      });
      console.log("✅ All contracts verified.");
    } catch (err) {
      console.warn("⚠️ Verification failed:", err.message);
    }
  }

  // Final Output
  console.log("\n📦 Contract Addresses for Frontend:");
  console.log(`export const donationContract = "${graceDonationAddress}";`);
  console.log(`export const usdtContract = "${usdtAddress}";`);
  console.log(`export const graceToken = "${graceTokenAddress}";`);
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exitCode = 1;
});
