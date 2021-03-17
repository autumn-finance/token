// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./openzeppelin/Ownable.sol";
import { IERC20, SafeERC20, SafeMath } from "./openzeppelin/SafeERC20.sol";

/// @dev Simple contract for public offering
contract Offering is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public cost;
    address public sell;
    uint256 public costPerPortion;
    uint256 public sellPerPortion;
    bool public native;

    uint256 public availablePortions;
    uint256 public totalSoldPortions;

    constructor (
        address cost_, address sell_,
        uint256 costPerPortion_, uint256 sellPerPortion_,
        bool native_)
    {
        require(cost_ != sell_, "Cannot offering same");
        cost = cost_; sell = sell_;
        costPerPortion = costPerPortion_; sellPerPortion = sellPerPortion_;
        native = native_;
    }

    function buy(uint256 portions) external payable {
        require(portions != 0, "Cannot buy zero portion");
        availablePortions = availablePortions.sub(portions, "No available portions");
        totalSoldPortions = totalSoldPortions.add(portions); // statistic

        uint256 costAmount = costPerPortion.mul(portions);
        if (native) {
            require(costAmount == msg.value, "Inconsistent amount");
        } else {
            IERC20(cost).safeTransferFrom(_msgSender(), address(this), costAmount);
        }
        IERC20(sell).safeTransfer(_msgSender(), sellPerPortion.mul(portions));
    }

    // Admin functions

    function addOffers(uint256 portions) onlyOwner() external {
        IERC20(sell).safeTransferFrom(_msgSender(), address(this), sellPerPortion.mul(portions));
        availablePortions = availablePortions.add(portions);
    }

    function subOffers(uint256 portions) onlyOwner() external {
        require(portions <= availablePortions, "Exceeds available");
        availablePortions = availablePortions.sub(portions);
        IERC20(sell).safeTransfer(_msgSender(), sellPerPortion.mul(portions));
    }

    function claimNative(uint256 amount) onlyOwner() external {
        msg.sender.transfer(amount);
    }

    function claimERC20(address token, uint256 amount) onlyOwner() external {
        require(token != sell, "Use `subOffers` for offering token");
        IERC20(token).safeTransfer(_msgSender(), amount);
    }
}