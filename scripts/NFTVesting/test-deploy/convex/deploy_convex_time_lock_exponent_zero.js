const { ethers } = require("hardhat");
const { expect } = require("chai");

// Test script for deploying the contract

async function main() {
	// Local Blockchain Deployment
	const [nftLocker, beneficiary] = await ethers.getSigners();
	const nftLockerBalance = await ethers.provider.getBalance(nftLocker.address);
	console.log("nftLocker: ", nftLocker.address);
	console.log(
		"nftLocker Balance: ",
		ethers.utils.formatEther(nftLockerBalance)
	);

	console.log("\nDeploying NFT contract...");

	// Deploying Basic NFT Contract
	const basicNFTContract = await ethers.getContractFactory("BasicNft");
	const basicNFTInstance = await basicNFTContract.deploy("TestNft", "TFT");

	// Minting NFT
	const basicMintTx = await basicNFTInstance.mintNft();
	await basicMintTx.wait(1);

	console.log(
		`Basic NFT index 0 tokenURI: ${await basicNFTInstance.tokenURI(0)}`
	);

	const nftOwner = await basicNFTInstance.ownerOf(0);
	console.log(`nftOwner: ${nftOwner}`);

	// Getting timestamp before deploying the contract
	const blockNumBefore = await ethers.provider.getBlockNumber();
	const blockBefore = await ethers.provider.getBlock(blockNumBefore);
	const timestampBefore = blockBefore.timestamp;
	const vestingStartTime = timestampBefore + 100;
	const growthRate = 1;
	const exponent = 0;
	console.log("timestampBefore: ", timestampBefore);

	// Deploying Timelock and send ETH to TimeLock contract
	console.log("\nDeploying TimeLock contract...");

	const timeLock = await ethers.getContractFactory("ConvexVestingNftTimeLock");

	try {
		const timeLockInstance = await timeLock.deploy(
			basicNFTInstance.address,
			0,
			nftLocker.address,
			beneficiary.address,
			vestingStartTime,
			growthRate,
			exponent,
			{ value: ethers.utils.parseEther("100") }
		);
		await timeLockInstance.deployed();
	} catch (e) {
		expect(e.reason).to.equal(
			"Error: VM Exception while processing transaction: reverted with reason string 'Timelock: exponent should be greater than 0'"
		);
	}
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
