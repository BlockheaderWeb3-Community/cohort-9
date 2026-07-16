// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {JayToken} from "../src/JayToken.sol";

contract JayTokenScript is Script {
    string constant NAME = "JayToken";
    string constant SYMBOL = "JAY";
    uint8 constant DECIMALS = 18;
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;

    function run() external returns (JayToken token) {
        vm.startBroadcast();

        token = new JayToken(NAME, SYMBOL, DECIMALS, INITIAL_SUPPLY);

        vm.stopBroadcast();

        console.log("Deployed at:      ", address(token));
        console.log("Name:             ", token.name());
        console.log("Symbol:           ", token.symbol());
        console.log("Initial supply:   ", token.totalSupply());
    }
}
