// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {EnglishAuction} from "../src/EnglishAuction.sol";

contract DeployEnglishAuctionScript is Script {
    function run(address nftAddress, uint256 tokenId_) external returns (EnglishAuction auction) {
        vm.startBroadcast();

        auction = new EnglishAuction(nftAddress, tokenId_);

        MyNFT nft = MyNFT(nftAddress);
        nft.approve(address(auction), tokenId_);
        auction.startAuction(0.01 ether, 2 days);

        vm.stopBroadcast();

        console.log("Auction deployed at:", address(auction));
        console.log("Seller:             ", auction.seller());
        console.log("Reserve price:      ", auction.reservePrice());
        console.log("End time:           ", auction.endTime());
    }
}
