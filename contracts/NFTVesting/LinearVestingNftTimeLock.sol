// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/utils/TokenTimelock.sol)
// SpartanLabs Contracts (NFTVesting)

pragma solidity ^0.8.0;
import "./IERC721.sol";

/**
 * @dev A single NFT holder contract that will allow a beneficiary to extract the
 * NFT after a given vesting start time.
 * After the vesting start time, the discount will start to accumulate for the locker linearly.
 *
 * The developer would have to send ETH to this contract on contract deployement for discount to be applied.
 * The amount of ETH sent to this contract is the total discount that beneficiary will receive.
 *
 * Developers would have to perform the following actions for the locking of NFT:
 * Deploy with Eth sent to contract -> Approve NFT Transfer -> Transfer of NFT to contract
 */
contract LinearVestingNftTimeLock {
    // ERC721 basic token smart contract
    IERC721 private immutable _nft;

    // ERC721 basic token ID of contract being held
    uint256 private immutable _tokenId;

    // address of NFT Locker who would receive the NFT and discount when it is released.
    address private immutable _nftLocker;

    // address of beneficiary that will receive the remaining discount not claimed by the `_nftLocker`.
    address private immutable _beneficiary;

    // timestamp when token release is enabled and when discount starts to vest.
    uint256 private immutable _vestingStartTime;

    // Duration that token will vest
    uint256 private _maxDuration;

    // Events
    event EthReceived(address indexed sender, uint256 amount);

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `vestingStartTime_`. The vesting start time is specified as a Unix timestamp
     * (in seconds).
     *
     *  The discount accumulation during vesting for beneficiary is based off a linear model y = mx
     *  The developer would have to send ETH to this contract on contract deployement for discount to be applied.
     */
    constructor(
        IERC721 nft_,
        uint256 tokenId_,
        address nftLocker_,
        address beneficiary_,
        uint256 vestingStartTime_,
        uint256 maxDuration_
    ) payable {
        require(
            vestingStartTime_ > block.timestamp,
            "BasicNFTTimelock: vesting start time is before current time"
        );

        require(
            address(this).balance > 0,
            "Time:Lock: Eth should be sent to contract before initialization"
        );

        _nft = nft_;
        _tokenId = tokenId_;
        _nftLocker = nftLocker_;
        _beneficiary = beneficiary_;
        _vestingStartTime = vestingStartTime_;
        _maxDuration = maxDuration_;
    }

    /**
     * @dev Returns the smart contract NFT.
     */
    function nft() public view virtual returns (IERC721) {
        return _nft;
    }

    /**
     * @dev Returns the token ID of the NFT being held.
     */
    function tokenId() public view virtual returns (uint256) {
        return _tokenId;
    }

    
    /**
     * @dev Returns the NFT Locker address that will receive the NFT and ETH Discount.
     */
    function nftLocker() public view virtual returns (address) {
        return _nftLocker;
    }

    /**
     * @dev Returns the beneficiary that will receive the remaining ETH Discount.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Returns the time when the NFT are released in seconds since Unix epoch (i.e. Unix timestamp).
     */
    function vestingStartTime() public view virtual returns (uint256) {
        return _vestingStartTime;
    }

    /**
     * @dev Returns the max duration that a token is allowed to vest
     */
    function maxDuration() public view virtual returns (uint256) {
        return _maxDuration;
    }

    /**
     * @dev Returns duration that NFT has been locked and vesting
     */
    function vestedDuration() public view returns (uint256) {
        return block.timestamp - vestingStartTime();
    }

    /**
     * @dev Returns discount accrued in Eth according to duration vested
     *
     * Mutiplies balance with discount ratio for achieved from vesting
     * Discount ratio is the ratio of {vestedDuration} to {maxDuration}
     * Maximum discount ratio is 1.
     */
    function getDiscount() public view returns (uint256) {
        if (block.timestamp < vestingStartTime()) {
            return 0;
        }

        uint256 discount = vestedDuration() * (address(this).balance / maxDuration()); // The reason why the balance is divided by maxDuration is because vestedDuration()/maxDuration() = 0.
        
        // Prevent discount from being greater than balance
        if (discount > address(this).balance) {
            discount = address(this).balance;
        }

        return discount;
    }

    /**
     * @dev Transfers NFT held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time. Sends the discount in Eth to the beneficiary.
     * Reverts if transfer of NFT fails.
     */
    function release() public virtual {
        // Check if current time is after vesting start time
        require(
            block.timestamp >= vestingStartTime(),
            "TimeLock: current time is before vesting start time"
        );

        // Check if the NFT is already released
        require(
            nft().ownerOf(tokenId()) == address(this),
            "TimeLock: no NFT to release for this address"
        );

        uint256 ethDiscount = getDiscount();
        uint256 ethRemaining = address(this).balance - ethDiscount;

        // Sending remaining discount to beneficiary
        (bool beneficiarySent, ) = beneficiary().call{value: ethRemaining}("");
        require(beneficiarySent, "Failed to send Ether");

        // Send discount to NFT Locker
        (bool nftLockerSent, ) = nftLocker().call{value: ethDiscount}("");
        require(nftLockerSent, "Failed to send Ether");

        // Transfer NFT to beneficiary
        nft().safeTransferFrom(address(this), beneficiary(), tokenId());

        // Check if beneficiary has received NFT, if not, revert
        require(
            nft().ownerOf(tokenId()) != address(this),
            "BasicNFTTimelock: NFT still owned by this contract"
        );
    }

    /**
     * @dev Fallback function for eth to be sent to contract on Initialization. Emits EthReceived Event
     */
    receive() external payable {
        emit EthReceived(msg.sender, msg.value);
    }

    /**
     * @dev Fallback function in the event that the contract is called directly.
     */
    fallback() external payable {}
}
