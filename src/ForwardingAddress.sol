// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {Initializable} from "solady/utils/Initializable.sol";

contract ForwardingAddress is ReentrancyGuardTransient, Initializable {
    using SafeERC20 for IERC20;

    error FailedETHWithdraw(address receiver, address token);

    address payable public receiver;

    receive() external payable {}

    constructor() {
        _disableInitializers();
    }

    function initialize(address payable aReceiver) public initializer {
        receiver = aReceiver;
    }

    function sweep(address token) public nonReentrant {
        if (token == address(0)) {
            (bool success,) = receiver.call{value: address(this).balance}("");
            require(success, FailedETHWithdraw(receiver, token));
        } else {
            IERC20(token).safeTransfer(receiver, IERC20(token).balanceOf(address(this)));
        }
    }
}
