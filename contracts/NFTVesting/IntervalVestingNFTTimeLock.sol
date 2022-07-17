// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/utils/TokenTimelock.sol)
// SpartanLabs Contracts (NFTVesting)

pragma solidity ^0.8.0;
import "./IERC721.sol";

/**
 * @dev A single NFT holder contract that will allow a beneficiary to extract the
 * NFT after a given release time with a discount sent to the beneficiary based on
 * the vesting duration of the NFT.
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
    uint256 private immutable _releaseTime;

    // Max discount allowed for a token in percentage
    uint256 private immutable _maxDiscount;

    // Max number of Interval for vesting
    uint256 private immutable _maxIntervals;

    // Duration for each Interval
    uint256 private _intervalDuration;

    // Discount for every interval passed
    uint256 private _discountPerInterval;



    modifier validRelease() {
        require(
            block.timestamp >= _releaseTime + _intervalDuration,
            "Vesting Schedule is not Up yet."
        );
        _;
    }

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_`. The release time is specified as a Unix timestamp
     * (in seconds). For every set of duration passed after the release time, the number of intervals would increase. 
     *  The discount will then be applied to the beneficiary according to number of intervals the token has been vested for. 
     * 
     *  The developer would have to send ETH to this contract for discount to be applied after initialization
     */
    constructor(
        IERC721 nft_,
        uint256 tokenId_,
        address beneficiary_,
        uint256 releaseTime_,
        uint256 maxDiscount_,
        uint256 maxInterval_,
        uint256 intervalDuration_,
        uint256 discountPerInterval_
    ) {
        require(
            releaseTime_ > block.timestamp,
            "TimeLock: release time is before current time"
        );
        require(
            0 < maxDiscount_ <= 100,
            "TimeLock: max discount is greater than 100% or 0. Please use a valid maxDiscount."
        );
        require(
            discountPerInterval_ * maxInterval_ == maxDiscount_,
            "TimeLock: discount per interval is not equal to max discount. Please use a valid discountPerInterval."
        );
        require(
            address(this).balance >= discountPerInterval_ * maxInterval_,
            "TimeLock: not enough ETH to pay for discount. Please send more ETH."
        );        


        _nft = nft_;
        _tokenId = tokenId_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
        _maxDiscount = maxDiscount_;
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
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    /**
     * @dev Returns the max discount allowed for a token in percentage.
     */
     function maxDiscount() public view virtual returns (uint256) {
        return _maxDiscount;
     }


    /**
     * @dev Returns discount for locking at each Interval
     */
    function discountPerInterval() public view virtual returns (uint256) {
        return _discountPerInterval;
    }

    /**
     * @dev Returns duration that NFT has been locked and vesting
     */
    function vestedDuration() public view returns (uint256) {
        return uint256(block.timestamp - _releaseTime);
    }

    /**
     * @dev Returns current vesting interval
     */
    function getCurrentInterval() public view returns (uint256) {
        if (block.timestamp < _releaseTime) {
            return 0;
        }
        uint256 interval = vestedDuration() / _intervalDuration;
        if (interval > _maxIntervals) {
            interval = _maxIntervals;
        }
        return interval;
    }

    /**
     * @dev Returns the remaining interval before max vesting interval
     */
    function getIntervalsLeft() public view returns (uint256) {
        return _maxIntervals - getCurrentInterval();
    }


    /**
     * @dev Get the current discount in terms of percentage for the vesting schedule.
     *
     *  Psuedocode of how discount can be calculated by developer
     *  vested_time = block.timestamp - _releaseTime
     *  intervals_passed = maximum(quotient of vested_time / interval_duration, max_intervals)
     *  discount = intervals_passed * discount_per_interval

     */
    function getDiscountPercentage() public view returns (uint256) {
        return getCurrentInterval() * discountPerInterval();
    }

    /**
     * @dev Transfers NFT held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time. Sends the discount in Eth to the beneficiary.
     */

    function release() public virtual validRelease {
        require(
            nft().ownerOf(tokenId()) == address(this),
            "TimeLock: no NFT to release for user"
        );
        require()

        uint256 discount = getDiscount();
        uint256 ethDiscount = discount * address(this).balance;
        (bool sent, ) = beneficiary().call{value: ethDiscount}("");
        require(sent, "Failed to send Ether");

        nft().safeTransferFrom(address(this), beneficiary(), tokenId());
    }

    
    /**
     * @dev Fallback function for eth to be sent to contract on Initialization.
     */
    fallback() external payable{}
}
