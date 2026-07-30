// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TieredStaking} from "../src/TieredStaking.sol";
import {StakingNFT}    from "../src/StakingNFT.sol";

contract TieredStakingTest is Test {
    TieredStaking public staking;
    StakingNFT    public nft;

    address public deployer = makeAddr("deployer");
    address public alice    = makeAddr("alice");
    address public bob      = makeAddr("bob");

    function setUp() public {
        vm.prank(deployer);
        staking = new TieredStaking();
        nft     = staking.nft();

        vm.deal(alice, 200 ether);
        vm.deal(bob,   200 ether);
    }

    // ── tier tests ────────────────────────────────────────────────────────────

    function test_Tier1AssignedBelow10Eth() public {
        vm.prank(alice);
        staking.stake{value: 5 ether}(1 days);

        (uint256 amount,,, uint8 tier) = staking.stakes(alice);
        assertEq(amount, 5 ether);
        assertEq(tier, 1);
    }

    function test_Tier2AssignedAt10Eth() public {
        vm.prank(alice);
        staking.stake{value: 10 ether}(1 days);

        (,,, uint8 tier) = staking.stakes(alice);
        assertEq(tier, 2);
    }

    function test_Tier2AssignedBetween10And50Eth() public {
        vm.prank(alice);
        staking.stake{value: 25 ether}(1 days);

        (,,, uint8 tier) = staking.stakes(alice);
        assertEq(tier, 2);
    }

    function test_Tier3AssignedAt50Eth() public {
        vm.prank(alice);
        staking.stake{value: 50 ether}(1 days);

        (,,, uint8 tier) = staking.stakes(alice);
        assertEq(tier, 3);
    }

    function test_Tier3AssignedAbove50Eth() public {
        vm.prank(alice);
        staking.stake{value: 100 ether}(1 days);

        (,,, uint8 tier) = staking.stakes(alice);
        assertEq(tier, 3);
    }

    // ── NFT tests ─────────────────────────────────────────────────────────────

    function test_NFTMintedOnStake() public {
        vm.prank(alice);
        staking.stake{value: 5 ether}(1 days);

        (,, uint256 nftTokenId,) = staking.stakes(alice);
        assertEq(nft.ownerOf(nftTokenId), alice);
        assertEq(nft.tokenTier(nftTokenId), 1);
        assertEq(nft.balanceOf(alice), 1);
    }

    // ── lock time tests ───────────────────────────────────────────────────────

    function test_LockedUntilSetCorrectly() public {
        vm.prank(alice);
        staking.stake{value: 1 ether}(30 days);

        (, uint256 lockedUntil,,) = staking.stakes(alice);
        assertEq(lockedUntil, block.timestamp + 30 days);
    }

    function test_RevertIfLockTooShort() public {
        vm.prank(alice);
        vm.expectRevert("Minimum lock is 1 day");
        staking.stake{value: 1 ether}(1 hours);
    }

    function test_RevertIfLockTooLong() public {
        vm.prank(alice);
        vm.expectRevert("Maximum lock is 730 days");
        staking.stake{value: 1 ether}(731 days);
    }

    function test_RevertWithdrawWhileLocked() public {
        vm.prank(alice);
        staking.stake{value: 1 ether}(7 days);

        vm.prank(alice);
        vm.expectRevert("Stake is still locked");
        staking.withdraw();
    }

    // ── normal withdrawal tests ───────────────────────────────────────────────

    function test_WithdrawAfterLockReturnsFullAmount() public {
        vm.prank(alice);
        staking.stake{value: 5 ether}(1 days);

        uint256 balanceBefore = alice.balance;

        vm.warp(block.timestamp + 1 days + 1);

        vm.prank(alice);
        staking.withdraw();

        assertEq(alice.balance, balanceBefore + 5 ether);
    }

    function test_WithdrawBurnsNFT() public {
        vm.prank(alice);
        staking.stake{value: 5 ether}(1 days);

        (,, uint256 nftTokenId,) = staking.stakes(alice);

        vm.warp(block.timestamp + 1 days + 1);
        vm.prank(alice);
        staking.withdraw();

        // NFT is burned - OpenZeppelin reverts when you query a burned token
        vm.expectRevert();
        nft.ownerOf(nftTokenId);

        assertEq(nft.balanceOf(alice), 0);
    }

    function test_WithdrawClearsStake() public {
        vm.prank(alice);
        staking.stake{value: 5 ether}(1 days);

        vm.warp(block.timestamp + 1 days + 1);
        vm.prank(alice);
        staking.withdraw();

        (uint256 amount,,,) = staking.stakes(alice);
        assertEq(amount, 0);
    }

    // ── emergency withdrawal tests ────────────────────────────────────────────

    function test_EmergencyWithdrawCharges10PercentPenalty() public {
        vm.prank(alice);
        staking.stake{value: 10 ether}(7 days);

        uint256 aliceBefore  = alice.balance;
        uint256 ownerBefore  = deployer.balance;

        vm.prank(alice);
        staking.emergencyWithdraw();

        assertEq(alice.balance,    aliceBefore + 9 ether); // got back 90%
        assertEq(deployer.balance, ownerBefore + 1 ether); // owner got 10%
    }

    function test_EmergencyWithdrawWorksWhileLocked() public {
        vm.prank(alice);
        staking.stake{value: 5 ether}(7 days); // lock not expired

        vm.prank(alice);
        staking.emergencyWithdraw(); // should NOT revert

        (uint256 amount,,,) = staking.stakes(alice);
        assertEq(amount, 0);
    }

    function test_EmergencyWithdrawBurnsNFT() public {
        vm.prank(alice);
        staking.stake{value: 5 ether}(7 days);

        (,, uint256 nftTokenId,) = staking.stakes(alice);

        vm.prank(alice);
        staking.emergencyWithdraw();

        vm.expectRevert();
        nft.ownerOf(nftTokenId);
    }

    // ── tokenURI tests ───────────────────────────────────────────────────────

    function test_BronzeURIForTier1() public {
        vm.prank(alice);
        staking.stake{value: 5 ether}(1 days);

        (,, uint256 nftTokenId,) = staking.stakes(alice);
        assertEq(nft.tokenURI(nftTokenId), nft.bronzeURI());
    }

    function test_SilverURIForTier2() public {
        vm.prank(alice);
        staking.stake{value: 10 ether}(1 days);

        (,, uint256 nftTokenId,) = staking.stakes(alice);
        assertEq(nft.tokenURI(nftTokenId), nft.silverURI());
    }

    function test_GoldURIForTier3() public {
        vm.prank(alice);
        staking.stake{value: 50 ether}(1 days);

        (,, uint256 nftTokenId,) = staking.stakes(alice);
        assertEq(nft.tokenURI(nftTokenId), nft.goldURI());
    }

    // ── revert tests ──────────────────────────────────────────────────────────

    function test_RevertOnZeroDeposit() public {
        vm.prank(alice);
        vm.expectRevert("You must send some ETH to stake");
        staking.stake{value: 0}(1 days);
    }

    function test_RevertDoubleStake() public {
        vm.startPrank(alice);
        staking.stake{value: 1 ether}(1 days);
        vm.expectRevert("Withdraw your current stake first");
        staking.stake{value: 1 ether}(1 days);
        vm.stopPrank();
    }

    function test_RevertWithdrawNoStake() public {
        vm.prank(alice);
        vm.expectRevert("No active stake");
        staking.withdraw();
    }

    function test_RevertEmergencyWithdrawNoStake() public {
        vm.prank(alice);
        vm.expectRevert("No active stake");
        staking.emergencyWithdraw();
    }
}
