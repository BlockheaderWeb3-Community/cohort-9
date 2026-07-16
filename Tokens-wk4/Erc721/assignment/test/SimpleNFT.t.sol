// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {SimpleNFT} from "../src/SimpleNFT.sol";
import {IERC721} from "../src/interfaces/IERC721.sol";
import {IERC721Metadata} from "../src/interfaces/IERC721Metadata.sol";
import {IERC165} from "../src/interfaces/IERC165.sol";
import {IERC721Receiver} from "../src/interfaces/IERC721Receiver.sol";

contract GoodReceiver is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

contract BadReceiver {
    // Intentionally does NOT implement onERC721Received.
}

contract SimpleNFTTest is Test {
    SimpleNFT nft;
    address owner = address(this);
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        nft = new SimpleNFT("SimpleNFT", "SNFT");
    }

    function test_nameAndSymbol() public view {
        assertEq(nft.name(), "SimpleNFT");
        assertEq(nft.symbol(), "SNFT");
    }

    function test_mintByOwner() public {
        nft.mint(alice, 1);
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.balanceOf(alice), 1);
    }

    function test_mintRevertsForNonOwner() public {
        vm.prank(alice);
        vm.expectRevert(SimpleNFT.NotOwner.selector);
        nft.mint(alice, 1);
    }

    function test_mintRevertsOnZeroAddress() public {
        vm.expectRevert(SimpleNFT.ZeroAddress.selector);
        nft.mint(address(0), 1);
    }

    function test_mintRevertsIfAlreadyMinted() public {
        nft.mint(alice, 1);
        vm.expectRevert(abi.encodeWithSelector(SimpleNFT.AlreadyMinted.selector, 1));
        nft.mint(bob, 1);
    }

    function test_ownerOfRevertsForNonexistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(SimpleNFT.TokenDoesNotExist.selector, 999));
        nft.ownerOf(999);
    }

    function test_getApprovedRevertsForNonexistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(SimpleNFT.TokenDoesNotExist.selector, 999));
        nft.getApproved(999);
    }

    function test_tokenURIRevertsForNonexistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(SimpleNFT.TokenDoesNotExist.selector, 999));
        nft.tokenURI(999);
    }

    function test_balanceOfRevertsForZeroAddress() public {
        vm.expectRevert(SimpleNFT.ZeroAddress.selector);
        nft.balanceOf(address(0));
    }

    function test_approveAndTransferFromByApprovedAddress() public {
        nft.mint(alice, 1);
        vm.prank(alice);
        nft.approve(bob, 1);
        assertEq(nft.getApproved(1), bob);

        vm.prank(bob);
        nft.transferFrom(alice, bob, 1);
        assertEq(nft.ownerOf(1), bob);
        // approval should be cleared after transfer
        assertEq(nft.getApproved(1), address(0));
    }

    function test_approveClearingWithZeroAddressNeverReverts() public {
        nft.mint(alice, 1);
        vm.startPrank(alice);
        nft.approve(bob, 1);
        nft.approve(address(0), 1); // must not revert
        vm.stopPrank();
        assertEq(nft.getApproved(1), address(0));
    }

    function test_setApprovalForAllAndTransferByOperator() public {
        nft.mint(alice, 1);
        vm.prank(alice);
        nft.setApprovalForAll(bob, true);
        assertTrue(nft.isApprovedForAll(alice, bob));

        vm.prank(bob);
        nft.transferFrom(alice, bob, 1);
        assertEq(nft.ownerOf(1), bob);
    }

    function test_transferFromRevertsForUnauthorizedCaller() public {
        nft.mint(alice, 1);
        vm.prank(bob);
        vm.expectRevert(SimpleNFT.NotTokenOwnerOrApproved.selector);
        nft.transferFrom(alice, bob, 1);
    }

    function test_transferFromRevertsToZeroAddress() public {
        nft.mint(alice, 1);
        vm.prank(alice);
        vm.expectRevert(SimpleNFT.ZeroAddress.selector);
        nft.transferFrom(alice, address(0), 1);
    }

    function test_safeTransferFromToGoodReceiver() public {
        GoodReceiver receiver = new GoodReceiver();
        nft.mint(alice, 1);
        vm.prank(alice);
        nft.safeTransferFrom(alice, address(receiver), 1);
        assertEq(nft.ownerOf(1), address(receiver));
    }

    function test_safeTransferFromRevertsOnBadReceiver() public {
        BadReceiver receiver = new BadReceiver();
        nft.mint(alice, 1);
        vm.prank(alice);
        vm.expectRevert(SimpleNFT.UnsafeRecipient.selector);
        nft.safeTransferFrom(alice, address(receiver), 1);
    }

    function test_plainTransferFromSkipsReceiverCheck() public {
        BadReceiver receiver = new BadReceiver();
        nft.mint(alice, 1);
        vm.prank(alice);
        nft.transferFrom(alice, address(receiver), 1); // should NOT revert
        assertEq(nft.ownerOf(1), address(receiver));
    }

    function test_supportsInterface() public view {
        assertTrue(nft.supportsInterface(type(IERC165).interfaceId));
        assertTrue(nft.supportsInterface(type(IERC721).interfaceId));
        assertTrue(nft.supportsInterface(type(IERC721Metadata).interfaceId));
        assertFalse(nft.supportsInterface(0xffffffff));
    }

    function test_transferEmitsEvent() public {
        nft.mint(alice, 1);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(alice, bob, 1);
        nft.transferFrom(alice, bob, 1);
    }
}
