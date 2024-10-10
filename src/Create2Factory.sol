// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice Deploy contracts in a deterministic way using CREATE2
/// @dev ensure this contract is deployed on multiple chain with the same address
contract Create2Factory is Ownable2Step, ReentrancyGuard {
    event SetWhitelist(address indexed user, bool isWhitelist);

    // Only whitelisted user can interact with create2Factory
    mapping(address user => bool isWhitelisted) public isUserWhitelisted;

    modifier onlyWhitelisted() {
        require(isUserWhitelisted[msg.sender], "Create2Factory: caller is not whitelisted");
        _;
    }

    constructor() Ownable(msg.sender) {
        isUserWhitelisted[msg.sender] = true;
    }

    /// @notice create2 deploy a contract
    /// @dev So long the same salt, creationCode is used, the contract will be deployed at the same address on other chain
    function deploy(bytes32 salt, bytes memory creationCode)
        external
        payable
        onlyWhitelisted
        returns (address deployed)
    {
        deployed = Create2.deploy(msg.value, salt, creationCode);
    }

    function getDeployed(bytes32 salt, bytes32 bytecodeHash) public view returns (address addr) {
        return Create2.computeAddress(salt, bytecodeHash);
    }

    /// @notice execute a call on a deployed contract
    /// @dev used in scenario where contract owner is create2Factory and we need to transfer ownership
    function execute(address target, bytes calldata data) external payable onlyWhitelisted nonReentrant {
        (bool success,) = target.call{value: msg.value}(data);
        require(success, "Create2Factory: failed execute call");
    }

    /// @notice set user as whitelisted
    function setWhitelistUser(address user, bool isWhiteList) external onlyOwner {
        isUserWhitelisted[user] = isWhiteList;

        emit SetWhitelist(user, isWhiteList);
    }
}
