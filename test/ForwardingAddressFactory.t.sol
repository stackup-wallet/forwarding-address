// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Test} from "forge-std/Test.sol";

import {ForwardingAddress} from "../src/ForwardingAddress.sol";
import {ForwardingAddressFactory} from "../src/ForwardingAddressFactory.sol";

contract ForwardingAddressFactoryTest is Test {
    ForwardingAddressFactory public factory;
    ERC20Mock public erc20Mock;

    function setUp() public {
        factory = new ForwardingAddressFactory();
        erc20Mock = new ERC20Mock();
    }

    function testFuzz_createForwardingAddress(bytes32 salt) public {
        (address receiver,) = makeAddrAndKey("receiver");

        address expectedAddr = factory.getAddress(receiver, salt);
        address actualAddress = address(factory.createForwardingAddress(payable(receiver), salt));

        assertEq(expectedAddr, actualAddress);
    }

    function testFuzz_createForwardingAddressAlreadyDeployed(bytes32 salt) public {
        (address receiver,) = makeAddrAndKey("receiver");

        address expectedAddr = factory.getAddress(receiver, salt);
        factory.createForwardingAddress(payable(receiver), salt);
        address actualAddress = address(factory.createForwardingAddress(payable(receiver), salt));

        assertEq(expectedAddr, actualAddress);
    }

    function testFuzz_sweepForETH(bytes32 salt, uint256 amount) public {
        (address receiver,) = makeAddrAndKey("receiver");

        address forwarder = factory.getAddress(receiver, salt);
        uint256 initBalance = receiver.balance;
        vm.deal(forwarder, amount);
        assertEq(receiver.balance, initBalance);
        assertEq(forwarder.balance, amount);

        address[] memory tokens = new address[](1);
        tokens[0] = address(0);
        factory.sweepFor(payable(receiver), salt, tokens);
        assertEq(receiver.balance, initBalance + amount);
        assertEq(forwarder.balance, 0);
    }

    function testFuzz_sweepForFailedETHWithdraw(bytes32 salt, uint256 amount) public {
        // create2Deployer address, a known non payable contract
        address receiver = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

        address forwarder = factory.getAddress(receiver, salt);
        uint256 initBalance = receiver.balance;
        vm.deal(forwarder, amount);
        assertEq(receiver.balance, initBalance);
        assertEq(forwarder.balance, amount);

        address[] memory tokens = new address[](1);
        tokens[0] = address(0);
        vm.expectRevert(abi.encodeWithSelector(ForwardingAddress.FailedETHWithdraw.selector, receiver, tokens[0]));
        factory.sweepFor(payable(receiver), salt, tokens);
        assertEq(receiver.balance, initBalance);
        assertEq(forwarder.balance, amount);
    }

    function testFuzz_sweepForERC20(bytes32 salt, uint256 amount) public {
        (address receiver,) = makeAddrAndKey("receiver");

        address forwarder = factory.getAddress(receiver, salt);
        erc20Mock.mint(forwarder, amount);
        assertEq(IERC20(address(erc20Mock)).balanceOf(receiver), 0);
        assertEq(IERC20(address(erc20Mock)).balanceOf(forwarder), amount);

        address[] memory tokens = new address[](1);
        tokens[0] = address(erc20Mock);
        factory.sweepFor(payable(receiver), salt, tokens);
        assertEq(IERC20(address(erc20Mock)).balanceOf(receiver), amount);
        assertEq(IERC20(address(erc20Mock)).balanceOf(forwarder), 0);
    }

    function testFuzz_sweepForMulti(bytes32 salt, uint256 amount) public {
        (address receiver,) = makeAddrAndKey("receiver");

        address forwarder = factory.getAddress(receiver, salt);
        uint256 initBalance = receiver.balance;
        vm.deal(forwarder, amount);
        erc20Mock.mint(forwarder, amount);
        assertEq(receiver.balance, initBalance);
        assertEq(forwarder.balance, amount);
        assertEq(IERC20(address(erc20Mock)).balanceOf(receiver), 0);
        assertEq(IERC20(address(erc20Mock)).balanceOf(forwarder), amount);

        address[] memory tokens = new address[](2);
        tokens[0] = address(0);
        tokens[1] = address(erc20Mock);
        factory.sweepFor(payable(receiver), salt, tokens);
        assertEq(receiver.balance, initBalance + amount);
        assertEq(forwarder.balance, 0);
        assertEq(IERC20(address(erc20Mock)).balanceOf(receiver), amount);
        assertEq(IERC20(address(erc20Mock)).balanceOf(forwarder), 0);
    }
}
