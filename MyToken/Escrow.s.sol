// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Escrow} from "../src/Escrow.sol";
import {MyToken} from "../src/MyToken.sol";

/// @notice Deploys the (single, shared) Escrow contract. Because Escrow
/// supports unlimited simultaneous deals, you deploy it once and then open
/// as many `deposit()` calls against it as you like — you do NOT redeploy
/// per deal. This script optionally opens one example deposit if
/// TOKEN_ADDRESS / RECIPIENT / AMOUNT env vars are set, to prove the wiring
/// end-to-end; the contract itself works the same with zero, one, or many
/// open deals.
///
///   TOKEN_ADDRESS=0x... RECIPIENT=0x... AMOUNT=1000000000000000000 \
///     forge script script/Escrow.s.sol:EscrowScript \
///     --rpc-url sepolia --account deployer --broadcast --verify
contract EscrowScript is Script {
    function run() external returns (Escrow escrow) {
        vm.startBroadcast();

        escrow = new Escrow();

        vm.stopBroadcast();

        console.log("Escrow deployed at:", address(escrow));

        // Optional: open one example deal against the token you deployed
        // separately with MyToken.s.sol, using the deployer as both
        // depositor and arbiter (release-to-self-controlled deal).
        try vm.envAddress("TOKEN_ADDRESS") returns (address tokenAddress) {
            address recipient = vm.envAddress("RECIPIENT");
            uint256 amount = vm.envUint("AMOUNT");

            vm.startBroadcast();
            MyToken(tokenAddress).approve(address(escrow), amount);
            uint256 escrowId = escrow.deposit(tokenAddress, recipient, msg.sender, amount);
            vm.stopBroadcast();

            console.log("Opened escrow id: ", escrowId);
        } catch {
            console.log("No TOKEN_ADDRESS/RECIPIENT/AMOUNT set — skipped opening an example deal.");
        }
    }
}
