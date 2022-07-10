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

    // Max number of epochs 
    uint256 private immutable _maxEpoch;

    // Current discount epoch after @variable _releaseTime
    uint256 private _currentEpoch;

    // Epoch Interval
    uint256 private _epochInterval;



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
        uint256 maxEpoch_,
        uint256 epochInterval_
    ) {
        require(releaseTime_ > block.timestamp, "BasicNFTTimelock: release time is before current time");
        _nft = nft_;
        _tokenId = tokenId_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
        _maxDiscount = maxDiscount_;
        _maxEpoch = maxEpoch_;
        _epochInterval = epochInterval_;
        _currentEpoch = 0;
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
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    /**
     * @dev Returns discount for locking at each epoch
     */
    function discountPerEpoch() public view virtual returns (uint256){
        return _maxDiscount/_maxEpoch;
    }

    function getCurrentEpoch() public view returns (uint256){
     uint256 epoch = uint256((block.timestamp - _releaseTime) / _epochInterval);
     if (epoch > _maxEpoch) {
         epoch = _maxEpoch;
     }
        return epoch;

    }

    function getEpochsLeft() public view returns (uint256){
        return _maxEpoch - _currentEpoch;
    }
    

    function updateEpoch() private {
        require(block.timestamp >= _releaseTime + _epochInterval, "Vesting Schedule is not Up yet.");
        require(_currentEpoch <= _maxEpoch, "Vesting Schedule is over.");
        // floor the current epoch to the nearest epoch interval
        _currentEpoch = getCurrentEpoch();
    }

    /**
     * @dev Get the current discount in terms of percentage for the vesting schedule.
     */
    function getDiscount() public view returns (uint256){
        require(_currentEpoch > 0, "Vesting Schedule is not Up yet.");
        return _currentEpoch * discountPerEpoch() / 100;
    }

    /**
     * @dev Transfers NFT held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time.
     */
    function release() public virtual {
        require(block.timestamp >= releaseTime(), "BasicNFTTimelock: current time is before release time");
        require(nft().ownerOf(tokenId()) == address(this), "BasicNFTTimelock: no NFT to release");
        
        updateEpoch();
        uint256 discount = getDiscount();
        uint256 ethDiscount = discount * address(this).balance;
        (bool sent, ) = msg.sender.call{value: ethDiscount}("");
        require(sent, "Failed to send Ether");

        nft().safeTransferFrom(address(this), beneficiary(), tokenId());
    }
}
