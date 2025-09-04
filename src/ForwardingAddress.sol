// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {Initializable} from "solady/utils/Initializable.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract ForwardingAddress is ReentrancyGuardTransient, Initializable {
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
            IERC20(token).transfer(receiver, IERC20(token).balanceOf(address(this)));
        }
    }
}
