// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}

/// @title TokenEscrow
/// @notice Holds a fixed amount of an ERC-20 token deposited by `depositor`.
///         An `arbiter` can release the funds to `recipient` at any time.
///         If the arbiter has not released by `deadline`, the depositor may
///         reclaim (refund) their own deposit instead.
contract TokenEscrow {
    enum State {
        AwaitingDeposit,
        Funded,
        Released,
        Refunded
    }

    IERC20 public immutable token;
    address public immutable depositor;
    address public immutable recipient;
    address public immutable arbiter;
    uint256 public immutable amount;
    uint256 public immutable deadline; // unix timestamp after which refund is allowed

    State public state;

    event Deposited(address indexed depositor, uint256 amount);
    event Released(address indexed recipient, uint256 amount);
    event Refunded(address indexed depositor, uint256 amount);

    error ZeroAddress();
    error ZeroAmount();
    error DeadlineInPast();
    error NotDepositor();
    error NotArbiter();
    error WrongState(State expected, State actual);
    error DeadlineNotReached(uint256 deadline, uint256 nowTs);
    error TransferFailed();

    modifier onlyDepositor() {
        if (msg.sender != depositor) revert NotDepositor();
        _;
    }

    modifier onlyArbiter() {
        if (msg.sender != arbiter) revert NotArbiter();
        _;
    }

    modifier inState(State expected) {
        if (state != expected) revert WrongState(expected, state);
        _;
    }

    constructor(
        address _token,
        address _depositor,
        address _recipient,
        address _arbiter,
        uint256 _amount,
        uint256 _deadline
    ) {
        if (_token == address(0) || _depositor == address(0) || _recipient == address(0) || _arbiter == address(0)) {
            revert ZeroAddress();
        }
        if (_amount == 0) revert ZeroAmount();
        if (_deadline <= block.timestamp) revert DeadlineInPast();

        token = IERC20(_token);
        depositor = _depositor;
        recipient = _recipient;
        arbiter = _arbiter;
        amount = _amount;
        deadline = _deadline;

        state = State.AwaitingDeposit;
    }

    /// @notice Pulls `amount` of the token from the depositor into escrow.
    /// @dev Depositor must have called token.approve(escrowAddress, amount) first.
    function deposit() external onlyDepositor inState(State.AwaitingDeposit) {
        state = State.Funded; // effects before interaction (checks-effects-interactions)

        bool ok = token.transferFrom(depositor, address(this), amount);
        if (!ok) revert TransferFailed();

        emit Deposited(depositor, amount);
    }

    /// @notice Arbiter confirms the condition was met; funds go to recipient.
    ///         Can only ever succeed once (state guard) and only the arbiter
    ///         can call it — the depositor cannot self-release.
    function release() external onlyArbiter inState(State.Funded) {
        state = State.Released;

        bool ok = token.transfer(recipient, amount);
        if (!ok) revert TransferFailed();

        emit Released(recipient, amount);
    }

    /// @notice If the arbiter hasn't released by `deadline`, the depositor
    ///         can pull their own funds back. Only the depositor can call it,
    ///         only once, and only after the deadline has passed.
    function refund() external onlyDepositor inState(State.Funded) {
        if (block.timestamp < deadline) revert DeadlineNotReached(deadline, block.timestamp);

        state = State.Refunded;

        bool ok = token.transfer(depositor, amount);
        if (!ok) revert TransferFailed();

        emit Refunded(depositor, amount);
    }
}
