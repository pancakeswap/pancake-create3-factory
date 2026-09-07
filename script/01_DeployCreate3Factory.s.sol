// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/src/Script.sol";
import {Create3Factory} from "../src/Create3Factory.sol";
import {Create3} from "../src/libraries/Create3.sol";
import {Create3FactoryConstants} from "./Create3FactoryConstants.sol";

/**
 * forge script script/01_DeployCreate3Factory.s.sol:DeployCreate3FactoryScript -vvv \
 *     --rpc-url $RPC_URL \
 *     --broadcast \
 *     --slow \
 *     --verify
 */
contract DeployCreate3FactoryScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        ////////////////////////////////////////////////////////
        // Pre-deployment checks (before spending the nonce 0)
        ////////////////////////////////////////////////////////

        // Sanity check to use nonce 0, to ensure the contract is deployed at the same address on other chain
        uint64 nonce = vm.getNonce(deployer);
        vm.assertEq(nonce, 0, "Must create contract with nonce 0");

        // Factory address only depends on (deployer, nonce), make sure it matches the address on bsc
        vm.assertEq(
            vm.computeCreateAddress(deployer, nonce),
            Create3FactoryConstants.EXPECTED_FACTORY,
            "Deployer would not create the factory at the same address as bsc"
        );

        // KECCAK256_PROXY_CHILD_BYTECODE is baked into the factory at compile time and drives every CREATE3 address.
        // It must be identical to the factory on bsc, otherwise contracts deployed via this factory would live at
        // different addresses across chains. Any change in solc version / optimizer / remappings / metadata breaks this.
        vm.assertEq(
            Create3.KECCAK256_PROXY_CHILD_BYTECODE,
            Create3FactoryConstants.EXPECTED_KECCAK256_PROXY_CHILD_BYTECODE,
            "KECCAK256_PROXY_CHILD_BYTECODE mismatch with bsc, check solc version / remappings / foundry.toml"
        );

        ////////////////////////////////////////////////////////
        // Deployment
        ////////////////////////////////////////////////////////
        vm.startBroadcast(deployerPrivateKey);
        Create3Factory create3Factory = new Create3Factory();
        vm.stopBroadcast();
        console.log("Create3Factory contract deployed at ", address(create3Factory));

        ////////////////////////////////////////////////////////
        // Post-deployment checks against the factory on bsc
        ////////////////////////////////////////////////////////
        vm.assertEq(
            address(create3Factory), Create3FactoryConstants.EXPECTED_FACTORY, "Factory address mismatch with bsc"
        );
        vm.assertEq(
            create3Factory.computeAddress(Create3FactoryConstants.SANITY_SALT),
            Create3FactoryConstants.EXPECTED_SANITY_ADDRESS,
            "computeAddress mismatch with bsc, KECCAK256_PROXY_CHILD_BYTECODE differs"
        );
        console.log("KECCAK256_PROXY_CHILD_BYTECODE verified: ");
        console.logBytes32(Create3.KECCAK256_PROXY_CHILD_BYTECODE);
    }
}
