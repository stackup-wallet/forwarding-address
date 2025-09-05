// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {ForwardingAddressFactory} from "src/ForwardingAddressFactory.sol";

contract Deploy is Script {
    function run() public {
        vm.startBroadcast();
        ForwardingAddressFactory factory = new ForwardingAddressFactory{salt: 0}();
        vm.stopBroadcast();

        console.log("Deploying ForwardingAddressFactory at: %s", address(factory));
    }
}
