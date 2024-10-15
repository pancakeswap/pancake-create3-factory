// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/src/Test.sol";
import {Create2Factory} from "../src/Create2Factory.sol";
import {MockOwner} from "./mocks/MockOwner.sol";

/// @dev run tests on testnet fork (bsc/sepolia) to verify same contract address across chain. To run the test,
/// ensure TESTNET_FORK_URL_BSC and TESTNET_FORK_URL_SEPOLIA environment variable are set
contract Create2FactoryForkTest is Test {
    Create2Factory create2Factory;

    address create2Deployer = makeAddr("pcsDeployer");
    /// @dev address with difference nonce on bsc / eth
    address pcsDeployer = 0x42571B8414c68B63A2729146CE93F23639d25399;

    function test_Deploy_OnTestnetFork() public {
        if (!vm.envExists("TESTNET_FORK_URL_BSC") || !vm.envExists("TESTNET_FORK_URL_SEPOLIA")) {
            return;
        }

        // deploy on bsc
        uint256 bscForkId = vm.createFork(vm.envString("TESTNET_FORK_URL_BSC"));
        uint256 sepoliaForkId = vm.createFork(vm.envString("TESTNET_FORK_URL_SEPOLIA"));

        ////////////////////////////////////////////////////////
        // Step 1: Deploy create2Factory on both chain
        ////////////////////////////////////////////////////////
        vm.selectFork(bscForkId);
        vm.startPrank(create2Deployer);
        Create2Factory bscCreate2 = new Create2Factory();
        bscCreate2.setWhitelistUser(pcsDeployer, true);
        vm.stopPrank();

        vm.selectFork(sepoliaForkId);
        vm.startPrank(create2Deployer);
        Create2Factory sepoliaCreate2 = new Create2Factory();
        bscCreate2.setWhitelistUser(pcsDeployer, true);
        vm.stopPrank();

        // assert step 1
        assertEq(address(bscCreate2), address(sepoliaCreate2));

        ////////////////////////////////////////////////////////
        // Step 2: Deploy contracts on both chain using pcsDeployer
        ////////////////////////////////////////////////////////
        bytes memory creationCode = type(MockOwner).creationCode;
        bytes32 salt = bytes32(uint256(0x1234));

        vm.selectFork(bscForkId);
        vm.prank(pcsDeployer);
        address bscMockOwner = bscCreate2.deploy(salt, creationCode);

        vm.selectFork(sepoliaForkId);
        vm.prank(pcsDeployer);
        address sepoliaMockOwner = sepoliaCreate2.deploy(salt, creationCode);

        // assert step 2
        assertEq(bscMockOwner, sepoliaMockOwner);
    }
}
