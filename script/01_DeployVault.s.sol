// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {BaseScript} from "./BaseScript.sol";
import {Create2Factory} from "../src/Create2Factory.sol";
import {Vault} from "pancake-v4-core/src/Vault.sol";

/**
 * forge script script/01_DeployVault.s.sol:DeployVaultScript -vvv \
 *     --rpc-url $RPC_URL \
 *     --broadcast \
 *     --slow \
 *     --verify
 */
contract DeployVaultScript is BaseScript {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Pre-req: load create2Factory
        Create2Factory create2Factory = getCreate2Factory();
        console.log("create2Factory address: ", address(create2Factory));

        // Deploy
        bytes memory creationCode = type(Vault).creationCode;
        bytes32 salt = keccak256(abi.encodePacked("XX"));
        address deployed = create2Factory.deploy(salt, creationCode);

        console.log("Vault contract deployed at ", deployed);

        vm.stopBroadcast();
    }
}
