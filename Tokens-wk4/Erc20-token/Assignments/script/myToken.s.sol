// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {MyToken} from "../src/myToken.sol"; // Double check this import matches your file name!



contract MyTokenScript is Script {
    string constant NAME = "MyToken";
    string constant SYMBOL = "MTK";
    uint8 constant DECIMALS = 18;
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;

    function run() external returns (MyToken token) {
        vm.startBroadcast();

        token = new MyToken(NAME, SYMBOL, DECIMALS, INITIAL_SUPPLY);

        vm.stopBroadcast();

        console.log("Token Deployed at:", address(token));
    }
}