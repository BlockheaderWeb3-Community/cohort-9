// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MyNFT, IERC721Receiver} from "../src/MyNFT.sol";

contract GoodReceiver is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract BadReceiver {
    // Deliberately does NOT implement onERC721Received.
}

contract MyNFTTest is Test {
    MyNFT nft;

    address deployer = address(this);
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address operator = makeAddr("operator");

    function setUp() public {
        nft = new MyNFT("MyNFT", "MNFT");
        nft.mint(alice, 1);
    }

    // ---- ERC-165 ----

    function test_supportsInterface() public view {
        assertTrue(nft.supportsInterface(0x01ffc9a7)); // ERC165
        assertTrue(nft.supportsInterface(0x80ac58cd)); // ERC721
        assertTrue(nft.supportsInterface(0x5b5e139f)); // ERC721Metadata
        assertFalse(nft.supportsInterface(0xffffffff));
    }

    // ---- existence / revert-on-nonexistent ----

    function test_ownerOfRevertsOnNonexistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(MyNFT.TokenDoesNotExist.selector, 999));
        nft.ownerOf(999);
    }

    function test_getApprovedRevertsOnNonexistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(MyNFT.TokenDoesNotExist.selector, 999));
        nft.getApproved(999);
    }

    function test_tokenURIRevertsOnNonexistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(MyNFT.TokenDoesNotExist.selector, 999));
        nft.tokenURI(999);
    }

    // ---- minting ----

    function test_onlyOwnerCanMint() public {
        vm.prank(alice);
        vm.expectRevert(MyNFT.NotOwner.selector);
        nft.mint(alice, 2);
    }

    function test_cannotMintExistingTokenId() public {
        vm.expectRevert(abi.encodeWithSelector(MyNFT.TokenAlreadyExists.selector, 1));
        nft.mint(bob, 1);
    }

    function test_cannotMintToZeroAddress() public {
        vm.expectRevert(MyNFT.ZeroAddress.selector);
        nft.mint(address(0), 2);
    }

    // ---- approvals ----

    function test_approveAndClearWithZeroAddress() public {
        vm.prank(alice);
        nft.approve(bob, 1);
        assertEq(nft.getApproved(1), bob);

        // Clearing an approval via address(0) must never revert.
        vm.prank(alice);
        nft.approve(address(0), 1);
        assertEq(nft.getApproved(1), address(0));
    }

    function test_setApprovalForAll() public {
        vm.prank(alice);
        nft.setApprovalForAll(operator, true);
        assertTrue(nft.isApprovedForAll(alice, operator));
    }

    // ---- transferFrom access control: owner OR approved OR operator ----

    function test_ownerCanTransfer() public {
        vm.prank(alice);
        nft.transferFrom(alice, bob, 1);
        assertEq(nft.ownerOf(1), bob);
    }

    function test_specificallyApprovedAddressCanTransfer() public {
        vm.prank(alice);
        nft.approve(bob, 1);

        vm.prank(bob);
        nft.transferFrom(alice, bob, 1);
        assertEq(nft.ownerOf(1), bob);
    }

    function test_operatorCanTransfer() public {
        vm.prank(alice);
        nft.setApprovalForAll(operator, true);

        vm.prank(operator);
        nft.transferFrom(alice, bob, 1);
        assertEq(nft.ownerOf(1), bob);
    }

    function test_strangerCannotTransfer() public {
        vm.prank(bob); // not owner, not approved, not operator
        vm.expectRevert(MyNFT.NotOwnerOrApproved.selector);
        nft.transferFrom(alice, bob, 1);
    }

    function test_approvalIsClearedAfterTransfer() public {
        vm.prank(alice);
        nft.approve(bob, 1);

        vm.prank(bob);
        nft.transferFrom(alice, bob, 1);

        assertEq(nft.getApproved(1), address(0));
    }

    // ---- safeTransferFrom ----

    function test_safeTransferToEOA() public {
        vm.prank(alice);
        nft.safeTransferFrom(alice, bob, 1);
        assertEq(nft.ownerOf(1), bob);
    }

    function test_safeTransferToGoodReceiverSucceeds() public {
        GoodReceiver good = new GoodReceiver();

        vm.prank(alice);
        nft.safeTransferFrom(alice, address(good), 1);
        assertEq(nft.ownerOf(1), address(good));
    }

    function test_safeTransferToBadReceiverReverts() public {
        BadReceiver bad = new BadReceiver();

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(MyNFT.UnsafeRecipient.selector, address(bad)));
        nft.safeTransferFrom(alice, address(bad), 1);
    }

    function test_plainTransferFromSkipsReceiverCheck() public {
        // Sanity check that transferFrom (unsafe) does NOT enforce the
        // onERC721Received hook the way safeTransferFrom does.
        BadReceiver bad = new BadReceiver();

        vm.prank(alice);
        nft.transferFrom(alice, address(bad), 1);
        assertEq(nft.ownerOf(1), address(bad));
    }
}
