// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MyNFT} from "../src/MyNFT.sol";

contract DeployMyNFTScript is Script {
    string constant NAME   = "MyNFT";
    string constant SYMBOL = "MNFT";

    function run() external returns (MyNFT nft) {
        vm.startBroadcast();

        nft = new MyNFT(NAME, SYMBOL);
        nft.mint(msg.sender, 1);

        vm.stopBroadcast();

        console.log("Deployed at:  ", address(nft));
        console.log("Name:         ", nft.name());
        console.log("Symbol:       ", nft.symbol());
        console.log("Owner of #1:  ", nft.ownerOf(1));
    }
}
