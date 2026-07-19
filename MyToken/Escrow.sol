// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20Min {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}

/// @title Escrow
/// @notice Holds ERC-20 tokens on behalf of many depositors at once. Each
/// call to `deposit` opens its own independent, numbered escrow — the
/// contract is a shared ledger of simultaneous deals, not a single-use
/// vault. Any number of deposits can be open concurrently, for the same
/// token or different ones, each tracked and settled separately.
contract Escrow {
    // ---------------------------------------------------------------------
    // Errors
    // ---------------------------------------------------------------------
    error ZeroAddress();
    error ZeroAmount();
    error EscrowNotFound(uint256 escrowId);
    error NotArbiter();
    error NotDepositor();
    error AlreadySettled();
    error TokenTransferFailed();

    // ---------------------------------------------------------------------
    // Storage
    // ---------------------------------------------------------------------
    enum Status {
        Active,
        Released,
        Refunded
    }

    struct Deal {
        address token;
        address depositor;
        address recipient;
        address arbiter;
        uint256 amount;
        Status status;
    }

    /// @dev Every open or settled deal lives here, keyed by its own id —
    /// deposits never overwrite or block each other.
    uint256 public nextEscrowId;
    mapping(uint256 => Deal) public deals;

    // ---------------------------------------------------------------------
    // Events
    // ---------------------------------------------------------------------
    event Deposited(
        uint256 indexed escrowId,
        address indexed token,
        address indexed depositor,
        address recipient,
        address arbiter,
        uint256 amount
    );
    event Released(uint256 indexed escrowId, address indexed recipient, uint256 amount);
    event Refunded(uint256 indexed escrowId, address indexed depositor, uint256 amount);

    // ---------------------------------------------------------------------
    // Deposit — opens a brand-new, independent escrow every time
    // ---------------------------------------------------------------------

    /// @notice Pulls `amount` of `token` from the caller into escrow #N and
    /// records who can release it (`arbiter`) and where it goes
    /// (`recipient`). Caller must have already `approve`'d this contract —
    /// funds are pulled with `transferFrom`, never pushed in raw.
    /// @param arbiter The address allowed to call `release`. Pass the
    /// depositor's own address to keep release decisions in their hands,
    /// or a third party to act as a neutral condition-checker.
    function deposit(address token, address recipient, address arbiter, uint256 amount)
        external
        returns (uint256 escrowId)
    {
        if (token == address(0) || recipient == address(0) || arbiter == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        escrowId = nextEscrowId++;
        deals[escrowId] = Deal({
            token: token,
            depositor: msg.sender,
            recipient: recipient,
            arbiter: arbiter,
            amount: amount,
            status: Status.Active
        });

        bool ok = IERC20Min(token).transferFrom(msg.sender, address(this), amount);
        if (!ok) revert TokenTransferFailed();

        emit Deposited(escrowId, token, msg.sender, recipient, arbiter, amount);
    }

    // ---------------------------------------------------------------------
    // Settlement — each escrow settles independently of every other one
    // ---------------------------------------------------------------------

    /// @notice Releases escrow #`escrowId` to its recipient. Only that
    /// deal's arbiter can call this, and only once.
    function release(uint256 escrowId) external {
        Deal storage deal = deals[escrowId];
        if (deal.depositor == address(0)) revert EscrowNotFound(escrowId);
        if (msg.sender != deal.arbiter) revert NotArbiter();
        if (deal.status != Status.Active) revert AlreadySettled();

        deal.status = Status.Released; // effects before interaction

        bool ok = IERC20Min(deal.token).transfer(deal.recipient, deal.amount);
        if (!ok) revert TokenTransferFailed();

        emit Released(escrowId, deal.recipient, deal.amount);
    }

    /// @notice Refunds escrow #`escrowId` back to its depositor. Only the
    /// original depositor can call this, and only before it's released.
    function refund(uint256 escrowId) external {
        Deal storage deal = deals[escrowId];
        if (deal.depositor == address(0)) revert EscrowNotFound(escrowId);
        if (msg.sender != deal.depositor) revert NotDepositor();
        if (deal.status != Status.Active) revert AlreadySettled();

        deal.status = Status.Refunded; // effects before interaction

        bool ok = IERC20Min(deal.token).transfer(deal.depositor, deal.amount);
        if (!ok) revert TokenTransferFailed();

        emit Refunded(escrowId, deal.depositor, deal.amount);
    }
}
