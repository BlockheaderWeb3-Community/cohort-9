// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// A tiny interface so the Escrow knows how to move the token
interface IERC20Minimal {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}

contract MyEscrow {
    // --- State Variables ---
    IERC20Minimal public immutable token;
    address public immutable depositor;
    address public immutable recipient;
    address public immutable arbiter;
    uint256 public immutable amount;

    // --- Safety Locks ---
    bool public isFunded;
    bool public isResolved;

    // --- Custom Errors ---
    error NotDepositor();
    error NotArbiter();
    error InvalidState(); // Used if someone tries to deposit twice, or release before deposit
    error TransferFailed();

    constructor(address _tokenAddress, address _recipient, address _arbiter, uint256 _amount) {
        token = IERC20Minimal(_tokenAddress);
        depositor = msg.sender;
        recipient = _recipient;
        arbiter = _arbiter;
        amount = _amount;
    }

    // 1. Depositor locks the tokens into this contract
    // NOTE: Depositor MUST call `approve()` on the token contract first!
    function deposit() external {
        if (msg.sender != depositor) revert NotDepositor();
        if (isFunded) revert InvalidState(); // Prevents double-deposits
        
        isFunded = true;
        
        bool success = token.transferFrom(depositor, address(this), amount);
        if (!success) revert TransferFailed();
    }

    // 2. Arbiter sends the tokens to the recipient (Condition Met)
    function release() external {
        if (msg.sender != arbiter) revert NotArbiter();
        if (!isFunded || isResolved) revert InvalidState(); // Must be funded, cannot be resolved twice

        isResolved = true; // Lock the contract forever

        bool success = token.transfer(recipient, amount);
        if (!success) revert TransferFailed();
    }

    // 3. Arbiter sends the tokens back to the depositor (Condition Failed / Cancelled)
    function refund() external {
        if (msg.sender != arbiter) revert NotArbiter();
        if (!isFunded || isResolved) revert InvalidState();

        isResolved = true; // Lock the contract forever

        bool success = token.transfer(depositor, amount);
        if (!success) revert TransferFailed();
    }
}