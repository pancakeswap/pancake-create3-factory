// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {BaseScript} from "./BaseScript.sol";
import {Create2Factory} from "../src/Create2Factory.sol";

/**
 * forge script script/00_DeployCreate2Factory.s.sol:DeployCreate2FactoryScript -vvv \
 *     --rpc-url $RPC_URL \
 *     --broadcast \
 *     --slow \
 *     --verify
 */
contract DeployCreate2FactoryScript is BaseScript {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Sanity check to use nonce 0, to ensure the contract is deployed at the same address on other chain
        uint64 nonce = vm.getNonce(vm.addr(deployerPrivateKey));
        vm.assertEq(nonce, 0, "Must create contract with nonce 0");

        Create2Factory create2Factory = new Create2Factory();
        console.log("Create2Factory contract deployed at ", address(create2Factory));

        vm.stopBroadcast();
    }
}
