// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from  "forge-std/Test.sol";
import "../src/Staking.sol";
import "../src/MyToken.sol";

contract StakingTest is Test {
    Staking public staking;
    MyErc20 public rewardToken;

    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    uint256 public constant LOCK_PERIOD = 7 days;
    uint256 public constant REWARD_RATE_BPS = 500; // 5%
    uint256 public constant INITIAL_SUPPLY = 1_000_000;
    //uint256 public constant REWARD_POOL = 10_000 ether;// why isthis IN ETH , the address should be given ther erc20 token instead
    uint256 public constant REWARD_POOL= 1_000_00;

    function setUp() public {
        vm.startPrank(owner);

        // deploy the reward token
        rewardToken = new MyErc20("Reward Token", "RWD", INITIAL_SUPPLY);

        // deploy the staking contract
        staking = new Staking(address(rewardToken), LOCK_PERIOD, REWARD_RATE_BPS);

        // fund the staking contract with my reward tokens
        rewardToken.transfer(address(staking), REWARD_POOL);

        vm.stopPrank();

        // give alice and bob some ETH to stake
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(owner, 10000 ether);
    }

    function test_IfDeploymentWorks() public view {
       uint256 Supply= rewardToken.totalSupply();
       console.log("Supply", Supply);

       uint256 reward_bal= rewardToken.balanceOf(address(staking));
       console.log("reward_bal", reward_bal);

       uint256 TokenBal= address(rewardToken).balance;

       console.log("TokenBal", TokenBal);

       assertEq(reward_bal, 100000);
       assertEq(Supply, 1000000);
       assertEq(TokenBal,9900000);
      assertEq(TokenBal - reward_bal,9900000);


    }


}
