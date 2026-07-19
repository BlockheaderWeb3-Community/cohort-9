// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenScript is Script {
   
    string constant NAME = "MyToken";
    string constant SYMBOL = "MTK";
    uint8 constant DECIMALS = 18;
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;

    function run() external returns (MyToken token) {
        vm.startBroadcast();

        token = new MyToken(NAME, SYMBOL, DECIMALS, INITIAL_SUPPLY);

        vm.stopBroadcast();

        console.log("Deployed at:      ", address(token));
        console.log("Name:             ", token.name());
        console.log("Symbol:           ", token.symbol());
        console.log("Decimals:         ", token.decimals());
        console.log("Initial supply:   ", token.totalSupply());
        console.log("Deployer balance: ", token.balanceOf(msg.sender));
    }
}
