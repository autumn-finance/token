// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./openzeppelin/ERC20.sol";

/// @dev Helper to deploy the token
contract ATMToken is ERC20 {
    constructor () ERC20("Autumn", "ATM") {
        _mint(_msgSender(), 10000000 * 1e18);
    }
}