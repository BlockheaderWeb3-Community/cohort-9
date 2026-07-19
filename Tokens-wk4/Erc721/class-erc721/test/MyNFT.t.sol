// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {ERC721} from "../src/ERC721.sol";
import {IERC721Receiver} from "../src/interfaces/IERC721Receiver.sol";

/// @dev A contract that correctly implements the receiver hook.
contract GoodReceiver is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

/// @dev A contract that does NOT implement the receiver hook at all —
///      simulates the classic "NFT sent to a contract with no way out" case.
contract BadReceiver {}

/// @dev A contract that implements the hook but deliberately returns the
///      wrong value — must revert the transfer just as hard as BadReceiver.
contract WrongSelectorReceiver is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return 0xdeadbeef;
    }
}

contract MyNFTTest is Test {
    MyNFT internal nft;

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function setUp() public {
        vm.prank(owner);
        nft = new MyNFT("MyNFT", "MNFT", "https://example.com/metadata/", 1000);
    }

    // ── Minting ────────────────────────────────────────────────────────

    function test_mint_incrementsBalanceAndSetsOwner() public {
        vm.prank(owner);
        uint256 tokenId = nft.mint(alice);

        assertEq(tokenId, 0);
        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.balanceOf(alice), 1);
    }

    function test_mint_revertsForNonOwnerCaller() public {
        vm.prank(alice);
        vm.expectRevert(MyNFT.CallerNotOwner.selector);
        nft.mint(alice);
    }

    function test_mint_revertsAtMaxSupply() public {
        vm.prank(owner);
        MyNFT small = new MyNFT("Small", "SM", "uri/", 1);

        vm.prank(owner);
        small.mint(alice);

        vm.prank(owner);
        vm.expectRevert(MyNFT.MaxSupplyReached.selector);
        small.mint(bob);
    }

    // ── Ownership queries ──────────────────────────────────────────────

    function test_ownerOf_revertsForNonExistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(ERC721.NonExistentToken.selector, 42));
        nft.ownerOf(42);
    }

    function test_balanceOf_revertsForZeroAddress() public {
        vm.expectRevert(ERC721.ZeroAddress.selector);
        nft.balanceOf(address(0));
    }

    // ── transferFrom ───────────────────────────────────────────────────

    function test_transferFrom_movesTokenAndResetsApproval() public {
        vm.prank(owner);
        uint256 tokenId = nft.mint(alice);

        vm.prank(alice);
        nft.approve(bob, tokenId);
        assertEq(nft.getApproved(tokenId), bob);

        vm.prank(alice);
        nft.transferFrom(alice, bob, tokenId);

        assertEq(nft.ownerOf(tokenId), bob);
        assertEq(nft.balanceOf(alice), 0);eee
        assertEq(nft.balanceOf(bob), 1);
        // Approval must be cleared by the transfer itself.
        assertEq(nft.getApproved(tokenId), address(0));
    }

    function test_transferFrom_revertsIfCallerNotAuthorized() public {
        vm.prank(owner);
        uint256 tokenId = nft.mint(alice);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(ERC721.NotOwnerOrApproved.selector, bob, tokenId));
        nft.transferFrom(alice, bob, tokenId);
    }

    function test_transferFrom_revertsOnZeroAddressRecipient() public {
        vm.prank(owner);
        uint256 tokenId = nft.mint(alice);

        vm.prank(alice);
        vm.expectRevert(ERC721.TransferToZeroAddress.selector);
        nft.transferFrom(alice, address(0), tokenId);
    }

    function test_transferFrom_approvedAddressCanMove() public {
        vm.prank(owner);
        uint256 tokenId = nft.mint(alice);

        vm.prank(alice);
        nft.approve(bob, tokenId);

        vm.prank(bob);
        nft.transferFrom(alice, bob, tokenId);
        assertEq(nft.ownerOf(tokenId), bob);
    }

    function test_operator_canMoveAnyOwnedToken() public {
        vm.startPrank(owner);
        uint256 t1 = nft.mint(alice);
        uint256 t2 = nft.mint(alice);
        vm.stopPrank();

        vm.prank(alice);
        nft.setApprovalForAll(bob, true);

        vm.startPrank(bob);
        nft.transferFrom(alice, bob, t1);
        nft.transferFrom(alice, bob, t2);
        vm.stopPrank();

        assertEq(nft.balanceOf(bob), 2);
    }

    // ── safeTransferFrom + receiver hook ───────────────────────────────

    function test_safeTransferFrom_toEOA_succeeds() public {
        vm.prank(owner);
        uint256 tokenId = nft.mint(alice);

        vm.prank(alice);
        nft.safeTransferFrom(alice, bob, tokenId);
        assertEq(nft.ownerOf(tokenId), bob);
    }

    function test_safeTransferFrom_toGoodReceiver_succeeds() public {
        GoodReceiver good = new GoodReceiver();

        vm.prank(owner);
        uint256 tokenId = nft.mint(alice);

        vm.prank(alice);
        nft.safeTransferFrom(alice, address(good), tokenId);
        assertEq(nft.ownerOf(tokenId), address(good));
    }

    function test_safeTransferFrom_toBadReceiver_reverts() public {
        BadReceiver bad = new BadReceiver();

        vm.prank(owner);
        uint256 tokenId = nft.mint(alice);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ERC721.UnsafeRecipient.selector, address(bad)));
        nft.safeTransferFrom(alice, address(bad), tokenId);
    }

    function test_safeTransferFrom_toWrongSelectorReceiver_reverts() public {
        WrongSelectorReceiver wrong = new WrongSelectorReceiver();

        vm.prank(owner);
        uint256 tokenId = nft.mint(alice);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ERC721.UnsafeRecipient.selector, address(wrong)));
        nft.safeTransferFrom(alice, address(wrong), tokenId);
    }

    // ── Burning ─────────────────────────────────────────────────────────

    function test_burn_removesTokenAndDecrementsBalance() public {
        vm.prank(owner);
        uint256 tokenId = nft.mint(alice);

        vm.prank(alice);
        nft.burn(tokenId);

        assertEq(nft.balanceOf(alice), 0);
        vm.expectRevert(abi.encodeWithSelector(ERC721.NonExistentToken.selector, tokenId));
        nft.ownerOf(tokenId);
    }

    // ── Metadata ────────────────────────────────────────────────────────

    function test_tokenURI_concatenatesBaseURIAndId() public {
        vm.prank(owner);
        uint256 tokenId = nft.mint(alice);
        assertEq(nft.tokenURI(tokenId), "https://example.com/metadata/0");
    }

    function test_tokenURI_revertsForNonExistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(ERC721.NonExistentToken.selector, 99));
        nft.tokenURI(99);
    }

    // ── ERC165 ──────────────────────────────────────────────────────────

    function test_supportsInterface_erc721AndErc165() public {
        assertTrue(nft.supportsInterface(0x80ac58cd)); // IERC721
        assertTrue(nft.supportsInterface(0x01ffc9a7)); // IERC165
        assertTrue(nft.supportsInterface(0x5b5e139f)); // IERC721Metadata
        assertFalse(nft.supportsInterface(0xffffffff)); // reserved sentinel
    }

    // ── Fuzz ────────────────────────────────────────────────────────────

    function testFuzz_mintThenTransfer_ownershipIsConsistent(address to) public {
        vm.assume(to != address(0) && to.code.length == 0);

        vm.prank(owner);
        uint256 tokenId = nft.mint(alice);

        vm.prank(alice);
        nft.transferFrom(alice, to, tokenId);

        assertEq(nft.ownerOf(tokenId), to);
        assertEq(nft.balanceOf(alice), 0);
        assertEq(nft.balanceOf(to), 1);
    }
}
