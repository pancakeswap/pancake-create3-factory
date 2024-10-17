// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CustomizedProxyChild} from "../../src/CustomizedProxyChild.sol";

contract MockOwnerWithConstructorArgs is Ownable {
    uint256 public args;

    constructor(uint256 _args) payable Ownable(msg.sender) {
        args = _args;
    }

    function payMe() external payable {
        // do nothing
    }

    function tryReEntryChildProxy() external {
        CustomizedProxyChild(msg.sender).deploy(new bytes(0), 0, new bytes(0), 0);
    }
}
