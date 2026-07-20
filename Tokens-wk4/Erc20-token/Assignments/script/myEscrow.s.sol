// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {MyEscrow} from "../src/myEscrow.sol";

contract MyEscrowScript is Script {
    // NOTE: Once we deploy MyToken, we will copy its address and paste it here!
    address constant TOKEN_ADDRESS = 0xEC0c651983F8bC8cbACcFB0A12A67a2F38e1eF24; 

    function run() external returns (MyEscrow escrow) {
        vm.startBroadcast();

        // Only passes the token address to the constructor now!
        escrow = new MyEscrow(TOKEN_ADDRESS);

        vm.stopBroadcast();

        console.log("Escrow Deployed at:", address(escrow));
    }
}