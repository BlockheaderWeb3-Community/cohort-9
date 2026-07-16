// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// We only call two functions on the token, so this small interface is all we need.
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// JayEscrow
// A buyer locks some tokens for a seller until a deadline.
//  - release: the buyer is happy the deal is done, so the tokens go to the seller.
//  - refund:  the deadline passed and nothing was released, so the buyer takes the tokens back.
// Each escrow is used once. After a release or refund it is closed and can't be touched again.
// Many people can use the same contract at once because every deposit gets its own id.
contract JayEscrow {
    // --- errors ---
    error ZeroAddress();
    error ZeroAmount();
    error DeadlineInPast();
    error NotBuyer();
    error NotActive();
    error DeadlineNotReached();
    error TransferFailed();

    // --- the stage an escrow is at ---
    enum Status {
        None, // never created
        Active, // tokens are locked and waiting
        Released, // tokens went to the seller
        Refunded // tokens went back to the buyer
    }

    // --- one escrow deal between two people ---
    struct Escrow {
        address buyer; // put the tokens in, and is the only one who can release or refund
        address seller; // gets the tokens if the deal is released
        uint256 amount; // how many tokens are locked
        uint256 deadline; // unix time; after this the buyer is allowed to refund
        Status status;
    }

    // --- events ---
    event Deposited(
        uint256 indexed id, address indexed buyer, address indexed seller, uint256 amount, uint256 deadline
    );
    event Released(uint256 indexed id, address indexed seller, uint256 amount);
    event Refunded(uint256 indexed id, address indexed buyer, uint256 amount);

    // --- state ---
    IERC20 public immutable token; // the token this escrow works with
    uint256 public escrowCount; // number of escrows so far, and the id of the next one
    mapping(uint256 => Escrow) public escrows; // every escrow, looked up by its id

    constructor(address _token) {
        if (_token == address(0)) revert ZeroAddress();
        token = IERC20(_token);
    }

    // Lock `amount` tokens for `seller`. The buyer has to approve this contract first.
    function deposit(address seller, uint256 amount, uint256 deadline) external returns (uint256 id) {
        if (seller == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        if (deadline <= block.timestamp) revert DeadlineInPast();

        id = escrowCount;
        escrowCount++;

        escrows[id] =
            Escrow({buyer: msg.sender, seller: seller, amount: amount, deadline: deadline, status: Status.Active});

        // Pull the tokens into the contract. This needs the buyer's approval beforehand.
        if (!token.transferFrom(msg.sender, address(this), amount)) revert TransferFailed();

        emit Deposited(id, msg.sender, seller, amount, deadline);
    }

    // Buyer confirms the deal, so the tokens go to the seller.
    function release(uint256 id) external {
        Escrow storage e = escrows[id];
        if (e.status != Status.Active) revert NotActive();
        if (msg.sender != e.buyer) revert NotBuyer();

        e.status = Status.Released;
        if (!token.transfer(e.seller, e.amount)) revert TransferFailed();

        emit Released(id, e.seller, e.amount);
    }

    // Deadline passed with no release, so the buyer takes the tokens back.
    function refund(uint256 id) external {
        Escrow storage e = escrows[id];
        if (e.status != Status.Active) revert NotActive();
        if (msg.sender != e.buyer) revert NotBuyer();
        if (block.timestamp <= e.deadline) revert DeadlineNotReached();

        e.status = Status.Refunded;
        if (!token.transfer(e.buyer, e.amount)) revert TransferFailed();

        emit Refunded(id, e.buyer, e.amount);
    }
}
