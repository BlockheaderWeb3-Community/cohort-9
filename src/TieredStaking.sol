// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {StakingNFT} from "./StakingNFT.sol";

contract TieredStaking {

    StakingNFT public nft;

    // receives the 10% penalty on emergency withdrawals
    address public owner;

    // one stake per user
    struct Stake {
        uint256 amount;       // ETH deposited
        uint256 lockedUntil;  // timestamp when lock expires
        uint256 nftTokenId;   // receipt NFT id
        uint8   tier;         // 1 = Bronze, 2 = Silver, 3 = Gold
    }

    mapping(address => Stake) public stakes;

    event Staked(address indexed user, uint256 amount, uint8 tier, uint256 lockedUntil);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyWithdrawn(address indexed user, uint256 amountReturned, uint256 penaltyPaid);

    // payable so the deployer can seed the contract with ETH at deploy time
    constructor() payable {
        owner = msg.sender;
        nft = new StakingNFT(address(this));
    }

    // deposit ETH and choose a lock duration in seconds
    function stake(uint256 lockDurationInSeconds) external payable {
        require(msg.value > 0,                     "You must send some ETH to stake");
        require(lockDurationInSeconds >= 1 days,   "Minimum lock is 1 day");
        require(lockDurationInSeconds <= 730 days, "Maximum lock is 730 days");
        require(stakes[msg.sender].amount == 0,    "Withdraw your current stake first");

        // assign tier based on amount sent
        uint8 tier;
        if (msg.value >= 50 ether) {
            tier = 3;  // Gold
        } else if (msg.value >= 10 ether) {
            tier = 2;  // Silver
        } else {
            tier = 1;  // Bronze
        }

        uint256 lockedUntil = block.timestamp + lockDurationInSeconds;

        // mint the receipt NFT to the user
        uint256 nftTokenId = nft.mint(msg.sender, tier);

        stakes[msg.sender] = Stake({
            amount:      msg.value,
            lockedUntil: lockedUntil,
            nftTokenId:  nftTokenId,
            tier:        tier
        });

        emit Staked(msg.sender, msg.value, tier, lockedUntil);
    }

    // withdraw after lock expires - burns NFT, returns 100% ETH
    function withdraw() external {
        Stake memory myStake = stakes[msg.sender];

        require(myStake.amount > 0,                     "No active stake");
        require(block.timestamp >= myStake.lockedUntil, "Stake is still locked");

        // clear state before sending ETH to prevent re-entrancy
        delete stakes[msg.sender];

        nft.burn(myStake.nftTokenId);

        (bool sent, ) = msg.sender.call{value: myStake.amount}("");
        require(sent, "ETH transfer failed");

        emit Withdrawn(msg.sender, myStake.amount);
    }

    // withdraw anytime but lose 10% as a penalty
    function emergencyWithdraw() external {
        Stake memory myStake = stakes[msg.sender];

        require(myStake.amount > 0, "No active stake");

        // clear state before sending ETH to prevent re-entrancy
        delete stakes[msg.sender];

        nft.burn(myStake.nftTokenId);

        uint256 penaltyAmount  = (myStake.amount * 10) / 100;
        uint256 amountToReturn = myStake.amount - penaltyAmount;

        (bool sentToUser, ) = msg.sender.call{value: amountToReturn}("");
        require(sentToUser, "ETH transfer failed");

        // penalty goes to the owner
        (bool sentToOwner, ) = owner.call{value: penaltyAmount}("");
        require(sentToOwner, "Penalty transfer failed");

        emit EmergencyWithdrawn(msg.sender, amountToReturn, penaltyAmount);
    }
}
