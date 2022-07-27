// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/utils/TokenTimelock.sol)
// SpartanLabs Contracts (NFTVesting)

pragma solidity ^0.8.0;
import "./IERC721.sol";

/**
 * @dev A single NFT holder contract that will allow a beneficiary to extract the
 * NFT after a given lock period.
 *
 * Developers would have to perform the following actions for the locking of NFT:
 * Deploy -> Approve -> Transfer
 *
 * Useful for simple vesting schedules like "whitelisted addresses get their NFT
 * after 1 year".
 */
contract BasicNftTimelock {
    // ERC721 basic token smart contract
    IERC721 private immutable _nft;

    // ERC721 basic token ID of contract being held
    uint256 private immutable _tokenId;

    // beneficiary of token after they are released
    address private immutable _beneficiary;

    // timestamp when token release is enabled
    uint256 private immutable _releaseTime;

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_`. The cliff period is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(
        IERC721 nft_,
        uint256 tokenId_,
        address beneficiary_,
        uint256 releaseTime_
    ) {
        require(
            releaseTime_ > block.timestamp,
            "BasicNFTTimelock: releaseTime_ has to be in the future"
        );
        _nft = nft_;
        _tokenId = tokenId_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
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
     * @dev Transfers NFT held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time.
     * Reverts if transfer of NFT fails.
     */
    function release() public virtual {
        // Check if current time is after vesting start time
        require(
            block.timestamp >= releaseTime(),
            "BasicNFTTimelock: current time is before cliff period"
        );
        
        // Check if the NFT is already released
        require(
            nft().ownerOf(tokenId()) == address(this),
            "BasicNFTTimelock: no NFT to release"
        );

        // Transfer NFT to beneficiary
        nft().safeTransferFrom(address(this), beneficiary(), tokenId());

        // Check if beneficiary has received NFT, if not, revert
        require(
            nft().ownerOf(tokenId()) != address(this),
            "BasicNFTTimelock: NFT still owned by this contract"
        );
    }
}
