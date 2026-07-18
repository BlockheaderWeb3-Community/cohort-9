// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TokenEscrow} from "../src/TokenEscrow.sol";

/// @dev Deployment parameters that aren't secrets but still shouldn't be
///      hardcoded are pulled from env vars (set in .env alongside RPC_URL /
///      ETHERSCAN_API_KEY). None of these are private keys.
///
///      TOKEN_ADDRESS   - address of the already-deployed MyToken
///      RECIPIENT       - who receives funds on release
///      ARBITER         - who is allowed to call release() (defaults to the deployer if unset)
///      ESCROW_AMOUNT   - amount of tokens (in wei units) the depositor will lock up
///      ESCROW_DURATION - seconds from now until the refund deadline
contract TokenEscrowScript is Script {
    function run() external returns (TokenEscrow escrow) {
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        address recipient = vm.envAddress("RECIPIENT");

        // Depositor is whoever broadcasts this script (--account deployer).
        address depositor = msg.sender;

        address arbiter;
        try vm.envAddress("ARBITER") returns (address a) {
            arbiter = a;
        } catch {
            arbiter = depositor;
        }

        uint256 amount = vm.envUint("ESCROW_AMOUNT");
        uint256 duration = vm.envUint("ESCROW_DURATION");
        uint256 deadline = block.timestamp + duration;

        vm.startBroadcast();

        escrow = new TokenEscrow(tokenAddress, depositor, recipient, arbiter, amount, deadline);

        vm.stopBroadcast();

        console.log("Escrow deployed at:", address(escrow));
        console.log("Token:             ", tokenAddress);
        console.log("Depositor:         ", depositor);
        console.log("Recipient:         ", recipient);
        console.log("Arbiter:           ", arbiter);
        console.log("Amount:            ", amount);
        console.log("Deadline (unix):   ", deadline);
    }
}
