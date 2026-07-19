// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MyNFT} from "../src/MYNFT.sol";
import {EnglishAuction} from "../src/Auction.sol";

/// @title Deploy a MyNFT, mint a token, and open an auction for it.
/// @dev Five plain steps, in order — nothing clever:
///      1. deploy the NFT
///      2. mint a token to ourselves (the seller)
///      3. deploy the auction, passing the NFT address and settings
///      4. approve the auction to move our token
///      5. call start() — the auction pulls the token into escrow
///
///      Run with:
///      forge script script/Auction.s.sol:AuctionScript --rpc-url sepolia --broadcast
contract AuctionScript is Script {
    string constant NAME = "MyNFT";
    string constant SYMBOL = "MNFT";
    string constant BASE_URI = "ipfs://your-cid/";
    uint256 constant MAX_SUPPLY = 100;

    uint256 constant RESERVE_PRICE = 0.01 ether;
    uint256 constant DURATION = 1 days;

    function run() external returns (MyNFT nft, EnglishAuction auction, uint256 tokenId) {
        vm.startBroadcast();

        // 1. Deploy the NFT collection.
        nft = new MyNFT(NAME, SYMBOL, BASE_URI, MAX_SUPPLY);

        // 2. Mint token #0 to ourselves — we are the seller.
        tokenId = nft.mint(msg.sender);

        // 3. Deploy the auction. Its constructor only stores settings; it does
        //    not touch the NFT yet, so this can't fail on a transfer.
        auction = new EnglishAuction(address(nft), tokenId, RESERVE_PRICE, DURATION);

        // 4. Approve the auction to move our token. It exists now, so we just
        //    use its real address — no prediction needed.
        nft.approve(address(auction), tokenId);

        // 5. Start the auction: it pulls the NFT into escrow and starts the clock.
        auction.start();

        vm.stopBroadcast();

        console.log("MyNFT deployed at:    ", address(nft));
        console.log("Auction deployed at:  ", address(auction));
        console.log("Token in escrow:      ", tokenId);
        console.log("NFT owner (escrow):   ", nft.ownerOf(tokenId));
        console.log("Seller:               ", auction.seller());
        console.log("Reserve price (wei):  ", auction.reservePrice());
        console.log("End time:             ", auction.endTime());
    }
}
