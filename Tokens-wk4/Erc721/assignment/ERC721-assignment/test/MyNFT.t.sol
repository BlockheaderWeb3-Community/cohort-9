// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {IERC721} from "../src/interfaces/IERC721.sol";
import {IERC721Receiver} from "../src/interfaces/IERC721Receiver.sol";

/// @dev A contract that accepts ERC-721 tokens (returns the correct selector).
contract GoodReceiver is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

/// @dev A contract that rejects ERC-721 tokens (returns wrong selector).
contract BadReceiver is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(0xdeadbeef);
    }
}

/// @dev A contract that reverts on ERC-721 receipt.
contract RevertingReceiver {
    // Has no onERC721Received — a raw call will revert.
}

contract MyNFTTest is Test {
    MyNFT nft;

    address owner = address(this);         // test contract deploys, so it's the NFT owner
    address alice = makeAddr("alice");
    address bob   = makeAddr("bob");

    uint256 constant TOKEN_1 = 1;
    uint256 constant TOKEN_2 = 2;

    function setUp() public {
        nft = new MyNFT("MyNFT", "MNFT");
    }

    // Metadata

    function test_name() public view {
        assertEq(nft.name(), "MyNFT");
    }

    function test_symbol() public view {
        assertEq(nft.symbol(), "MNFT");
    }

    // supportsInterface (ERC-165)


    function test_supportsInterface_ERC165() public view {
        // bytes4(keccak256("supportsInterface(bytes4)")) == 0x01ffc9a7
        assertTrue(nft.supportsInterface(0x01ffc9a7));
    }

    function test_supportsInterface_ERC721() public view {
        // ERC-721 interface id == 0x80ac58cd
        assertTrue(nft.supportsInterface(0x80ac58cd));
    }

    function test_supportsInterface_ERC721Metadata() public view {
        // ERC-721 Metadata interface id == 0x5b5e139f
        assertTrue(nft.supportsInterface(0x5b5e139f));
    }

    function test_supportsInterface_falseForRandom() public view {
        assertFalse(nft.supportsInterface(0xdeadbeef));
    }

    // mint

    function test_mint_emitsTransferFromZero() public {
        vm.expectEmit(true, true, true, false);
        emit IERC721.Transfer(address(0), alice, TOKEN_1);
        nft.mint(alice, TOKEN_1);
    }

    function test_mint_incrementsBalance() public {
        nft.mint(alice, TOKEN_1);
        assertEq(nft.balanceOf(alice), 1);
    }

    function test_mint_setsOwner() public {
        nft.mint(alice, TOKEN_1);
        assertEq(nft.ownerOf(TOKEN_1), alice);
    }

    function test_mint_revertsOnZeroAddress() public {
        vm.expectRevert(MyNFT.ZeroAddress.selector);
        nft.mint(address(0), TOKEN_1);
    }

    function test_mint_revertsOnDuplicateTokenId() public {
        nft.mint(alice, TOKEN_1);
        vm.expectRevert(abi.encodeWithSelector(MyNFT.AlreadyExists.selector, TOKEN_1));
        nft.mint(bob, TOKEN_1);
    }

    function test_mint_onlyOwner() public {
        vm.prank(alice);
        vm.expectRevert(MyNFT.NotOwner.selector);
        nft.mint(alice, TOKEN_1);
    }

    // balanceOf

    function test_balanceOf_zeroInitially() public view {
        assertEq(nft.balanceOf(alice), 0);
    }

    function test_balanceOf_revertsZeroAddress() public {
        vm.expectRevert(MyNFT.ZeroAddress.selector);
        nft.balanceOf(address(0));
    }

    // ownerOf

    function test_ownerOf_revertsOnNonExistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(MyNFT.TokenDoesNotExist.selector, 999));
        nft.ownerOf(999);
    }

    // approve / getApproved


    function test_approve_byOwner() public {
        nft.mint(alice, TOKEN_1);
        vm.prank(alice);
        vm.expectEmit(true, true, true, false);
        emit IERC721.Approval(alice, bob, TOKEN_1);
        nft.approve(bob, TOKEN_1);
        assertEq(nft.getApproved(TOKEN_1), bob);
    }

    function test_approve_byOperator() public {
        nft.mint(alice, TOKEN_1);
        vm.prank(alice);
        nft.setApprovalForAll(bob, true);
        vm.prank(bob);
        nft.approve(address(this), TOKEN_1);
        assertEq(nft.getApproved(TOKEN_1), address(this));
    }

    function test_approve_revertsIfNotOwnerOrOperator() public {
        nft.mint(alice, TOKEN_1);
        vm.prank(bob);
        vm.expectRevert(MyNFT.NotOwnerOrApproved.selector);
        nft.approve(bob, TOKEN_1);
    }

    function test_approve_zeroAddressClearsApproval() public {
        nft.mint(alice, TOKEN_1);
        vm.startPrank(alice);
        nft.approve(bob, TOKEN_1);
        // Clearing approval with zero address must NOT revert (spec requirement)
        nft.approve(address(0), TOKEN_1);
        vm.stopPrank();
        assertEq(nft.getApproved(TOKEN_1), address(0));
    }

    function test_getApproved_revertsOnNonExistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(MyNFT.TokenDoesNotExist.selector, 999));
        nft.getApproved(999);
    }

    // ─────────────────────────────────────────────
    // setApprovalForAll / isApprovedForAll
    // ─────────────────────────────────────────────

    function test_setApprovalForAll_setsAndEmits() public {
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit IERC721.ApprovalForAll(alice, bob, true);
        nft.setApprovalForAll(bob, true);
        assertTrue(nft.isApprovedForAll(alice, bob));
    }

    function test_setApprovalForAll_revokes() public {
        vm.startPrank(alice);
        nft.setApprovalForAll(bob, true);
        nft.setApprovalForAll(bob, false);
        vm.stopPrank();
        assertFalse(nft.isApprovedForAll(alice, bob));
    }

    function test_setApprovalForAll_revertsZeroOperator() public {
        vm.expectRevert(MyNFT.ZeroAddress.selector);
        nft.setApprovalForAll(address(0), true);
    }

    // ─────────────────────────────────────────────
    // transferFrom
    // ─────────────────────────────────────────────

    function test_transferFrom_byOwner() public {
        nft.mint(alice, TOKEN_1);
        vm.prank(alice);
        vm.expectEmit(true, true, true, false);
        emit IERC721.Transfer(alice, bob, TOKEN_1);
        nft.transferFrom(alice, bob, TOKEN_1);
        assertEq(nft.ownerOf(TOKEN_1), bob);
        assertEq(nft.balanceOf(alice), 0);
        assertEq(nft.balanceOf(bob), 1);
    }

    function test_transferFrom_byApprovedAddress() public {
        nft.mint(alice, TOKEN_1);
        vm.prank(alice);
        nft.approve(bob, TOKEN_1);
        vm.prank(bob);
        nft.transferFrom(alice, address(this), TOKEN_1);
        assertEq(nft.ownerOf(TOKEN_1), address(this));
    }

    function test_transferFrom_byOperator() public {
        nft.mint(alice, TOKEN_1);
        vm.prank(alice);
        nft.setApprovalForAll(bob, true);
        vm.prank(bob);
        nft.transferFrom(alice, address(this), TOKEN_1);
        assertEq(nft.ownerOf(TOKEN_1), address(this));
    }

    function test_transferFrom_clearsApproval() public {
        nft.mint(alice, TOKEN_1);
        vm.prank(alice);
        nft.approve(bob, TOKEN_1);
        vm.prank(alice);
        nft.transferFrom(alice, address(this), TOKEN_1);
        assertEq(nft.getApproved(TOKEN_1), address(0));
    }

    function test_transferFrom_revertsIfNotAuthorized() public {
        nft.mint(alice, TOKEN_1);
        vm.prank(bob);
        vm.expectRevert(MyNFT.NotOwnerOrApproved.selector);
        nft.transferFrom(alice, bob, TOKEN_1);
    }

    function test_transferFrom_revertsToZeroAddress() public {
        nft.mint(alice, TOKEN_1);
        vm.prank(alice);
        vm.expectRevert(MyNFT.TransferToZeroAddress.selector);
        nft.transferFrom(alice, address(0), TOKEN_1);
    }

    function test_transferFrom_revertsFromWrongOwner() public {
        nft.mint(alice, TOKEN_1);
        // bob tries to transfer token from alice to himself, but says from=bob
        vm.prank(alice);
        nft.setApprovalForAll(bob, true);
        vm.prank(bob);
        vm.expectRevert(MyNFT.NotOwner.selector);
        nft.transferFrom(bob, alice, TOKEN_1);
    }

    // ─────────────────────────────────────────────
    // safeTransferFrom
    // ─────────────────────────────────────────────

    function test_safeTransferFrom_toEOA() public {
        nft.mint(alice, TOKEN_1);
        vm.prank(alice);
        nft.safeTransferFrom(alice, bob, TOKEN_1);
        assertEq(nft.ownerOf(TOKEN_1), bob);
    }

    function test_safeTransferFrom_toGoodReceiver() public {
        GoodReceiver receiver = new GoodReceiver();
        nft.mint(alice, TOKEN_1);
        vm.prank(alice);
        nft.safeTransferFrom(alice, address(receiver), TOKEN_1);
        assertEq(nft.ownerOf(TOKEN_1), address(receiver));
    }

    function test_safeTransferFrom_toBadReceiver_reverts() public {
        BadReceiver receiver = new BadReceiver();
        nft.mint(alice, TOKEN_1);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(MyNFT.InvalidReceiver.selector, address(receiver)));
        nft.safeTransferFrom(alice, address(receiver), TOKEN_1);
    }

    function test_safeTransferFrom_toRevertingReceiver_reverts() public {
        RevertingReceiver receiver = new RevertingReceiver();
        nft.mint(alice, TOKEN_1);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(MyNFT.InvalidReceiver.selector, address(receiver)));
        nft.safeTransferFrom(alice, address(receiver), TOKEN_1);
    }

    function test_safeTransferFrom_withData() public {
        GoodReceiver receiver = new GoodReceiver();
        nft.mint(alice, TOKEN_1);
        vm.prank(alice);
        nft.safeTransferFrom(alice, address(receiver), TOKEN_1, "hello");
        assertEq(nft.ownerOf(TOKEN_1), address(receiver));
    }

    // ─────────────────────────────────────────────
    // tokenURI
    // ─────────────────────────────────────────────

    function test_tokenURI_returnsForExistingToken() public {
        nft.mint(alice, TOKEN_1);
        string memory uri = nft.tokenURI(TOKEN_1);
        assertEq(uri, "https://example.com/metadata/1");
    }

    function test_tokenURI_revertsForNonExistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(MyNFT.TokenDoesNotExist.selector, 999));
        nft.tokenURI(999);
    }
}
