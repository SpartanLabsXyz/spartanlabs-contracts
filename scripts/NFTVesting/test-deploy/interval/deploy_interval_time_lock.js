const { ethers } = require("hardhat");

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
	const maxIntervals = 10;
	const intervalDuration = 100;
	console.log("timestampBefore: ", timestampBefore);

	// Deploying Timelock and send ETH to TimeLock contract
	console.log("\nDeploying TimeLock contract...");

	const timeLock = await ethers.getContractFactory(
		"IntervalVestingNftTimeLock"
	);
	const timeLockInstance = await timeLock.deploy(
		basicNFTInstance.address,
		0,
		nftLocker.address,
		beneficiary.address,
		vestingStartTime,
		maxIntervals,
		intervalDuration,
		{ value: ethers.utils.parseEther("1000") }
	);

	await timeLockInstance.deployed();

	console.log("basicNFT deployed to:", basicNFTInstance.address);
	console.log("timeLockInstance deployed to:", timeLockInstance.address);

	// Check nftLocker Eth Balance
	const ownerBalanceAfter = await ethers.provider.getBalance(nftLocker.address);
	console.log(
		"nftLocker Balance After: ",
		ethers.utils.formatEther(ownerBalanceAfter)
	);

	// check NFT Locked
	const nftLocked = await timeLockInstance.nft();
	console.log("nftLocked: ", nftLocked);

	// Send NFT to timelock contract
	await basicNFTInstance.transferFrom(
		nftLocker.address,
		timeLockInstance.address,
		0 // token id
	);

	// check nftLocker of NFT after transfer to be timelock contract
	const nftOwnerAfterTransfer = await basicNFTInstance.ownerOf(0);
	console.log("nftOwnerAfterTransfer: ", nftOwnerAfterTransfer);

	// Set new timestamp by speeding up time
	await ethers.provider.send("evm_setNextBlockTimestamp", [
		timestampBefore + 1111,
	]);
	await ethers.provider.send("evm_mine"); // Fast forward time

	// Get new timestamp
	const blockNumAfter = await ethers.provider.getBlockNumber();
	const blockAfter = await ethers.provider.getBlock(blockNumAfter);
	const currentTimeStamp = blockAfter.timestamp;
	console.log("currentTimeStamp: ", currentTimeStamp, "\n");

	// Get balance of timelock contract
	const timeLockBalance = await ethers.provider.getBalance(
		timeLockInstance.address
	);
	console.log("timeLockBalance: ", ethers.utils.formatEther(timeLockBalance));

	// Get current discount
	const currentDiscount = await timeLockInstance.getDiscount();
	console.log(
		"currentDiscount: ",
		ethers.utils.formatEther(currentDiscount),
		"\n"
	);

	// release NFT
	console.log(
		"Release Time: ",
		ethers.utils.formatUnits(await timeLockInstance.vestingStartTime(), 18 - 18)
	);

	console.log(
		"Release Time: ",
		ethers.utils.formatUnits(await timeLockInstance.vestingStartTime(), 18 - 18)
	);

	const blockNumBeforeRelease = await ethers.provider.getBlockNumber();
	const blockBeforeRelease = await ethers.provider.getBlock(
		blockNumBeforeRelease
	);
	console.log("Time Before Release:", blockBeforeRelease.timestamp, "\n");

	// Get current discount
	const currentDiscount2 = await timeLockInstance.getDiscount();
	console.log(
		"currentDiscount: ",
		ethers.utils.formatEther(currentDiscount2),
		"\n"
	);

	console.log("Releasing NFT... \n");

	const releaseTx = await timeLockInstance.release(); // failing
	const newNftOwner = await basicNFTInstance.ownerOf(0);
	console.log("newNftOwner: ", newNftOwner); // same as original beneficiary

	// Get the ETH balance of NFT Locker and Beneficiary
	const nftLockerBalanceAfter = await ethers.provider.getBalance(
		nftLocker.address
	);
	const beneficiaryBalanceAfter = await ethers.provider.getBalance(
		beneficiary.address
	);

	console.log(
		"nftLockerBalanceAfter: ",
		ethers.utils.formatEther(nftLockerBalanceAfter)
	);
	console.log(
		"beneficiaryBalanceAfter: ",
		ethers.utils.formatEther(beneficiaryBalanceAfter)
	);

	// // check if {release} function can be called again. Expected failure.
	// const releaseTx2 = await timeLockInstance.release();
	// console.log("releaseTx2: ", releaseTx2);
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
