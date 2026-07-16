// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MyToken} from "../src/fundz.sol";

contract FundzScript is Script {
    function run() external {
        vm.startBroadcast();
        
        // Define your token parameters
        string memory name = "MyToken";
        string memory symbol = "MTK";
        uint8 decimals = 18;
        uint256 initialSupply = 1_000_000 * 10 ** 18;

        // Pass those 4 arguments to the constructor
        MyToken token = new MyToken(name, symbol, decimals, initialSupply);
        
        vm.stopBroadcast();
        console.log("Token deployed at:", address(token));
    }
}