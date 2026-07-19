// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MyNFT} from "../src/MYNFT.sol";

/// @title Deploy MyNFT and mint the first token to the deployer.
/// @dev Run with:
///      forge script script/MyNFT.s.sol:MyNFTScript --rpc-url sepolia --broadcast --verify
contract MyNFTScript is Script {
    // Tweak these to taste.
    string constant NAME = "MyNFT";
    string constant SYMBOL = "MNFT";
    string constant BASE_URI = "ipfs://your-cid/"; // {baseURI}{tokenId} -> ipfs://your-cid/0
    uint256 constant MAX_SUPPLY = 100;

    function run() external returns (MyNFT nft, uint256 firstTokenId) {
        vm.startBroadcast();

        nft = new MyNFT(NAME, SYMBOL, BASE_URI, MAX_SUPPLY);

        // Mint token #0 to the deployer so there's something to auction.
        firstTokenId = nft.mint(msg.sender);

        vm.stopBroadcast();

        console.log("MyNFT deployed at: ", address(nft));
        console.log("Name:              ", nft.name());
        console.log("Symbol:            ", nft.symbol());
        console.log("Max supply:        ", nft.maxSupply());
        console.log("Minted tokenId:    ", firstTokenId);
        console.log("Owner of token:    ", nft.ownerOf(firstTokenId));
        console.log("tokenURI:          ", nft.tokenURI(firstTokenId));
    }
}
