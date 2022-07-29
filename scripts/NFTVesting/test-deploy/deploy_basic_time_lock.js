const { ethers } = require("hardhat");
const { expect } = require("chai");

// Test script for deploying the contract

async function main() {
	// Local Blockchain Deployment
	const [owner] = await ethers.getSigners();
	console.log("Owner: ", owner.address);

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

	// getting timestamp
	const blockNumBefore = await ethers.provider.getBlockNumber();
	const blockBefore = await ethers.provider.getBlock(blockNumBefore);
	const timestampBefore = blockBefore.timestamp;
	const timestampAfter = timestampBefore + 100;
	console.log("timestampBefore: ", timestampBefore);

	console.log("\nDeploying TimeLock contract...");

	// Deploying Timelock
	const timeLock = await ethers.getContractFactory("BasicNftTimelock");
	const timeLockInstance = await timeLock.deploy(
		basicNFTInstance.address,
		0, // ID of nft
		owner.address,
		timestampAfter
	);

	await timeLockInstance.deployed();

	console.log("basicNFT deployed to:", basicNFTInstance.address);
	console.log("timeLockInstance deployed to:", timeLockInstance.address);

	// check NFT Locked
	const nftLocked = await timeLockInstance.nft();
	console.log("nftLocked: ", nftLocked);

	// Send NFT to timelock contract
	await basicNFTInstance.transferFrom(
		owner.address,
		timeLockInstance.address,
		0 // token id
	);

	// check owner of NFT after transfer to be timelock contract
	const nftOwnerAfterTransfer = await basicNFTInstance.ownerOf(0);
	expect(nftOwnerAfterTransfer).to.equal(timeLockInstance.address); // Owner should be time lock contract

	// Unhappy path to see if it can be released. Should not unlock.
	// Set new timestamp by speeding up time
	await ethers.provider.send("evm_setNextBlockTimestamp", [
		timestampBefore + 50,
	]);

	// try release NFT
	console.log("Releasing NFT prior to release time...");
	try {
		await timeLockInstance.release();
	} catch (e) {
		expect(e.reason).to.equal(
			"Error: VM Exception while processing transaction: reverted with reason string 'BasicNftTimelock: current time is before release time'"
		);
	}

	// Set new timestamp by speeding up time
	await ethers.provider.send("evm_setNextBlockTimestamp", [
		timestampBefore + 3000,
	]);
	await ethers.provider.send("evm_mine");

	// Get new timestamp
	const blockNumAfter = await ethers.provider.getBlockNumber();
	const blockAfter = await ethers.provider.getBlock(blockNumAfter);
	const currentTimeStamp = blockAfter.timestamp;
	console.log("currentTimeStamp: ", currentTimeStamp, "\n");

	// release NFT
	console.log("Releasing NFT...");
	const releaseTx = await timeLockInstance.release();
	const newNftOwner = await basicNFTInstance.ownerOf(0);
	console.log("newNftOwner: ", newNftOwner); // same as original beneficiary
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
