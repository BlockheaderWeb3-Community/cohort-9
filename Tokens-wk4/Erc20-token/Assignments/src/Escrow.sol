// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "./IERC20.sol";

error NotRecipient();
error AlreadyReleased();
error DeadlineNotReached();
error DeadlineExpired();
error InvalidToken();
error NothingToRefund();
error NoDeposit();

contract Escrow {
    struct Deposit {
        uint256 amount;
        bool refunded;
    }

    IERC20 public immutable token;
    address public immutable recipient;
    uint256 public immutable deadline;

    mapping(address => Deposit) public deposits;
    bool public released;

    event Deposited(address indexed depositor, uint256 amount);
    event Released(address indexed recipient, uint256 totalAmount);
    event Refunded(address indexed depositor, uint256 amount);

    constructor(IERC20 _token, address _recipient, uint256 _deadline) {
        if (address(_token) == address(0)) revert InvalidToken();
        if (_deadline <= block.timestamp) revert DeadlineExpired();

        token = _token;
        recipient = _recipient;
        deadline = _deadline;
    }

    function deposit(uint256 amount) external {
        if (released) revert AlreadyReleased();

        token.transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender].amount += amount;

        emit Deposited(msg.sender, amount);
    }

    function release() external {
        if (released) revert AlreadyReleased();
        if (msg.sender != recipient) revert NotRecipient();
        if (block.timestamp > deadline) revert DeadlineExpired();

        released = true;
        uint256 total = token.balanceOf(address(this));
        token.transfer(recipient, total);
        emit Released(recipient, total);
    }

    function refund() external {
        if (released) revert AlreadyReleased();
        if (block.timestamp <= deadline) revert DeadlineNotReached();

        Deposit storage d = deposits[msg.sender];
        if (d.amount == 0) revert NoDeposit();
        if (d.refunded) revert NothingToRefund();

        uint256 amount = d.amount;
        d.refunded = true;
        d.amount = 0;

        token.transfer(msg.sender, amount);
        emit Refunded(msg.sender, amount);
    }

    function getDeposit(address _depositor) external view returns (uint256 amount, bool refunded) {
        Deposit storage d = deposits[_depositor];
        return (d.amount, d.refunded);
    }
}
