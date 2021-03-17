// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./openzeppelin/Ownable.sol";
import { IERC20, SafeERC20, SafeMath } from "./openzeppelin/SafeERC20.sol";

/// @dev Linear token timelock and releasing
contract Timelock is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Token to timelock
    address public token;

    /// @dev Timestamp of timelock ending
    uint256 public timelockEndTime;

    /// @dev Last time of release to compare past time
    uint256 public lastReleaseTime;

    /// @dev Release amount in per second
    uint256 public releasePerSecond;

    /// @dev Recipient of releasing
    address public recipient;

    constructor (address _token) {
        token = _token;
    }

    function setRecipient(address _recipient) onlyOwner() external {
        recipient = _recipient;
    }

    function startTimelock(uint256 amount, uint256 duration) onlyOwner() external {
        require(lastReleaseTime == 0, "Timelock already started");
        require(duration != 0, "Timelock duration is zero");
        
        IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);
        releasePerSecond = IERC20(token).balanceOf(address(this)).div(duration);
        require(releasePerSecond != 0, "Amount too few");
        lastReleaseTime = block.timestamp;
        timelockEndTime = block.timestamp.add(duration);
    }

    function lastTimeApplicable() private view returns (uint256) {
        return block.timestamp > timelockEndTime ? timelockEndTime : block.timestamp;
    }

    /// @dev Available amount of releasing
    function available() public view returns (uint256) {
        require(lastReleaseTime != 0, "Timelock not start yet");
        uint256 past = lastTimeApplicable().sub(lastReleaseTime);
        require(past != 0, "No release available yet");
        return past.mul(releasePerSecond);
    }

    /// @dev Releases and transfer to recipient
    function tryRelease() external {
        require(recipient != address(0), "No recipient");
        IERC20(token).safeTransfer(recipient, available());
        lastReleaseTime = block.timestamp;
    }
}