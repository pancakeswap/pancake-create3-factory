// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

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

    /// @notice set user as whitelisted
    function setWhitelistUser(address user, bool isWhiteList) external onlyOwner {
        isUserWhitelisted[user] = isWhiteList;

        emit SetWhitelist(user, isWhiteList);
    }

    function deploy(bytes32 salt, bytes memory creationCode)
        external
        payable
        onlyWhitelisted
        returns (address deployed)
    {
        // hash salt with the deployer address to give each deployer its own namespace
        salt = keccak256(abi.encodePacked(msg.sender, salt));

        deployed = Create2.deploy(msg.value, salt, creationCode);
    }

    function getDeployed(address deployer, bytes32 salt, bytes32 bytecodeHash) public view returns (address addr) {
        // hash salt with the deployer address to give each deployer its own namespace
        salt = keccak256(abi.encodePacked(deployer, salt));

        return Create2.computeAddress(salt, bytecodeHash);
    }

    /// @notice execute a call on a deployed contract
    function execute(bytes32 salt, bytes32 bytecodeHash, bytes calldata data)
        external
        payable
        onlyWhitelisted
        nonReentrant
    {
        address target = getDeployed(msg.sender, salt, bytecodeHash);
        (bool success,) = target.call{value: msg.value}(data);
        require(success, "Create2Factory: failed execute call");
    }
}
