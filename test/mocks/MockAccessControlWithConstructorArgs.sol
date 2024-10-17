// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {AccessControlDefaultAdminRules} from
    "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";

contract MockAccessControlWithConstructorArgs is AccessControlDefaultAdminRules {
    string public args;

    constructor(string memory _args) payable AccessControlDefaultAdminRules(1 days, msg.sender) {
        args = _args;
    }
}
