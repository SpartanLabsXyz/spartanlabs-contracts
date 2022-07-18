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
 * Developers would have to perform the following actions for the locking of NFT:
 * Deploy -> Approve -> Transfer
 *
 * Note that in order for discount in ETH to be valid, ETH must first be sent to this contract upon token locking.
 */
contract LinearVestingNFTTimeLock {
    // ERC721 basic token smart contract
    IERC721 private immutable _nft;

    // ERC721 basic token ID of contract being held
    uint256 private immutable _tokenId;

    // beneficiary of token after they are released
    address private immutable _beneficiary;

    // timestamp when token release is enabled and when discount starts to vest. Also known as cliff period.
    uint256 private immutable _vestingStartTime;

    // Max discount allowed for a token in percentage
    uint256 private immutable _maxDiscountPercentage;

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
        address beneficiary_,
        uint256 vestingStartTime_,
        uint256 maxDiscountPercentage_,
        uint256 maxDuration_
    ) {
        require(
            vestingStartTime_ > block.timestamp,
            "BasicNFTTimelock: vesting start time is before current time"
        );
        require(
            maxDiscountPercentage_ <= 100,
            "TimeLock: max discount is greater than 100%. Please use a valid maxDiscountPercentage."
        );
        require(
            address(this).balance > 0,
            "Time:Lock: Eth should be sent to contract before initialization"
        );

        _nft = nft_;
        _tokenId = tokenId_;
        _beneficiary = beneficiary_;
        _vestingStartTime = vestingStartTime_;
        _maxDiscountPercentage = maxDiscountPercentage_;
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
     * @dev Returns the beneficiary that will receive the NFT.
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
     * @dev Returns the max discount allowed for a token in percentage.
     */
    function maxDiscountPercentage() public view virtual returns (uint256) {
        return _maxDiscountPercentage;
    }

    /**
     * @dev Returns duration that NFT has been locked and vesting
     */
    function vestedDuration() public view returns (uint256) {
        return block.timestamp - vestingStartTime();
    }

    /**
     * @dev Returns discount percentage for achieved from vesting
     * Based off: discount = mx
     */
    function getDiscountPercentage() public view returns (uint256) {
        if (block.timestamp < vestingStartTime()) {
            return 0;
        }
        return (maxDiscountPercentage() * vestedDuration()) / maxDuration();
    }

    /**
     * @dev Returns discount accrued in Eth according to duration vested
     */
    function getDiscount() public view returns (uint256) {
        return address(this).balance * getDiscountPercentage();
    }

    /**
     * @dev Transfers NFT held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time. Sends the discount in Eth to the beneficiary.
     */
    function release() public virtual {
        require(
            block.timestamp >= vestingStartTime(),
            "TimeLock: current time is before vesting start time"
        );
        require(
            nft().ownerOf(tokenId()) == address(this),
            "TimeLock: no NFT to release for this address"
        );

        uint256 ethDiscount = getDiscount();
        (bool sent, ) = beneficiary().call{value: ethDiscount}("");
        require(sent, "Failed to send Ether");

        nft().safeTransferFrom(address(this), beneficiary(), tokenId());
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
