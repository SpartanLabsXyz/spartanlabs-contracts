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
contract IntervalVestingNftTimeLock {
    // ERC721 basic token smart contract
    IERC721 private immutable _nft;

    // ERC721 basic token ID of contract being held
    uint256 private immutable _tokenId;

    // beneficiary of token after they are released
    address private immutable _beneficiary;

    // timestamp when token release is enabled and vesting starts.
    uint256 private immutable _vestingStartTime;

    // Max number of Interval for vesting
    uint256 private immutable _maxIntervals;

    // Duration for each Interval
    uint256 private immutable _intervalDuration;


    // Events
    event EthReceived(address indexed sender, uint256 amount);

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `vestingStartTime_`. The vesting start time is specified as a Unix timestamp
     * (in seconds).
     *
     *  For every set of duration passed after the vesting start time, the number of intervals would increase.
     *  The discount will then be applied to the beneficiary according to number of intervals the token has been vested for.
     *
     *  The developer would have to send ETH to this contract on contract deployement for discount to be applied.
     *  The amount of ETH sent to this contract is the total discount that beneficiary will receive.
     *
     *  Developers would have to perform the following actions for the locking of NFT:
     *  Deploy with Eth sent to contract -> Approve NFT Transfer -> Transfer of NFT to contract
     */
    constructor(
        IERC721 nft_,
        uint256 tokenId_,
        address beneficiary_,
        uint256 vestingStartTime_,
        uint256 maxInterval_,
        uint256 intervalDuration_
    ) {
        require(
            vestingStartTime_ > block.timestamp,
            "TimeLock: vesting start time is before current time"
        );
        
        require(
            address(this).balance > 0,
            "Time:Lock: Eth should be sent to contract before initialization"
        );

        _nft = nft_;
        _tokenId = tokenId_;
        _beneficiary = beneficiary_;
        _vestingStartTime = vestingStartTime_;
        _maxIntervals = maxInterval_;
        _intervalDuration = intervalDuration_;
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
     * @dev Returns the maximum number of intervals set for vesting.
     */
    function maxIntervals() public view virtual returns (uint256) {
        return _maxIntervals;
    }

    /**
     * @dev Returns the set duration of each interval.
     */
    function intervalDuration() public view virtual returns (uint256) {
        return _intervalDuration;
    }

    /**
     * @dev Returns duration that NFT has been locked and vesting
     */
    function vestedDuration() public view returns (uint256) {
        return block.timestamp - vestingStartTime();
    }

    /**
     * @dev Returns the number of interval that the token has been vested for after the vesting start time.
     */
    function intervalsPassed() public view returns (uint256) {
        return vestedDuration() / intervalDuration();
    }

    /**
     * @dev Returns current vesting interval.
     */
    function currentInterval() public view returns (uint256) {
        // Before vesting start time, the interval is 0.
        if (block.timestamp < vestingStartTime()) {
            return 0;
        }

        // After vesting start time, the interval interval count turns to 1.
        uint256 intervals = 1 + intervalsPassed();

        if (intervals > maxIntervals()) {
            intervals = maxIntervals();
        }
        return intervals;
    }

    /**
     * @dev Returns the remaining interval before max vesting interval
     */
    function getIntervalsLeft() public view returns (uint256) {
        return maxIntervals() - currentInterval();
    }


    /**
     * @dev Returns discount accrued by the user up until the current interval.
     *      Discount ratio is the ratio of number of interval passed {currentInterval} to {maxIntervals}.
     *      Maximum discount ratio is 1.
     */
    function getDiscount() public view returns (uint256) {
        return address(this).balance * currentInterval() / maxIntervals();
    }

    /**
     * @dev Transfers NFT held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time {vestingStartTime}.
     *
     * Sends the discount in Eth to the beneficiary.
     * Reverts if transfer of NFT fails.
     */
    function release() public virtual {
        // Check if vesting start time has passed.
        require(
            block.timestamp >= _vestingStartTime,
            "Vesting Schedule is not Up yet."
        );
        // Check if the NFT is already released
        require(
            nft().ownerOf(tokenId()) == address(this),
            "TimeLock: no NFT to release for this address"
        );

        // Sending discount to beneficiary
        uint256 ethDiscount = getDiscount();
        (bool sent, ) = beneficiary().call{value: ethDiscount}("");
        require(sent, "Failed to send Ether");

        // Check if beneficiary has received NFT, if not, revert
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
