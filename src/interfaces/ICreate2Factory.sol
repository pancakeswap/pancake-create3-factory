//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICreate2Factory {
    /// @notice create2 deploy a contract
    /// @dev So long the same salt, creationCode is used, the contract will be deployed at the same address on other chain
    function deploy(bytes32 salt, bytes memory creationCode) external payable returns (address deployed);

    /// @notice compute the create2 address based on salt, bytecodeHash
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) external view returns (address);

    /// @notice execute a call on a deployed contract
    /// @dev used in scenario where contract owner is create2Factory and we need to transfer ownership
    function execute(address target, bytes calldata data) external payable;

    /// @notice set user as whitelisted
    function setWhitelistUser(address user, bool isWhiteList) external;
}
