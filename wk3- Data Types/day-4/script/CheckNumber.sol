// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

contract CheckNumberScript is Script {
    address a = 0xeE9970bcfc2af7CfE0fa42fbFE91Bbce37728f16;

    function run() public view {
        uint256 number = Counter(a).number();
        console.log("Number is", number);
    }
}
