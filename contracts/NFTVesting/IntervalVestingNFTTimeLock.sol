// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/utils/TokenTimelock.sol)
// SpartanLabs Contracts (NFTVesting)

pragma solidity ^0.8.0;
import "./IERC721.sol";

/**
 * @dev A single NFT holder contract that will allow a beneficiary to extract the
 * NFT after a given vesting start time with a discount sent to the beneficiary based on
 * the vesting duration of the NFT.
 *
 * On every interval epoch, the discount accrued by the locker is based off a set amount.
 *
 * Note that in order for discount in ETH to be valid, ETH must first be sent to this contract upon token locking.
 */
contract IntervalVestingNFTTimeLock {
    // ERC721 basic token smart contract
    IERC721 private immutable _nft;

    // ERC721 basic token ID of contract being held
    uint256 private immutable _tokenId;

    // beneficiary of token after they are released
    address private immutable _beneficiary;

    // timestamp when token release is enabled
    uint256 private immutable _vestingStartTime;

    // Max discount allowed for a token in percentage
    uint256 private immutable _maxDiscountPercentage;

    // Max number of Interval for vesting
    uint256 private immutable _maxIntervals;

    // Duration for each Interval
    uint256 private immutable _intervalDuration;

    // Discount for every interval passed
    uint256 private immutable _discountPerInterval;

    // Events
    event EthReceived(address indexed sender, uint256 amount);

    modifier validRelease() {
        require(
            block.timestamp >= _vestingStartTime + _intervalDuration,
            "Vesting Schedule is not Up yet."
        );
        _;
    }

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `vestingStartTime_`. The vesting start time is specified as a Unix timestamp
     * (in seconds).
     *
     *  For every set of duration passed after the vesting start time, the number of intervals would increase.
     *  The discount will then be applied to the beneficiary according to number of intervals the token has been vested for.
     *
     *  The developer would have to send ETH to this contract on contract deployement for discount to be applied
     */
    constructor(
        IERC721 nft_,
        uint256 tokenId_,
        address beneficiary_,
        uint256 vestingStartTime_,
        uint256 maxDiscountPercentage_,
        uint256 maxInterval_,
        uint256 intervalDuration_,
        uint256 discountPerInterval_
    ) {
        require(
            vestingStartTime_ > block.timestamp,
            "TimeLock: vesting start time is before current time"
        );
        require(
            maxDiscountPercentage_ <= 100,
            "TimeLock: max discount is greater than 100%. Please use a valid maxDiscountPercentage."
        );
        require(
            discountPerInterval_ * maxInterval_ == maxDiscountPercentage_,
            "TimeLock: discount per interval is not equal to max discount. Please use a valid discountPerInterval."
        );
        require(
            address(this).balance >= discountPerInterval_ * maxInterval_,
            "TimeLock: not enough ETH to pay for discount. Please send more ETH."
        );

        _nft = nft_;
        _tokenId = tokenId_;
        _beneficiary = beneficiary_;
        _vestingStartTime = vestingStartTime_;
        _maxDiscountPercentage = maxDiscountPercentage_;
        _maxIntervals = maxInterval_;
        _intervalDuration = intervalDuration_;
        _discountPerInterval = discountPerInterval_;
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
     * @dev Returns the time when the NFT are released in seconds since Unix Interval (i.e. Unix timestamp).
     */
    function vestingStartTime() public view virtual returns (uint256) {
        return _vestingStartTime;
    }

    /**
     * @dev Returns the max discount allowed for a token in percentage.
     */
    function maxDiscountPercentage() public view virtual returns (uint256) {
        return _maxDiscountPercentage;
    }

    /**
     * @dev Returns discount for locking at each Interval
     */
    function discountPerInterval() public view virtual returns (uint256) {
        return _discountPerInterval;
    }

    function getMaxIntervals() public view virtual returns (uint256) {
        return _maxIntervals;
    }

    function getIntervalDuration() public view virtual returns (uint256) {
        return _intervalDuration;
    }

    /**
     * @dev Returns duration that NFT has been locked and vesting
     */
    function vestedDuration() public view returns (uint256) {
        return uint256(block.timestamp - vestingStartTime());
    }

    /**
     * @dev Returns current vesting interval
     */
    function getCurrentInterval() public view returns (uint256) {
        if (block.timestamp < vestingStartTime()) {
            return 0;
        }
        uint256 interval = vestedDuration() / getIntervalDuration();
        if (interval > getMaxIntervals()) {
            interval = getMaxIntervals();
        }
        return interval;
    }

    /**
     * @dev Returns the remaining interval before max vesting interval
     */
    function getIntervalsLeft() public view returns (uint256) {
        return getMaxIntervals() - getCurrentInterval();
    }

    /**
     * @dev Get the current discount in terms of percentage for the vesting schedule.
     *
     *  Psuedocode of how discount can be calculated by developer
     *  vested_time = block.timestamp - _vestingStartTime
     *  intervals_passed = maximum(quotient of vested_time / interval_duration, max_intervals)
     *  discount = intervals_passed * discount_per_interval
     */
    function getDiscountPercentage() public view returns (uint256) {
        return getCurrentInterval() * discountPerInterval();
    }

    /**
     * @dev Returns discount accrued by the user up until the current interval.
     */
    function getDiscount() public view returns (uint256) {
        return getDiscountPercentage() * address(this).balance;
    }

    /**
     * @dev Transfers NFT held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time. Sends the discount in Eth to the beneficiary.
     * Reverts if transfer of NFT fails.
     */
    function release() public virtual validRelease {
        require(
            nft().ownerOf(tokenId()) == address(this),
            "TimeLock: no NFT to release for this address"
        );

        uint256 ethDiscount = getDiscount();
        (bool sent, ) = beneficiary().call{value: ethDiscount}("");
        require(sent, "Failed to send Ether");

        nft().safeTransferFrom(address(this), beneficiary(), tokenId());
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
