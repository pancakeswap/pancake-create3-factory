// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev plain OpenZeppelin ERC20 with constructor args, used to verify create3 deployment across chains
contract MockERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_, address initialHolder, uint256 initialSupply)
        ERC20(name_, symbol_)
    {
        _mint(initialHolder, initialSupply);
    }
}
