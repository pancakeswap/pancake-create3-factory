// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

/// @notice Reference values taken from the Create3Factory already live on BSC (mainnet + testnet share the same bytecode).
/// @dev Every new deployment must reproduce these values, otherwise contracts deployed through the factory
/// would end up at a different address than on the other chains.
///
/// Values were captured from BSC mainnet:
/// - factory:  0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1 (created by deployer at nonce 0, tx
///   0xe5cf021b94331dbefff0eda8f72b4f21d7643b215fc1d10f4651ac7621d1ee69)
/// - KECCAK256_PROXY_CHILD_BYTECODE: keccak256 of the CustomizedProxyChild creation code embedded in the factory
///   runtime bytecode. It includes the solc metadata hash, so any change in compiler version, optimizer settings,
///   remappings or the CustomizedProxyChild source will change it (and therefore every CREATE3 address).
/// - computeAddress(SANITY_SALT) as returned by the factory on BSC
library Create3FactoryConstants {
    /// @dev EOA that deployed the factory with nonce 0 on every chain
    address internal constant EXPECTED_DEPLOYER = 0xDB1fa6562f3784643c1b547b17dcAEDE0b79CA80;

    address internal constant EXPECTED_FACTORY = 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1;

    /// @dev keccak256 of the factory runtime bytecode on bsc (mainnet and testnet are identical). Only used by fork
    /// tests to make sure they talk to the real on-chain factory. A locally compiled factory may have a different
    /// codehash (its own metadata hash) without affecting create3 addresses.
    bytes32 internal constant EXPECTED_FACTORY_CODEHASH =
        0xc25d75b33104321ed6dbc7d51d496a7a981c97abd9d47749722193e05afcbf2c;

    bytes32 internal constant EXPECTED_KECCAK256_PROXY_CHILD_BYTECODE =
        0x062e0b9e0e28785406fcd3ea3efde49e1d40668774057ec7ba53f120d0809763;

    /// @dev factory.computeAddress(SANITY_SALT) on BSC == EXPECTED_SANITY_ADDRESS
    bytes32 internal constant SANITY_SALT = bytes32(uint256(0x1234));
    address internal constant EXPECTED_SANITY_ADDRESS = 0xC9025a31E39f73AD2B0c7Ce16cceC6A3416e52E0;
}
