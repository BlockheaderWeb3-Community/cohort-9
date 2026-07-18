// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {EnglishAuction} from "../src/EnglishAuction.sol";

/// @dev EnglishAuction's constructor pulls the NFT immediately via
///      transferFrom, which means the seller must approve the auction's
///      address *before* it exists. We compute the CREATE address the
///      broadcast will produce (deployer address + current nonce) and
///      approve that address first, in the same broadcast.
///
///      Env vars:
///        NFT_ADDRESS    - address of the already-deployed MyNFT
///        AUCTION_TOKEN_ID  - tokenId being auctioned (seller must own it)
///        RESERVE_PRICE  - minimum winning bid, in wei
///        AUCTION_DURATION - seconds the auction runs for
contract EnglishAuctionScript is Script {
    function run() external returns (EnglishAuction auction) {
        address nftAddress = vm.envAddress("NFT_ADDRESS");
        uint256 tokenId = vm.envUint("AUCTION_TOKEN_ID");
        uint256 reservePrice = vm.envUint("RESERVE_PRICE");
        uint256 duration = vm.envUint("AUCTION_DURATION");

        MyNFT nft = MyNFT(nftAddress);

        vm.startBroadcast();

        uint256 nonce = vm.getNonce(msg.sender);
        address predictedAuction = vm.computeCreateAddress(msg.sender, nonce);

        nft.approve(predictedAuction, tokenId);
        auction = new EnglishAuction(nftAddress, tokenId, reservePrice, duration);

        vm.stopBroadcast();

        require(address(auction) == predictedAuction, "address prediction mismatch");

        console.log("Auction deployed at:", address(auction));
        console.log("NFT:                ", nftAddress);
        console.log("Token id:           ", tokenId);
        console.log("Seller:             ", auction.seller());
        console.log("Reserve price:      ", reservePrice);
        console.log("End time (unix):    ", auction.endTime());
    }
}
