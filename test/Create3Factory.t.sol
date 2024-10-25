// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/src/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IAccessControlDefaultAdminRules} from
    "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";
import {Create3} from "../src/libraries/Create3.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {ICreate3Factory, Create3Factory} from "../src/Create3Factory.sol";
import {MockOwnerWithConstructorArgs} from "./mocks/MockOwnerWithConstructorArgs.sol";
import {MockAccessControlWithConstructorArgs} from "./mocks/MockAccessControlWithConstructorArgs.sol";
import {CustomizedProxyChild} from "../src/CustomizedProxyChild.sol";

contract Create3FactoryTest is Test, GasSnapshot {
    Create3Factory create3Factory;

    address pcsDeployer = makeAddr("pcsDeployer");
    address alice = makeAddr("alice");
    address expectedOwner = makeAddr("expectedOwner");

    function setUp() public {
        create3Factory = new Create3Factory();
        create3Factory.setWhitelistUser(pcsDeployer, true);
    }

    function test_Deploy_MockOwnerWithConstructorArgs() public {
        // 1. prepare salt and creation code
        bytes32 salt = bytes32(uint256(0x1234));
        bytes memory creationCode = abi.encodePacked(type(MockOwnerWithConstructorArgs).creationCode, abi.encode(42));

        // 2. prepare owner transfer payload
        bytes memory afterDeploymentExecutionPayload =
            abi.encodeWithSelector(Ownable.transferOwnership.selector, expectedOwner);

        // 3. make sure this contract has enough balance
        vm.deal(address(this), 1 ether);

        vm.expectEmit(true, true, true, true);
        emit Create3Factory.Deployed(create3Factory.computeAddress(salt), salt, keccak256(creationCode));

        // 4. deploy
        address deployed = create3Factory.deploy{value: 1 ether}(
            salt, creationCode, keccak256(creationCode), 1 ether, afterDeploymentExecutionPayload, 0 ether
        );

        // 5. verify constructor args, balance and owner
        assertEq(MockOwnerWithConstructorArgs(deployed).args(), 42);
        assertEq(deployed.balance, 1 ether);
        assertEq(Ownable(deployed).owner(), expectedOwner);
    }

    function test_Deploy_MockOwnerWithConstructorArgs_RevertWithCreationCodeHashMismatch() public {
        // 1. prepare salt and creation code
        bytes32 salt = bytes32(uint256(0x1234));
        bytes memory creationCode = abi.encodePacked(type(MockOwnerWithConstructorArgs).creationCode, abi.encode(42));

        // 2. prepare owner transfer payload
        bytes memory afterDeploymentExecutionPayload =
            abi.encodeWithSelector(Ownable.transferOwnership.selector, expectedOwner);

        // 3. make sure this contract has enough balance
        vm.deal(address(this), 1 ether);

        // 4. deploy
        vm.expectRevert(abi.encodeWithSelector(ICreate3Factory.CreationCodeHashMismatch.selector));
        create3Factory.deploy{value: 1 ether}(
            salt, creationCode, keccak256("anything else"), 1 ether, afterDeploymentExecutionPayload, 0 ether
        );
    }

    function test_Deploy_MockOwnerWithConstructorArgs_RevertWithFundsAmountMismatch() public {
        // 1. prepare salt and creation code
        bytes32 salt = bytes32(uint256(0x1234));
        bytes memory creationCode = abi.encodePacked(type(MockOwnerWithConstructorArgs).creationCode, abi.encode(42));

        // 2. prepare owner transfer payload
        bytes memory afterDeploymentExecutionPayload =
            abi.encodeWithSelector(Ownable.transferOwnership.selector, expectedOwner);

        // 3. make sure this contract has enough balance
        vm.deal(address(this), 1 ether);

        // 4. deploy
        vm.expectRevert(abi.encodeWithSelector(ICreate3Factory.FundsAmountMismatch.selector));
        create3Factory.deploy{value: 1 ether}(
            salt, creationCode, keccak256(creationCode), 1 ether, afterDeploymentExecutionPayload, 0.2 ether
        );
    }

    function test_Deploy_MockOwnerWithConstructorArgs_BubbleUpRevert() public {
        // 1. prepare salt and creation code
        bytes32 salt = bytes32(uint256(0x1234));
        bytes memory creationCode = abi.encodePacked(type(MockOwnerWithConstructorArgs).creationCode, abi.encode(42));

        // 2. prepare owner transfer payload
        // set target owner to address(0) to trigger revert
        bytes memory afterDeploymentExecutionPayload =
            abi.encodeWithSelector(Ownable.transferOwnership.selector, address(0));

        // 3. make sure this contract has enough balance
        vm.deal(address(this), 1 ether);

        // 4. deploy
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0)));
        create3Factory.deploy{value: 1 ether}(
            salt, creationCode, keccak256(creationCode), 1 ether, afterDeploymentExecutionPayload, 0 ether
        );
    }

    function test_Deploy_MockOwnerWithConstructorArgs_NotFromParent() public {
        // 1. prepare salt and creation code
        bytes32 salt = bytes32(uint256(0x1234));
        bytes memory creationCode = abi.encodePacked(type(MockOwnerWithConstructorArgs).creationCode, abi.encode(42));

        // 2. prepare owner transfer payload
        bytes memory afterDeploymentExecutionPayload =
            abi.encodeWithSelector(MockOwnerWithConstructorArgs.tryReEntryChildProxy.selector);

        // 3. make sure this contract has enough balance
        vm.deal(address(this), 1 ether);

        // 4. deploy
        vm.expectRevert(abi.encodeWithSelector(CustomizedProxyChild.NotFromParent.selector));
        create3Factory.deploy{value: 1 ether}(
            salt, creationCode, keccak256(creationCode), 1 ether, afterDeploymentExecutionPayload, 0 ether
        );
    }

    function test_Deploy_MockAccessControlWithConstructorArgs() public {
        // 1. prepare salt and creation code
        bytes32 salt = bytes32(uint256(0x1234));
        bytes memory creationCode =
            abi.encodePacked(type(MockAccessControlWithConstructorArgs).creationCode, abi.encode("hello world"));

        // 2. prepare defaultAdmin transfer payload
        bytes memory afterDeploymentExecutionPayload =
            abi.encodeWithSelector(IAccessControlDefaultAdminRules.beginDefaultAdminTransfer.selector, expectedOwner);

        // 3. make sure this contract has enough balance
        vm.deal(address(this), 2 ether);

        // 4. deploy
        address deployed = create3Factory.deploy{value: 2 ether}(
            salt, creationCode, keccak256(creationCode), 2 ether, afterDeploymentExecutionPayload, 0 ether
        );

        // 5. verify constructor args, balance and owner
        assertEq(MockAccessControlWithConstructorArgs(deployed).args(), "hello world");
        assertEq(deployed.balance, 2 ether);
        (address pendingAdmin, uint48 acceptSchedule) =
            MockAccessControlWithConstructorArgs(deployed).pendingDefaultAdmin();
        assertEq(pendingAdmin, expectedOwner);
        skip(acceptSchedule);
        vm.prank(expectedOwner);
        MockAccessControlWithConstructorArgs(deployed).acceptDefaultAdminTransfer();
        assertEq(MockAccessControlWithConstructorArgs(deployed).defaultAdmin(), expectedOwner);
    }

    function testFuzz_Deploy(bytes32 randomSalt, uint256 randomValue, uint256 randomArg) public {
        vm.assume(randomValue > 1 ether);
        // 1. prepare creation code
        bytes memory creationCode =
            abi.encodePacked(type(MockOwnerWithConstructorArgs).creationCode, abi.encode(randomArg));

        // 2. prepare owner transfer payload
        bytes memory afterDeploymentExecutionPayload =
            abi.encodeWithSelector(MockOwnerWithConstructorArgs.payMe.selector);

        // 3. make sure this contract has enough balance
        vm.deal(address(this), randomValue);

        // 4. deploy
        address deployed = create3Factory.deploy{value: randomValue}(
            randomSalt,
            creationCode,
            keccak256(creationCode),
            randomValue - 1 ether,
            afterDeploymentExecutionPayload,
            1 ether
        );

        // 5. verify constructor args, balance and owner
        assertEq(MockOwnerWithConstructorArgs(deployed).args(), randomArg);
        assertEq(deployed.balance, randomValue);
    }

    function testFuzz_Deploy_OnlySaltAffectedAddress(
        bytes32 randomSalt,
        uint256 randomValue1,
        uint256 randomArg1,
        uint256 randomValue2,
        string memory randomArg2
    ) public {
        vm.assume(randomValue1 != randomValue2);

        address newContractAddr1;
        address newContractAddr2;

        vm.deal(address(this), randomValue1);
        bytes memory creationCode =
            abi.encodePacked(type(MockOwnerWithConstructorArgs).creationCode, abi.encode(randomArg1));
        bytes memory afterDeploymentExecutionPayload =
            abi.encodeWithSelector(Ownable.transferOwnership.selector, expectedOwner);

        try Create3FactoryTest(this).tryDelpoy{value: randomValue1}(
            randomSalt, creationCode, randomValue1, afterDeploymentExecutionPayload, 0
        ) {
            revert("should revert!");
        } catch (bytes memory payload) {
            assembly {
                newContractAddr1 := mload(add(payload, 0x20))
            }
        }

        vm.deal(address(this), randomValue2);
        creationCode = abi.encodePacked(type(MockAccessControlWithConstructorArgs).creationCode, abi.encode(randomArg2));
        afterDeploymentExecutionPayload =
            abi.encodeWithSelector(IAccessControlDefaultAdminRules.beginDefaultAdminTransfer.selector, expectedOwner);
        try Create3FactoryTest(this).tryDelpoy{value: randomValue2}(
            randomSalt, creationCode, randomValue2, afterDeploymentExecutionPayload, 0
        ) {
            revert("should revert!");
        } catch (bytes memory payload) {
            assembly {
                newContractAddr2 := mload(add(payload, 0x20))
            }
        }

        assertNotEq(
            (type(MockOwnerWithConstructorArgs).creationCode), (type(MockAccessControlWithConstructorArgs).creationCode)
        );
        assertEq(newContractAddr1, newContractAddr2);
    }

    function test_Deploy_NotWhitelisted() public {
        vm.startPrank(alice);

        // deploy
        bytes memory creationCode = abi.encodePacked(type(MockOwnerWithConstructorArgs).creationCode, abi.encode(42));
        bytes32 salt = bytes32(uint256(0x1234));
        vm.expectRevert(ICreate3Factory.NotWhitelisted.selector);
        create3Factory.deploy(salt, creationCode, keccak256(creationCode), 0 ether, new bytes(0), 0 ether);
    }

    function test_SetWhitelistedUser() public {
        // before
        assertEq(create3Factory.isUserWhitelisted(alice), false);

        // set whitelisted
        vm.expectEmit();
        emit Create3Factory.SetWhitelist(alice, true);
        create3Factory.setWhitelistUser(alice, true);
        assertEq(create3Factory.isUserWhitelisted(alice), true);

        // set not whitelisted
        vm.expectEmit();
        emit Create3Factory.SetWhitelist(alice, false);
        create3Factory.setWhitelistUser(alice, false);
        assertEq(create3Factory.isUserWhitelisted(alice), false);
    }

    function test_SetWhitelistUser_OnlyOwner() public {
        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        create3Factory.setWhitelistUser(alice, true);
    }

    function tryDelpoy(
        bytes32 salt,
        bytes memory creationCode,
        uint256 creationFund,
        bytes calldata afterDeploymentExecutionPayload,
        uint256 afterDeploymentExecutionFund
    ) external payable {
        address addr = create3Factory.deploy{value: creationFund + afterDeploymentExecutionFund}(
            salt,
            creationCode,
            keccak256(creationCode),
            creationFund,
            afterDeploymentExecutionPayload,
            afterDeploymentExecutionFund
        );

        assembly ("memory-safe") {
            mstore(0, addr)
            revert(0, 32)
        }
    }
}
