// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/src/Script.sol";
import {Create3Factory} from "../src/Create3Factory.sol";

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
        vm.startBroadcast(deployerPrivateKey);

        // Sanity check to use nonce 0, to ensure the contract is deployed at the same address on other chain
        uint64 nonce = vm.getNonce(vm.addr(deployerPrivateKey));
        vm.assertEq(nonce, 0, "Must create contract with nonce 0");

        Create3Factory create3Factory = new Create3Factory();
        console.log("Create3Factory contract deployed at ", address(create3Factory));

        vm.stopBroadcast();
    }
}
