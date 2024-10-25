// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {ICreate3Factory} from "./interfaces/ICreate3Factory.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Create3} from "./libraries/Create3.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @notice Deploy contracts in a deterministic way using CREATE3
/// @dev ensure this contract is deployed on multiple chain with the same address
contract Create3Factory is ICreate3Factory, Ownable2Step, ReentrancyGuard {
    event SetWhitelist(address indexed user, bool isWhitelist);
    event Deployed(address indexed deployed, bytes32 salt, bytes32 creationCodeHash);

    // Only whitelisted user can interact with create2Factory
    mapping(address user => bool isWhitelisted) public isUserWhitelisted;

    modifier onlyWhitelisted() {
        if (!isUserWhitelisted[msg.sender]) revert NotWhitelisted();
        _;
    }

    constructor() Ownable(msg.sender) {
        isUserWhitelisted[msg.sender] = true;
    }

    /// @inheritdoc ICreate3Factory
    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        bytes32 creationCodeHash,
        uint256 creationFund,
        bytes calldata afterDeploymentExecutionPayload,
        uint256 afterDeploymentExecutionFund
    ) external payable onlyWhitelisted nonReentrant returns (address deployed) {
        if (creationCodeHash != keccak256(creationCode)) revert CreationCodeHashMismatch();
        if (creationFund + afterDeploymentExecutionFund != msg.value) revert FundsAmountMismatch();

        deployed = Create3.create3(
            salt, creationCode, creationFund, afterDeploymentExecutionPayload, afterDeploymentExecutionFund
        );

        emit Deployed(deployed, salt, creationCodeHash);
    }

    /// @inheritdoc ICreate3Factory
    function computeAddress(bytes32 salt) public view returns (address) {
        return Create3.addressOf(salt);
    }

    /// @inheritdoc ICreate3Factory
    function setWhitelistUser(address user, bool isWhiteList) external onlyOwner {
        isUserWhitelisted[user] = isWhiteList;

        emit SetWhitelist(user, isWhiteList);
    }
}
