const { ethers } = require("hardhat");

// Test script for deploying the contract

async function main() {
	// Local Blockchain Deployment
	const [owner, addr1] = await ethers.getSigners();

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
	console.log(`nftOwner: ${nftOwner.address}`);

	// getting timestamp
	const blockNumBefore = await ethers.provider.getBlockNumber();
	const blockBefore = await ethers.provider.getBlock(blockNumBefore);
	const timestampBefore = blockBefore.timestamp;
	console.log("timestampBefore: ", timestampBefore);

	// Deploying Timelock
	const timeLock = await ethers.getContractFactory("BasicNFTTimelock");
	const timeLockInstance = await timeLock.deploy(
		basicNFTInstance.address,
		0,
		addr1.address,
		timestampBefore + 30
	);

	await timeLockInstance.deployed();

	console.log("basicNFT deployed to:", basicNFTInstance.address);
	console.log("timeLockInstance deployed to:", timeLockInstance.address);

	// check NFT Locked
	const nftLocked = await timeLockInstance.nft();
	console.log("nftLocked: ", nftLocked);

	// Set new timestamp
	await ethers.provider.send("evm_setNextBlockTimestamp", [
		timestampBefore + 300,
	]);
	await ethers.provider.send("evm_mine"); // this one will have 02:00 PM as its timestamp

	// Get new timestamp
	const blockNumAfter = await ethers.provider.getBlockNumber();
	const blockAfter = await ethers.provider.getBlock(blockNumAfter);
	const timestampAfter = blockAfter.timestamp;
	console.log("timestampAfter: ", timestampAfter);


	// release NFT
	const releaseTx = await timeLockInstance.release();
	const newNftOwner = await basicNFTInstance.ownerOf(0);
	console.log("newNftOwner: ", newNftOwner);
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
