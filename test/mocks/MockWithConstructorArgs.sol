// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

contract MockWithConstructorArgs {
    uint256 public args;

    constructor(uint256 _args) {
        args = _args;
    }
}
