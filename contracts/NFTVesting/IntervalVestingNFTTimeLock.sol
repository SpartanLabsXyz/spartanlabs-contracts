// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/utils/TokenTimelock.sol)
// SpartanLabs Contracts (NFTVesting)

pragma solidity ^0.8.0;
import "./IERC721.sol";

/**
 * @dev A single NFT holder contract that will allow a beneficiary to extract the
 * NFT after a given release time.
 *
 * Useful for simple vesting schedules like "whitelisted addresses get their NFT
 * after 1 year".
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
    uint256 public immutable _maxInterval;

    // Current interval after @variable _releaseTime
    uint256 public _currentInterval;

    // Duration for each Interval
    uint256 public _intervalDuration;

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
     * (in seconds).
     */
    constructor(
        IERC721 nft_,
        uint256 tokenId_,
        address beneficiary_,
        uint256 releaseTime_,
        uint256 maxDiscount_,
        uint256 maxInterval_,
        uint256 intervalDuration_
    ) {
        require(
            releaseTime_ > block.timestamp,
            "BasicNFTTimelock: release time is before current time"
        );
        _nft = nft_;
        _tokenId = tokenId_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
        _maxDiscount = maxDiscount_;
        _maxInterval = maxInterval_;
        _intervalDuration = intervalDuration_;
        _currentInterval = 0;
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
     * @dev Returns discount for locking at each Interval
     */
    function discountPerInterval() public view virtual returns (uint256) {
        return _maxDiscount / _maxInterval;
    }

    /**
     * @dev Returns current Interval
     */
     */
    function getCurrentInterval() public view returns (uint256) {
        if (block.timestamp < _releaseTime) {
            return 0;
        }
        uint256 interval = uint256(block.timestamp - _releaseTime) /
            _intervalDuration;
        if (interval > _maxInterval) {
            interval = _maxInterval;
        }
        return interval;
    }

    /**
     * @dev Returns the remaining interval before max vesting interval
     */
    function getIntervalsLeft() public view returns (uint256) {
        return _maxInterval - _currentInterval;
    }

    /**
     * @dev Updates the interval after release schedule
     */
    function updateInterval() private validRelease {
        require(_currentInterval <= _maxInterval, "Vesting Schedule is over.");
        // floor the current Interval to the nearest Interval interval
        _currentInterval = getCurrentInterval();
    }

    /**
     * @dev Get the current discount in terms of percentage for the vesting schedule.
     */
    function getDiscount() public view returns (uint256) {
        require(_currentInterval > 0, "Vesting Schedule is not Up yet.");
        return (_currentInterval * discountPerInterval()) / 100;
    }

    /**
     * @dev Transfers NFT held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time. Sends the discount in Eth to the beneficiary.
     */

    function release() public virtual validRelease{
        require(
            nft().ownerOf(tokenId()) == address(this),
            "BasicNFTTimelock: no NFT to release"
        );

        updateInterval();
        uint256 discount = getDiscount();
        uint256 ethDiscount = discount * address(this).balance;
        (bool sent, ) = beneficiary().call{value: ethDiscount}(""); 
        require(sent, "Failed to send Ether");

        nft().safeTransferFrom(address(this), beneficiary(), tokenId());
    }
}
