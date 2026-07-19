// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OurNft} from "./OurNft.sol";

contract TimeLock is ReentrancyGuard, Ownable {
    //  minimum Time lock duration rather than a Fixed time Duration
    uint256 immutable min_lockDuration = 1 days;

    // NFT receipt contract
    OurNft public receiptNFT;

    // Track deposits, keyed by the receipt NFT's tokenId.
    // Holding the NFT is what authorizes withdrawal, so tokenId is the natural key
    // and it lets one user hold many deposits (one receipt each).
    struct Deposit {
        uint256 amount;
        uint256 depositTime;
        uint256 duration;
    }

    // tokenId => Deposit info
    mapping(uint256 => Deposit) public deposits;

    // Events
    event Deposited(address indexed user, uint256 amount, uint256 tokenId, uint256 lockEndTime);
    event Withdrawn(address indexed user, uint256 amount, uint256 tokenId);
    event EmergencyWithdrawn(address indexed user, uint256 amount, uint256 tokenId);

    constructor(address _receiptNFT) Ownable(msg.sender) {
        receiptNFT = OurNft(_receiptNFT);
    }

    // Users deposit ETH and receive an NFT receipt. Depositor picks their own lock
    // duration, but it must be at least the minimum. Depositing again just mints
    // another receipt, so no "already deposited" guard is needed.
    function deposit(uint256 _depositDuration) external payable nonReentrant {
        require(msg.value > 0, "Must deposit some ETH");
        require(_depositDuration >= min_lockDuration, "Time unit must be valid");

        // Mint NFT receipt to user
        uint256 tokenId = receiptNFT.mint(msg.sender);

        // Store deposit info keyed by tokenId
        deposits[tokenId] = Deposit({
            amount: msg.value,
            depositTime: block.timestamp,
            duration: _depositDuration
        });

        uint256 lockEndTime = block.timestamp + _depositDuration;
        emit Deposited(msg.sender, msg.value, tokenId, lockEndTime);
    }

    /// @dev  Former version, kept for reference. Keyed by msg.sender, so it only ever
    // supported one deposit per user and relied on the now-removed lockDuration.
    // function withdraw() external nonReentrant {
    //     Deposit storage userDeposit = deposits[msg.sender];
    //
    //     require(userDeposit.amount > 0, "No deposit found");
    //     require(userDeposit.withdrawn == false, "Already withdrawn");
    //     require(block.timestamp >= userDeposit.depositTime + lockDuration, "Lock period not over");
    //
    //     uint256 amount = userDeposit.amount;
    //     uint256 tokenId = userDeposit.tokenId;
    //
    //     // Update state BEFORE external calls
    //     userDeposit.withdrawn = true;
    //     delete nftToUser[tokenId];
    //
    //     // Burn the NFT receipt
    //     receiptNFT.burn(tokenId);
    //
    //     // Send ETH to user
    //     (bool success, ) = payable(msg.sender).call{value: amount}("");
    //     require(success, "ETH transfer failed");
    //
    //     emit Withdrawn(msg.sender, amount, tokenId);
    // }

    // Withdraw after the lock period by proving you hold the receipt NFT.
    // "Before you withdraw, you must have the receipt."
    function withdraw(uint256 tokenId) external nonReentrant {
        // ownerOf reverts for a nonexistent/burned token, so this also guards double-withdraw.
        require(receiptNFT.ownerOf(tokenId) == msg.sender, "Not your receipt");

        Deposit storage d = deposits[tokenId];
        require(block.timestamp >= d.depositTime + d.duration, "Lock period not over");

        uint256 amount = d.amount;

        // Update state BEFORE external calls
        delete deposits[tokenId];

        // Burn the receipt
        receiptNFT.burn(tokenId);

        // Send ETH to user
        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "ETH transfer failed");

        emit Withdrawn(msg.sender, amount, tokenId);
    }

    // Check if a given receipt can be withdrawn yet
    function canWithdraw(uint256 tokenId) external view returns (bool) {
        Deposit storage d = deposits[tokenId];
        if (d.amount == 0) {
            return false;
        }
        return block.timestamp >= d.depositTime + d.duration;
    }

    // Get a deposit's info by tokenId
    function getDepositInfo(uint256 tokenId) external view returns (
        uint256 amount,
        uint256 depositTime,
        uint256 lockEndTime,
        bool canWithdrawNow
    ) {
        Deposit storage d = deposits[tokenId];
        amount = d.amount;
        depositTime = d.depositTime;
        lockEndTime = depositTime + d.duration;
        canWithdrawNow = amount > 0 && block.timestamp >= lockEndTime;
    }

    // Get total ETH in vault
    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // =============================================
    // DEVELOPER FUNCTIONS (only owner)
    // =============================================

    /// @dev updateLockDuration has been removed. Since the contract enforces the
    /// minimum lock duration and each depositor sets their own duration, there is
    /// nothing global left to update.
    //

    // function updateLockDuration(uint256 newDuration) external onlyOwner {
    //     uint256 oldDuration = lockDuration;
    //     lockDuration = newDuration;
    //     emit LockDurationUpdated(oldDuration, newDuration);
    // }

    // Emergency withdrawal, before the lock period is over.
    // Funds are sent to depositor so long as they have deposited and hold the receipt NFT.
 
function emergencyWithdraw(uint256 tokenId) external onlyOwner nonReentrant {
    Deposit memory d = deposits[tokenId];
    require(d.amount > 0, "No deposit found");

    address depositor = receiptNFT.ownerOf(tokenId);
    uint256 amount = d.amount;

    delete deposits[tokenId];
    receiptNFT.burn(tokenId);

    (bool ok, ) = payable(depositor).call{value: amount}("");
    require(ok, "ETH transfer failed");

    emit EmergencyWithdrawn(depositor, amount, tokenId);
}
}