// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ClassworkToken} from "../src/classworkToken.sol";
import {ClassworkEscrow} from "../src/classworkEscrow.sol";

contract DeployEscrow is Script {
    function run() external {
        // 1. Fetch your deployer private key safely from the environment configuration
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // 2. Start broadcasting the deployment transactions to the blockchain
        vm.startBroadcast(deployerPrivateKey);

        // 3. Deploy the ERC-1155 custom token contract first
        ClassworkToken token = new ClassworkToken();
        console.log("ClassworkToken successfully deployed at:", address(token));

        // Define setup parameters for the Escrow system
        address buyer = vm.addr(deployerPrivateKey); // Sets you (the deployer) as the buyer
        address escrowAgent = 0x95222290DD7278Aa3ddd389Cc1E1d165CC4BAfe5; // Replace with your tutor's/agent's address

        // 4. Deploy the Escrow contract, linking it directly to the newly deployed token
        ClassworkEscrow escrow = new ClassworkEscrow(buyer, escrowAgent, address(token));
        console.log("ClassworkEscrow successfully deployed at:", address(escrow));

        // 5. CRITICAL AUTHORIZATION STEP: Tell the Token that this Escrow is allowed to burn items
        token.setManager(address(escrow), true);
        console.log("Authorization complete: Escrow is now a registered Token Manager.");

        vm.stopBroadcast();
    }
}