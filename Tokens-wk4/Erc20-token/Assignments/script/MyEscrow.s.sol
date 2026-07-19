// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MultiEscrow} from "../src/MyEscrow.sol";

contract MyEscrowScript is Script {
    function run() external returns (MultiEscrow escrow) {
        vm.startBroadcast();

        // MultiEscrow has no constructor; individual escrows are created
        // later via createEscrow(seller, token, amount, deadline).
        escrow = new MultiEscrow();

        vm.stopBroadcast();

        console.log("Deployed at:      ", address(escrow));
        console.log("Next escrow id:   ", escrow.nextEscrowid());
    }
}
