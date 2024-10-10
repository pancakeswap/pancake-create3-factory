// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockOwner is Ownable {
    constructor() Ownable(msg.sender) {}

    /// @notice test function to test payableFunc
    function payableFunc() external payable {}
}
