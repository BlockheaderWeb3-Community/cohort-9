// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

contract IncrementScript is Script {
    address a = 0xeE9970bcfc2af7CfE0fa42fbFE91Bbce37728f16;

    function run() public {
        vm.startBroadcast();
        Counter(a).increment();
        console.log("Increment Successful");
        vm.stopBroadcast();
    }
}
