// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ERC20NoReturnMock} from "@openzeppelin/contracts/mocks/token/ERC20NoReturnMock.sol";
import {ERC20ReturnFalseMock} from "@openzeppelin/contracts/mocks/token/ERC20ReturnFalseMock.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Test} from "forge-std/Test.sol";

import {ForwardingAddress} from "../src/ForwardingAddress.sol";
import {ForwardingAddressFactory} from "../src/ForwardingAddressFactory.sol";

contract NonPayableReceiver {}

contract ERC20NoReturn is ERC20NoReturnMock {
    constructor() ERC20("ERC20Mock", "E20M") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

contract ERC20ReturnFalse is ERC20ReturnFalseMock {
    constructor() ERC20("ERC20Mock", "E20M") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

contract ForwardingAddressFactoryTest is Test {
    ForwardingAddressFactory public factory;
    ERC20Mock public erc20Mock;
    ERC20NoReturn public erc20NoReturn;
    ERC20ReturnFalse public erc20ReturnFalse;

    function setUp() public {
        factory = new ForwardingAddressFactory();
        erc20Mock = new ERC20Mock();
        erc20NoReturn = new ERC20NoReturn();
        erc20ReturnFalse = new ERC20ReturnFalse();
    }

    function testFuzz_createForwardingAddress(bytes32 salt) public {
        (address receiver,) = makeAddrAndKey("receiver");

        address expectedAddr = factory.getAddress(receiver, salt);
        address actualAddress = address(factory.createForwardingAddress(payable(receiver), salt));

        assertEq(expectedAddr, actualAddress);
        assertEq(ForwardingAddress(payable(actualAddress)).receiver(), receiver);
    }

    function testFuzz_createForwardingAddressAlreadyDeployed(bytes32 salt) public {
        (address receiver,) = makeAddrAndKey("receiver");

        address expectedAddr = factory.getAddress(receiver, salt);
        factory.createForwardingAddress(payable(receiver), salt);
        address actualAddress = address(factory.createForwardingAddress(payable(receiver), salt));

        assertEq(expectedAddr, actualAddress);
    }

    function testFuzz_saltUniqueness(bytes32 salt1, bytes32 salt2) public {
        vm.assume(salt1 != salt2);
        (address receiver,) = makeAddrAndKey("receiver");

        ForwardingAddress f1 = factory.createForwardingAddress(payable(receiver), salt1);
        ForwardingAddress f2 = factory.createForwardingAddress(payable(receiver), salt2);

        assertNotEq(address(f1), address(f2));
        assertEq(f1.receiver(), f2.receiver());
    }

    function testFuzz_receiverUniqueness(bytes32 salt) public {
        (address r1,) = makeAddrAndKey("r1");
        (address r2,) = makeAddrAndKey("r2");
        vm.assume(r1 != r2);

        ForwardingAddress f1 = factory.createForwardingAddress(payable(r1), salt);
        ForwardingAddress f2 = factory.createForwardingAddress(payable(r2), salt);

        assertNotEq(address(f1), address(f2));
        assertNotEq(f1.receiver(), f2.receiver());
    }

    function testFuzz_sweepForETH(bytes32 salt, uint256 amount) public {
        (address receiver,) = makeAddrAndKey("receiver");

        address forwarder = factory.getAddress(receiver, salt);
        vm.deal(forwarder, amount);
        assertEq(receiver.balance, 0);
        assertEq(forwarder.balance, amount);

        address[] memory tokens = new address[](1);
        tokens[0] = address(0);
        factory.sweepFor(payable(receiver), salt, tokens);
        assertEq(receiver.balance, amount);
        assertEq(forwarder.balance, 0);
    }

    function testFuzz_sweepForFailedETHWithdraw(bytes32 salt, uint256 amount) public {
        address receiver = address(new NonPayableReceiver());

        address forwarder = factory.getAddress(receiver, salt);
        vm.deal(forwarder, amount);
        assertEq(receiver.balance, 0);
        assertEq(forwarder.balance, amount);

        address[] memory tokens = new address[](1);
        tokens[0] = address(0);
        vm.expectRevert(abi.encodeWithSelector(ForwardingAddress.FailedETHWithdraw.selector, receiver, tokens[0]));
        factory.sweepFor(payable(receiver), salt, tokens);
        assertEq(receiver.balance, 0);
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

    function testFuzz_sweepForERC20NoReturn(bytes32 salt, uint256 amount) public {
        (address receiver,) = makeAddrAndKey("receiver");

        address forwarder = factory.getAddress(receiver, salt);
        erc20NoReturn.mint(forwarder, amount);
        assertEq(IERC20(address(erc20NoReturn)).balanceOf(receiver), 0);
        assertEq(IERC20(address(erc20NoReturn)).balanceOf(forwarder), amount);

        address[] memory tokens = new address[](1);
        tokens[0] = address(erc20NoReturn);
        factory.sweepFor(payable(receiver), salt, tokens);
        assertEq(IERC20(address(erc20NoReturn)).balanceOf(receiver), amount);
        assertEq(IERC20(address(erc20NoReturn)).balanceOf(forwarder), 0);
    }

    function testFuzz_sweepForERC20ReturnFalse(bytes32 salt, uint256 amount) public {
        (address receiver,) = makeAddrAndKey("receiver");

        address forwarder = factory.getAddress(receiver, salt);
        erc20ReturnFalse.mint(forwarder, amount);
        assertEq(IERC20(address(erc20ReturnFalse)).balanceOf(receiver), 0);
        assertEq(IERC20(address(erc20ReturnFalse)).balanceOf(forwarder), amount);

        address[] memory tokens = new address[](1);
        tokens[0] = address(erc20ReturnFalse);
        vm.expectRevert(abi.encodeWithSelector(SafeERC20.SafeERC20FailedOperation.selector, tokens[0]));
        factory.sweepFor(payable(receiver), salt, tokens);
        assertEq(IERC20(address(erc20ReturnFalse)).balanceOf(receiver), 0);
        assertEq(IERC20(address(erc20ReturnFalse)).balanceOf(forwarder), amount);
    }

    function testFuzz_sweepForMulti(bytes32 salt, uint256 amount) public {
        (address receiver,) = makeAddrAndKey("receiver");

        address forwarder = factory.getAddress(receiver, salt);
        vm.deal(forwarder, amount);
        erc20Mock.mint(forwarder, amount);
        assertEq(receiver.balance, 0);
        assertEq(forwarder.balance, amount);
        assertEq(IERC20(address(erc20Mock)).balanceOf(receiver), 0);
        assertEq(IERC20(address(erc20Mock)).balanceOf(forwarder), amount);

        address[] memory tokens = new address[](2);
        tokens[0] = address(0);
        tokens[1] = address(erc20Mock);
        factory.sweepFor(payable(receiver), salt, tokens);
        assertEq(receiver.balance, amount);
        assertEq(forwarder.balance, 0);
        assertEq(IERC20(address(erc20Mock)).balanceOf(receiver), amount);
        assertEq(IERC20(address(erc20Mock)).balanceOf(forwarder), 0);
    }
}
