// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MyEscrow} from "../src/myEscrow.sol";

contract MyEscrowScript is Script {
    
    address constant TOKEN_ADDRESS = 0x0000000000000000000000000000000000000000;
    
    
    address constant RECIPIENT_ADDRESS = 0x1111111111111111111111111111111111111111;
    address constant ARBITER_ADDRESS = 0x2222222222222222222222222222222222222222;
    
    // Escrowing 100 tokens
    uint256 constant ESCROW_AMOUNT = 100 * 10 ** 18;

    function run() external returns (MyEscrow escrow) {
        address tokenAddress = 0x425370F8AB434dCAed084215c367d53BBF47b622;
        address recipientAddress = 0x41648dE45Cc4D0172beCd4Db0A0A0b459C383705;
        address arbiterAddress = 0xCAFc5f0a599475C61f700fF02A11B5647c188fcd;
        
        // 0.0049 tokens (less than 0.005)
        uint256 escrowAmount = 0.00049 * 10 ** 18; 

        vm.startBroadcast();
        escrow = new MyEscrow(tokenAddress, recipientAddress, arbiterAddress, escrowAmount);
        vm.stopBroadcast();

        console.log("Escrow deployed at: ", address(escrow));
    }
}