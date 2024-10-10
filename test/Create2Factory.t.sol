// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Create2Factory} from "../src/Create2Factory.sol";
import {MockOwner} from "./mocks/MockOwner.sol";

contract Create2FactoryTest is Test {
    Create2Factory create2Factory;

    address pcsDeployer = makeAddr("pcsDeployer");
    address alice = makeAddr("alice");

    function setUp() public {
        create2Factory = new Create2Factory();
        create2Factory.setWhitelistUser(pcsDeployer, true);
    }

    function test_Deploy_differentNonce(uint64 nonce) public {
        vm.setNonce(pcsDeployer, nonce);
        vm.startPrank(pcsDeployer);

        // deploy
        bytes memory creationCode = type(MockOwner).creationCode;
        bytes32 salt = bytes32(uint256(0x1234));
        address deployed = create2Factory.deploy(salt, creationCode);

        // verify
        address expectedDeployed = create2Factory.getDeployed(pcsDeployer, salt, keccak256(creationCode));
        assertEq(deployed, expectedDeployed);
    }

    function test_Deploy_NotWhitelisted() public {
        vm.startPrank(alice);

        // deploy
        bytes memory creationCode = type(MockOwner).creationCode;
        bytes32 salt = bytes32(uint256(0x1234));
        vm.expectRevert("Create2Factory: caller is not whitelisted");
        address deployed = create2Factory.deploy(salt, creationCode);
    }

    function test_Execute() public {
        vm.startPrank(pcsDeployer);

        // deploy
        bytes memory creationCode = type(MockOwner).creationCode;
        bytes32 salt = bytes32(uint256(0x1234));
        address deployed = create2Factory.deploy(salt, creationCode);

        // verify
        MockOwner owner = MockOwner(deployed);
        assertEq(owner.owner(), address(create2Factory));

        // execute
        bytes memory data = abi.encodeWithSignature("transferOwnership(address)", pcsDeployer);
        create2Factory.execute(salt, keccak256(creationCode), data);
        assertEq(owner.owner(), pcsDeployer);
    }

    function test_Execute_Payable() public {
        vm.deal(pcsDeployer, 1 ether);
        vm.startPrank(pcsDeployer);

        // deploy
        bytes memory creationCode = type(MockOwner).creationCode;
        bytes32 salt = bytes32(uint256(0x1234));
        address deployed = create2Factory.deploy(salt, creationCode);

        // before
        assertEq(deployed.balance, 0);

        // execute
        bytes memory data = abi.encodeWithSignature("payableFunc()");
        create2Factory.execute{value: 1 ether}(salt, keccak256(creationCode), data);

        // after
        assertEq(deployed.balance, 1 ether);
    }

    function test_Execute_NotWhitelisted() public {
        // before deploy
        vm.startPrank(pcsDeployer);
        bytes memory creationCode = type(MockOwner).creationCode;
        bytes32 salt = bytes32(uint256(0x1234));
        vm.stopPrank();

        vm.prank(alice);
        vm.expectRevert("Create2Factory: caller is not whitelisted");
        bytes memory data = abi.encodeWithSignature("transferOwnership(address)", alice);
        create2Factory.execute(salt, keccak256(creationCode), data);
    }

    function test_SetWhitelistedUser() public {
        // before
        assertEq(create2Factory.isUserWhitelisted(alice), false);

        // set whitelisted
        vm.expectEmit();
        emit Create2Factory.SetWhitelist(alice, true);
        create2Factory.setWhitelistUser(alice, true);
        assertEq(create2Factory.isUserWhitelisted(alice), true);

        // set not whitelisted
        vm.expectEmit();
        emit Create2Factory.SetWhitelist(alice, false);
        create2Factory.setWhitelistUser(alice, false);
        assertEq(create2Factory.isUserWhitelisted(alice), false);
    }

    function test_SetWhitelistUser_OnlyOwner() public {
        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        create2Factory.setWhitelistUser(alice, true);
    }
}
