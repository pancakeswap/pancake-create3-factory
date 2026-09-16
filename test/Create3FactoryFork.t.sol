// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/src/Test.sol";
import {Create3Factory} from "../src/Create3Factory.sol";
import {MockOwnerWithConstructorArgs} from "./mocks/MockOwnerWithConstructorArgs.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Create3FactoryConstants} from "../script/Create3FactoryConstants.sol";

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

    /// @dev Deploy an OpenZeppelin ERC20 through
    ///   1. the factory that is already live on bsc (fork), and
    ///   2. a factory compiled locally and deployed by the real deployer with nonce 0 on a second bsc fork where the
    ///      on-chain factory has been wiped (so the local build lands on the very same address)
    /// and verify both end up at the same address. This proves the locally compiled factory
    /// (in particular KECCAK256_PROXY_CHILD_BYTECODE) is equivalent to the one on bsc.
    /// Uses MAINNET_FORK_URL_BSC when set, otherwise falls back to a public bsc rpc.
    function test_Deploy_OpenZeppelinERC20_LocalVsBscFork() public {
        string memory bscRpc = vm.envOr("MAINNET_FORK_URL_BSC", string("https://bsc-rpc.publicnode.com"));
        address deployer = Create3FactoryConstants.EXPECTED_DEPLOYER;
        address holder = makeAddr("holder");

        bytes32 salt = keccak256("pancake-create3-factory/fork-test/oz-erc20");
        bytes memory creationCode =
            abi.encodePacked(type(MockERC20).creationCode, abi.encode("Pancake Test Token", "PTT", holder, 1e24));
        bytes32 creationCodeHash = keccak256(creationCode);

        // note: forge carries every account touched in the local state into the forks, so both environments are
        // forks and nothing is deployed locally before selecting them
        uint256 bscLiveForkId = vm.createFork(bscRpc);
        uint256 bscReplayForkId = vm.createFork(bscRpc);

        ////////////////////////////////////////////////////////
        // Step 1: bsc fork, use the factory already deployed on bsc
        ////////////////////////////////////////////////////////
        vm.selectFork(bscLiveForkId);
        Create3Factory bscFactory = Create3Factory(Create3FactoryConstants.EXPECTED_FACTORY);
        // make sure we are talking to the real on-chain factory and not a locally deployed one
        assertEq(
            address(bscFactory).codehash,
            Create3FactoryConstants.EXPECTED_FACTORY_CODEHASH,
            "factory on bsc fork does not have the expected codehash"
        );
        assertTrue(bscFactory.isUserWhitelisted(deployer), "deployer not whitelisted on bsc");

        // on-chain computeAddress uses the KECCAK256_PROXY_CHILD_BYTECODE baked into the bsc factory
        assertEq(
            bscFactory.computeAddress(Create3FactoryConstants.SANITY_SALT),
            Create3FactoryConstants.EXPECTED_SANITY_ADDRESS,
            "bsc computeAddress(SANITY_SALT) mismatch"
        );
        address bscExpected = bscFactory.computeAddress(salt);
        assertEq(bscExpected.code.length, 0, "salt already used on bsc, pick another salt");

        vm.prank(deployer);
        address bscDeployed = bscFactory.deploy(salt, creationCode, creationCodeHash, 0, new bytes(0), 0);
        assertEq(bscDeployed, bscExpected);
        assertEq(MockERC20(bscDeployed).name(), "Pancake Test Token");
        assertEq(MockERC20(bscDeployed).symbol(), "PTT");
        assertEq(MockERC20(bscDeployed).balanceOf(holder), 1e24);

        ////////////////////////////////////////////////////////
        // Step 2: second bsc fork, wipe the on-chain factory and replay the original deployment with the local build
        ////////////////////////////////////////////////////////
        vm.selectFork(bscReplayForkId);
        assertEq(
            Create3FactoryConstants.EXPECTED_FACTORY.codehash,
            Create3FactoryConstants.EXPECTED_FACTORY_CODEHASH,
            "second fork should start from the on-chain factory"
        );
        vm.etch(Create3FactoryConstants.EXPECTED_FACTORY, new bytes(0));
        vm.resetNonce(Create3FactoryConstants.EXPECTED_FACTORY);
        vm.setNonceUnsafe(deployer, 0);
        assertEq(Create3FactoryConstants.EXPECTED_FACTORY.code.length, 0, "factory should have been wiped");
        assertEq(vm.getNonce(deployer), 0, "deployer nonce must be 0");

        vm.prank(deployer);
        Create3Factory localFactory = new Create3Factory();
        assertEq(address(localFactory), Create3FactoryConstants.EXPECTED_FACTORY, "local factory address mismatch");
        assertEq(localFactory.computeAddress(salt), bscExpected, "local computeAddress mismatch with bsc");

        vm.prank(deployer);
        address localDeployed = localFactory.deploy(salt, creationCode, creationCodeHash, 0, new bytes(0), 0);
        assertEq(MockERC20(localDeployed).name(), "Pancake Test Token");
        assertEq(MockERC20(localDeployed).symbol(), "PTT");
        assertEq(MockERC20(localDeployed).balanceOf(holder), 1e24);

        // assert: same address from the local build and the factory live on bsc
        assertEq(localDeployed, bscDeployed, "ERC20 address mismatch between local build and bsc");
    }
}
