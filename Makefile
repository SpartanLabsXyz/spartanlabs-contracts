hardhat-local-deploy:
	npx hardhat compile
	npx hardhat run --network localhost scripts/NFTVesting/deploy.js
hardhat-chain:
	npx hardhat node
