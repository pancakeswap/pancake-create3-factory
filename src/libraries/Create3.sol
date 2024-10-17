// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {CustomizedProxyChild} from "../CustomizedProxyChild.sol";

/**
 * @dev Referenced from https://github.com/0xsequence/create3/blob/master/contracts/Create3.sol
 * Updated PROXY_CHILD_BYTECODE to support customized deployment logic
 * @title A library for deploying contracts EIP-3171 style.
 * @author Agustin Aguilar <aa@horizon.io>
 */
library Create3 {
    error ErrorCreatingProxy();
    error ErrorCreatingContract();
    error TargetAlreadyExists();

    bytes internal constant PROXY_CHILD_BYTECODE = type(CustomizedProxyChild).creationCode;

    bytes32 internal constant KECCAK256_PROXY_CHILD_BYTECODE = keccak256(PROXY_CHILD_BYTECODE);

    /**
     * @notice Returns the size of the code on a given address
     * @param _addr Address that may or may not contain code
     * @return size of the code on the given `_addr`
     */
    function codeSize(address _addr) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(_addr)
        }
    }

    /**
     * @notice Creates a new contract with given `_creationCode` and `_salt`
     * @param _salt Salt of the contract creation, resulting address will be derived from this value only
     * @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
     * @param _creationFund In WEI of ETH to be forwarded to target contract constructor
     * @param _afterDeploymentExecutionPayload Payload to be executed after contract creation
     * @param _afterDeploymentExecutionFund In WEI of ETH to be forwarded to when executing after deployment initialization
     * @return addr of the deployed contract, reverts on error
     */
    function create3(
        bytes32 _salt,
        bytes memory _creationCode,
        uint256 _creationFund,
        bytes calldata _afterDeploymentExecutionPayload,
        uint256 _afterDeploymentExecutionFund
    ) internal returns (address addr) {
        // Creation code
        bytes memory proxyCreationCode = PROXY_CHILD_BYTECODE;

        // Get target final address
        address preCalculatedAddr = addressOf(_salt);
        if (codeSize(preCalculatedAddr) != 0) revert TargetAlreadyExists();

        // Create CREATE2 proxy
        address proxy;
        assembly {
            proxy := create2(0, add(proxyCreationCode, 32), mload(proxyCreationCode), _salt)
        }
        if (proxy == address(0)) revert ErrorCreatingProxy();

        // Call proxy with final init code to deploy target contract
        addr = CustomizedProxyChild(proxy).deploy{value: _creationFund + _afterDeploymentExecutionFund}(
            _creationCode, _creationFund, _afterDeploymentExecutionPayload, _afterDeploymentExecutionFund
        );

        if (preCalculatedAddr != addr) revert ErrorCreatingContract();
    }

    /**
     * @notice Computes the resulting address of a contract deployed using address(this) and the given `_salt`
     * @param _salt Salt of the contract creation, resulting address will be derived from this value only
     * @return addr of the deployed contract, reverts on error
     *
     * @dev The address creation formula is: keccak256(rlp([keccak256(0xff ++ address(this) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
     */
    function addressOf(bytes32 _salt) internal view returns (address) {
        address proxy = address(
            uint160(uint256(keccak256(abi.encodePacked(hex"ff", address(this), _salt, KECCAK256_PROXY_CHILD_BYTECODE))))
        );

        return address(uint160(uint256(keccak256(abi.encodePacked(hex"d694", proxy, hex"01")))));
    }
}
