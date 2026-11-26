// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking {
    event Staked(address indexed user, uint256 value, uint256 timestamp);
    event withdrawn(address indexed user, uint256 value, uint256 timestamp);

    IERC20 public rewardToken;
    uint256 public lockPeriod;

    uint256 public rewardRateBps;

    struct Stake {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Stake) public stakes;

    constructor(address _rewardToken, uint256 _lockPeriod, uint256 _rewardRateBps) {
        rewardToken = IERC20(_rewardToken);

        lockPeriod = _lockPeriod;

        rewardRateBps = _rewardRateBps;
    }

    function stake() external payable {
        require(msg.value > 0, "Send ETH to stake");
        require(stakes[msg.sender].amount == 0, "Already staked");

        stakes[msg.sender] = Stake(msg.value, block.timestamp + lockPeriod);

        emit Staked(msg.sender, msg.value, block.timestamp);
    }

    function withdraw() external {
        Stake memory s = stakes[msg.sender];
        require(s.amount > 0, "Nothing staked");
        require(block.timestamp >= s.unlockTime, "Still locked");

        delete stakes[msg.sender];

        uint256 reward = (s.amount * rewardRateBps) / 10000;

        (bool sent,) = msg.sender.call{value: s.amount}("");
        require(sent, "ETH transfer failed");

        rewardToken.transfer(msg.sender, reward);
    }
}
