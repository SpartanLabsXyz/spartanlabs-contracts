hardhat-deploy-local-basic:
	npx hardhat compile
	npx hardhat run --network localhost scripts/NFTVesting/deploy_basic_time_lock.js
hardhat-chain:
	npx hardhat node
