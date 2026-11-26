// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// A simple single escrow: a buyer deposits funds that are either
// released to the seller or refunded to the buyer after a deadline.
contract MyEscrow {
    address public immutable buyer;
    address public immutable seller;

    uint256 public amount;
    uint256 public immutable deadline;

    enum State {
        AWAITING_PAYMENT,
        PENDING,
        PAID,
        REFUNDED
    }

    State public state;

    event Deposited(address indexed buyer, uint256 amount, uint256 timestamp);
    event Released(address indexed seller, uint256 amount, uint256 timestamp);
    event Refunded(address indexed buyer, uint256 amount, uint256 timestamp);

    constructor(address _buyer, address _seller, uint256 _duration) {
        buyer = _buyer;
        seller = _seller;
        deadline = block.timestamp + _duration;
        state = State.AWAITING_PAYMENT;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only Buyer can call this function");
        _;
    }

    modifier inState(State _expected) {
        require(state == _expected, "Invalid state for this action");
        _;
    }

    

    function deposit() external payable onlyBuyer inState(State.AWAITING_PAYMENT) {
        require(msg.value != 0, "Amount must be greater than zero");

        amount = msg.value;
        state = State.PENDING;

        emit Deposited(msg.sender, msg.value, block.timestamp);
    }

    function release() external onlyBuyer inState(State.PENDING) {
        uint256 payout = amount;
        state = State.PAID;

        (bool success, ) = payable(seller).call{value: payout}("");
        require(success, "Transfer failed");

        emit Released(seller, payout, block.timestamp);
    }

    function refund() external onlyBuyer inState(State.PENDING) {
        require(block.timestamp >= deadline, "Deadline has not passed yet");

        uint256 payout = amount;
        state = State.REFUNDED;

        (bool success, ) = payable(buyer).call{value: payout}("");
        require(success, "Transfer failed");

        emit Refunded(buyer, payout, block.timestamp);
    }
}
