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
contract LinearVestingNFTTimeLock {
    // ERC721 basic token smart contract
    IERC721 private immutable _nft;

    // ERC721 basic token ID of contract being held
    uint256 private immutable _tokenId;

    // beneficiary of token after they are released
    address private immutable _beneficiary;

    // timestamp when token release is enabled and when discount starts to vest
    uint256 private immutable _releaseTime;

    // Max discount allowed for a token in percentage
    uint256 private immutable _maxDiscount;

    // Duration that token will vest
    uint256 private _maxDuration;

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
        uint256 maxDuration_
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
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
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
    function maxDiscount() public view virtual returns (uint256) {
        return _maxDiscount;
    }
    /**
     * @dev Returns duration that NFT has been locked and vesting
     */
    function vestedDuration() public view returns (uint256) {
        return block.timestamp - _releaseTime;
    }

    /**
     * @dev Returns discount percentage for achieved from vesting
     */

    function getDiscountPercentage() public view returns (uint256) {
        if (block.timestamp < _releaseTime) {
            return 0;
        }
        return (_maxDiscount * vestedDuration()) / maxDuration();
    }

    /**
     * @dev Returns discount for achieved from vesting
     */
    function getDiscount() public view returns (uint256) {
        uint256 currentBalance = address(this).balance;
        uint256 discount = currentBalance * getDiscountPercentage();

        return discount;
    }

    /**
     * @dev Transfers NFT held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time. Sends the discount in Eth to the beneficiary.
     */
    function release() public virtual {
        require(
            block.timestamp >= releaseTime(),
            "TimeLock: current time is before release time"
        );
        require(
            nft().ownerOf(tokenId()) == address(this),
            "TimeLock: no NFT to release for user"
        );

        uint256 ethDiscount = getDiscount();
        (bool sent, ) = beneficiary().call{value: ethDiscount}("");
        require(sent, "Failed to send Ether");

        nft().safeTransferFrom(address(this), beneficiary(), tokenId());
    }
}
