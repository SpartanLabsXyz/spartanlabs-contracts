// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/utils/TokenTimelock.sol)
// SpartanLabs Contracts (NFTVesting)

pragma solidity ^0.8.0;
import "./IERC721.sol";

/**
 * @dev A single NFT holder contract that will allow a beneficiary to extract the
 * NFT after a given cliff period.
 *
 * Useful for simple vesting schedules like "whitelisted addresses get their NFT
 * after 1 year".
 */
contract ConvexVestingNFTTimeLock {
    // ERC721 basic token smart contract
    IERC721 private immutable _nft;

    // ERC721 basic token ID of contract being held
    uint256 private immutable _tokenId;

    // beneficiary of token after they are released
    address private immutable _beneficiary;

    // timestamp when token release is enabled and when discount starts to vest
    uint256 private immutable _cliffPeriod;

    // Max discount allowed for a token in percentage
    uint256 private immutable _maxDiscountPercentage;

    // Duration that token will vest
    uint256 private immutable _maxDuration;

    // Growth rate for vesting. M in MX^exponent
    uint256 private immutable _growthRate;

    // Exponent for vesting. exponent in MX^exponent
    uint8 private immutable _exponent;

    // Events
    event EthReceived(address indexed sender, uint256 amount);

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `cliffPeriod_`. The cliff period is specified as a Unix timestamp
     * (in seconds).
     *
     *  The discount accumulation for beneficiary is based off a convex model y = mx^exponent
     *  The developer would have to send ETH to this contract on contract deployement for discount to be applied.
     *
     */
    constructor(
        IERC721 nft_,
        uint256 tokenId_,
        address beneficiary_,
        uint256 cliffPeriod_,
        uint256 maxDiscountPercentage_,
        uint256 maxDuration_,
        uint256 growthRate_,
        uint8 exponent_
    ) {
        require(
            cliffPeriod_ > block.timestamp,
            "Timelock: cliff period is before current time"
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
        _cliffPeriod = cliffPeriod_;
        _maxDiscountPercentage = maxDiscountPercentage_;
        _maxDuration = maxDuration_;
        _growthRate = growthRate_;
        _exponent = exponent_;
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
    function cliffPeriod() public view virtual returns (uint256) {
        return _cliffPeriod;
    }

    /**
     * @dev Returns max discount percentage that beneficiary can receive
     */
    function maxDiscountPercentage() public view virtual returns (uint256) {
        return _maxDiscountPercentage;
    }

    /**
     * @dev Returns max duration that token will vest for before hitting max discount percentage
     */
    function maxDuration() public view virtual returns (uint256) {
        return _maxDuration;
    }

    /**
     * @dev Returns growth rate for vesting. M in MX^exponent
     */
    function growthRate() public view virtual returns (uint256) {
        return _growthRate;
    }

    /**
     * @dev Returns Exponent for vesting. exponent in MX^exponent
     */
    function exponent() public view virtual returns (uint8) {
        return _exponent;
    }

    /**
     * @dev Returns duration that NFT has been locked and vesting
     */
    function vestedDuration() public view returns (uint256) {
        return block.timestamp - cliffPeriod();
    }

    /**
     * @dev Returns current discount percentage for achieved from vesting. 
     * Based off: discount = mx**exponent
     */
    function getDiscountPercentage() public view returns (uint256) {
        if (block.timestamp < cliffPeriod()) {
            return 0;
        }
        uint256 discountPercentage = growthRate() *
            vestedDuration()**exponent();

        if (discountPercentage > maxDiscountPercentage()) {
            return maxDiscountPercentage();
        }
        return discountPercentage;
    }

    /**
     * @dev Returns discount for achieved from vesting
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
            block.timestamp >= cliffPeriod(),
            "TimeLock: current time is before cliff period"
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
