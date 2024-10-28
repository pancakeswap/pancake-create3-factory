//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICreate3Factory {
    error NotWhitelisted();
    error CreationCodeHashMismatch();
    error FundsAmountMismatch();

    /**
     * @notice create3 deploy a contract
     * @dev So long the same salt is used, the contract will be deployed at the same address on other chain
     * @param salt Salt of the contract creation, resulting address will be derived from this value only
     * @param creationCode Creation code (constructor + args) of the contract to be deployed, this value doesn't affect the resulting address
     * @param creationCodeHash Hash of the creation code, it can be used to verify the creation code
     * @param creationFund In WEI of ETH to be forwarded to target contract constructor
     * @param afterDeploymentExecutionPayload Payload to be executed after contract creation
     * @param afterDeploymentExecutionFund In WEI of ETH to be forwarded to when executing after deployment initialization
     * @return deployed of the deployed contract, reverts on error
     */
    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        bytes32 creationCodeHash,
        uint256 creationFund,
        bytes calldata afterDeploymentExecutionPayload,
        uint256 afterDeploymentExecutionFund
    ) external payable returns (address deployed);

    /// @notice compute the create3 address based on salt
    function computeAddress(bytes32 salt) external view returns (address);

    /// @notice set user as whitelisted
    function setWhitelistUser(address user, bool isWhiteList) external;
}
