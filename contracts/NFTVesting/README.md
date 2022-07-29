# NFT Smart Contract Vesting

- These set of contracts is based on the [article]() # TBD



### Setup

### Dependencies
- Hardhat


### Commands to Deploy
For testing of the contracts, you can refer to `scripts/NFTVesting/test-deploy`.

1. Start local chain with `npx hardhat node`
2. Run the deploy script with
  - Basic Time Lock : `	npx hardhat run --network localhost scripts/NFTVesting/deploy_basic_time_lock.js`
- Linear Vesting Time Lock ` npx hardhat run --network localhost scripts/NFTVesting/deploy_linear_time_lock.js`
- Interval Vesting Time Lock ` npx hardhat run --network localhost scripts/NFTVesting/deploy_interval_time_lock.js`
- Convex Vesting Time Lock ` npx hardhat run --network localhost scripts/NFTVesting/deploy_convex_time_lock.js` with exponent 2

The Makefile also contains commands for contract deployment.

For test deployment of different cases:

Interval Vesting Time Lock:
- Maximum number of vesting periods: `npx hardhat run --network localhost scripts/NFTVesting/deploy_interval_time_lock_release_max.js`

Linear Vesting Time Lock:
- Maximum amount of vesting periods: `npx hardhat run --network localhost scripts/NFTVesting/deploy_linear_time_lock_release_max.js`

Convex Vesting Time Lock:
- Maximum amount of vesting periods: `npx hardhat run --network localhost scripts/NFTVesting/deploy_convex_time_lock_release_max.js`
- Exponent = 0 `npx hardhat run --network localhost scripts/NFTVesting/deploy_convex_time_lock_exponent_zero.js`
- Exponent = 1 `npx hardhat run --network localhost scripts/NFTVesting/deploy_convex_time_lock_exponent_one.js`
