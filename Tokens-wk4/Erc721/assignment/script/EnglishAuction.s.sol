// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {EnglishAuction} from "../src/EnglishAuction.sol";
import {SimpleNFT} from "../src/SimpleNFT.sol";

contract EnglishAuctionScript is Script {
    uint256 constant RESERVE_PRICE = 0.01 ether;
    uint256 constant DURATION = 1 hours;

    function run(address nftAddress, uint256 tokenId) external returns (EnglishAuction auction) {
        vm.startBroadcast();

        SimpleNFT nft = SimpleNFT(nftAddress);
        auction = new EnglishAuction(nftAddress);

        nft.approve(address(auction), tokenId);
        auction.list(tokenId, RESERVE_PRICE, DURATION);

        vm.stopBroadcast();

        console.log("Auction deployed at:", address(auction));
        console.log("Listed tokenId:     ", tokenId);
        console.log("Reserve price (wei):", RESERVE_PRICE);
        console.log("Ends at (timestamp):", auction.endTime());
    }
}
