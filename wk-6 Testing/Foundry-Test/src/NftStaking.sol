// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {StakeReceipt} from "./MyNft.sol";


contract ETHStakingTiers is Ownable {
    // ============================================================
    //                          ERRORS
    // ============================================================
    error DepositBelowTier1(uint256 amount);
    error LockDurationMustBePositive();
    error StakeDoesNotExist(uint256 tokenId);
    error NotStakeOwner(uint256 tokenId, address caller);
    error LockNotYetElapsed(uint256 tokenId, uint256 lockEnd);
    error EthTransferFailed(address to, uint256 amount);

 
    event Staked(address indexed staker, uint256 indexed tokenId, uint256 amount, uint256 lockEnd, Tier tier);
    event Withdrawn(address indexed staker, uint256 indexed tokenId, uint256 principal, uint256 reward);
    event EmergencyDrain(address indexed owner, uint256 amount);



    /// @notice Tier1 = [1, 5) ETH, Tier2 = [5, 10) ETH, Tier3 = [10, inf) ETH
    enum Tier {
        None,
        Tier1,
        Tier2,
        Tier3
    }

    struct Stake {
        address owner;
        uint256 amount;
        uint256 lockEnd;
        Tier tier;
    }

    
    StakeReceipt public immutable stakeReceipt;

    mapping(uint256 tokenId => Stake) public stakes;

    /// @dev Reward rates in basis points (1 bps = 0.01%), paid once on matured withdrawal
    uint16 public constant TIER1_REWARD_BPS = 10;
    uint16 public constant TIER2_REWARD_BPS = 20;
    uint16 public constant TIER3_REWARD_BPS = 30;
    uint16 private constant BPS_DENOMINATOR = 10_000;


    /// @notice Deploys the StakeReceipt NFT and seeds the reward pool
    /// @param initialOwner Address that owns this contract and can trigger the emergency drain
    constructor(address initialOwner) payable Ownable(initialOwner) {
        stakeReceipt = new StakeReceipt(address(this));// wha
    }

  

    /// @notice Stakes ETH for a caller-chosen lock duration, minting a tier NFT receipt
    /// @param lockDuration Seconds from now until the stake matures
    function stake(uint256 lockDuration) external payable returns (uint256 tokenId) {
        if (lockDuration == 0) revert LockDurationMustBePositive();
        if (msg.value == 0) revert DepositBelowTier1(0);

        Tier tier = _tierFor(msg.value);
        //if (tier == Tier.None) revert DepositBelowTier1(msg.value);

        uint256 lockEnd = block.timestamp + lockDuration;

        tokenId = stakeReceipt.mint(msg.sender);// i know that this code should come prior to the line above it , cause its the token id here that is being used by that code, but if i pust this line above ,its going to be "Unreachable "
 
        stakes[tokenId] = Stake({owner: msg.sender, amount: msg.value, lockEnd: lockEnd, tier: tier});

        emit Staked(msg.sender, tokenId, msg.value, lockEnd, tier);
    }

    /// @notice Withdraws a matured stake — burns the NFT, pays principal + tier reward
    /// @param tokenId The stake's receipt tokenId
    function withdraw(uint256 tokenId) external {
        Stake memory s = stakes[tokenId];
        if (s.owner == address(0)) revert StakeDoesNotExist(tokenId);
        if (s.owner != msg.sender) revert NotStakeOwner(tokenId, msg.sender);
        if (block.timestamp < s.lockEnd) revert LockNotYetElapsed(tokenId, s.lockEnd);

        delete stakes[tokenId];
        stakeReceipt.burn(tokenId);

        uint256 reward = (s.amount * _rewardBpsFor(s.tier)) / BPS_DENOMINATOR;
        uint256 payout = s.amount + reward;

        (bool success,) = payable(msg.sender).call{value: payout}("");
        if (!success) revert EthTransferFailed(msg.sender, payout);

        emit Withdrawn(msg.sender, tokenId, s.amount, reward);
    }

 
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = payable(msg.sender).call{value: balance}("");
        if (!success) revert EthTransferFailed(msg.sender, balance);

        emit EmergencyDrain(msg.sender, balance);
    }
   
   
    function _tierFor(uint256 amount) internal pure returns (Tier) {  
        if (amount >= 10 ether) return Tier.Tier3;
        if (amount >= 5 ether) return Tier.Tier2;
        if (amount > 0 ether) return Tier.Tier1;
        return Tier.None;
    }

    function _rewardBpsFor(Tier tier) internal pure returns (uint16) {
        if (tier == Tier.Tier1) return TIER1_REWARD_BPS;
        if (tier == Tier.Tier2) return TIER2_REWARD_BPS;
        if (tier == Tier.Tier3) return TIER3_REWARD_BPS;
        return 0;
    }
}