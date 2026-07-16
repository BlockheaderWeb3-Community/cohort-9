//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {JayEscrow} from "../src/JayEscrow.sol";

/// @notice Deploys JayEscrow, wiring it to an already-deployed JayToken.
///         Pass the token address via the TOKEN_ADDRESS env var:
///         TOKEN_ADDRESS=0x... forge script script/JayEscrow.s.sol:JayEscrowScript \
///           --rpc-url sepolia --account deployer --broadcast --verify
contract JayEscrowScript is Script {
    function run() external returns (JayEscrow escrow) {
        address token = vm.envAddress("TOKEN_ADDRESS");

        vm.startBroadcast();

        escrow = new JayEscrow(token);

        vm.stopBroadcast();

        console.log("Escrow deployed at:", address(escrow));
        console.log("Bound token:       ", address(escrow.token()));
    }
}
