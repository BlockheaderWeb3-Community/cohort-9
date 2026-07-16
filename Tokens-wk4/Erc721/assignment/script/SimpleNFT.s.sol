// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {SimpleNFT} from "../src/SimpleNFT.sol";

contract SimpleNFTScript is Script {
    string constant NAME = "SimpleNFT";
    string constant SYMBOL = "SNFT";

    function run() external returns (SimpleNFT nft) {
        vm.startBroadcast();

        nft = new SimpleNFT(NAME, SYMBOL);
        nft.mint(msg.sender, 1); // mint token 1 so there's something to auction

        vm.stopBroadcast();

        console.log("Deployed at:      ", address(nft));
        console.log("Name:             ", nft.name());
        console.log("Symbol:           ", nft.symbol());
        console.log("Owner of #1:      ", nft.ownerOf(1));
    }
}
