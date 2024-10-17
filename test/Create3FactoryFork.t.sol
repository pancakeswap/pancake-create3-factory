// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/src/Test.sol";
import {Create3Factory} from "../src/Create3Factory.sol";
import {MockOwnerWithConstructorArgs} from "./mocks/MockOwnerWithConstructorArgs.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @dev run tests on testnet fork (bsc/sepolia) to verify same contract address across chain. To run the test,
/// ensure TESTNET_FORK_URL_BSC and TESTNET_FORK_URL_SEPOLIA environment variable are set
contract Create3FactoryForkTest is Test {
    Create3Factory create3Factory;

    address create3Deployer = makeAddr("pcsDeployer");
    address expectedOwner = makeAddr("expectedOwner");
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
        vm.startPrank(create3Deployer);
        Create3Factory bscCreate3 = new Create3Factory();
        bscCreate3.setWhitelistUser(pcsDeployer, true);
        vm.stopPrank();

        vm.selectFork(sepoliaForkId);
        vm.startPrank(create3Deployer);
        Create3Factory sepoliaCreate3 = new Create3Factory();
        bscCreate3.setWhitelistUser(pcsDeployer, true);
        vm.stopPrank();

        // assert step 1
        assertEq(address(bscCreate3), address(sepoliaCreate3));

        ////////////////////////////////////////////////////////
        // Step 2: Deploy contracts on both chain using pcsDeployer
        ////////////////////////////////////////////////////////
        bytes memory creationCode = abi.encodePacked(type(MockOwnerWithConstructorArgs).creationCode, abi.encode(666));
        bytes memory afterDeploymentExecutionPayload =
            abi.encodeWithSelector(Ownable.transferOwnership.selector, expectedOwner);
        bytes32 salt = bytes32(uint256(0x1234));

        vm.selectFork(bscForkId);
        vm.prank(pcsDeployer);
        address bscDeployedAddr =
            bscCreate3.deploy(salt, creationCode, keccak256(creationCode), 0, afterDeploymentExecutionPayload, 0);
        assertEq(MockOwnerWithConstructorArgs(bscDeployedAddr).args(), 666);
        assertEq(Ownable(bscDeployedAddr).owner(), expectedOwner);

        // update constructor args just to verify that even creation code is different, the address will be same
        creationCode = abi.encodePacked(type(MockOwnerWithConstructorArgs).creationCode, abi.encode(888));
        vm.selectFork(sepoliaForkId);
        vm.prank(pcsDeployer);
        address sepoliaDeployedAddr =
            sepoliaCreate3.deploy(salt, creationCode, keccak256(creationCode), 0, afterDeploymentExecutionPayload, 0);
        assertEq(MockOwnerWithConstructorArgs(sepoliaDeployedAddr).args(), 888);
        assertEq(Ownable(sepoliaDeployedAddr).owner(), expectedOwner);

        // assert step 2
        assertEq(bscDeployedAddr, sepoliaDeployedAddr);
    }
}
