// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {LibClone} from "solady/utils/LibClone.sol";

import {ForwardingAddress} from "./ForwardingAddress.sol";

contract ForwardingAddressFactory is ReentrancyGuardTransient {
    ForwardingAddress public immutable implementation;

    constructor() {
        implementation = new ForwardingAddress();
    }

    function createForwardingAddress(address payable receiver, bytes32 salt) public returns (ForwardingAddress ret) {
        address addr = getAddress(receiver, salt);
        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return ForwardingAddress(payable(addr));
        }
        ret = ForwardingAddress(
            payable(LibClone.cloneDeterministic(address(implementation), keccak256(abi.encode(receiver, salt))))
        );
        ret.initialize(receiver);
    }

    function getAddress(address receiver, bytes32 salt) public view returns (address) {
        return LibClone.predictDeterministicAddress(
            address(implementation), keccak256(abi.encode(receiver, salt)), address(this)
        );
    }

    function sweepFor(address payable receiver, bytes32 salt, address[] calldata tokens) public nonReentrant {
        ForwardingAddress f = createForwardingAddress(receiver, salt);
        for (uint256 i = 0; i < tokens.length; i++) {
            f.sweep(tokens[i]);
        }
    }
}
