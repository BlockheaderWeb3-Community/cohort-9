// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract MyEscrow {
    // --- State Variables ---
    IERC20 public immutable token;
    uint256 public nextEscrowId; // Keeps track of unique transaction IDs

    enum EscrowStatus { Active, Released, Refunded }

    // --- The Struct: What every escrow deal contains ---
    struct EscrowAgreement {
        address depositor;
        address recipient;
        address arbiter;
        uint256 amount;
        EscrowStatus status;
    }

    // mapping from: Escrow ID => Escrow details
    mapping(uint256 => EscrowAgreement) public escrows;

    // --- Custom Errors ---
    error OnlyArbiter();
    error NotActive();
    error TransferFailed();

    // --- Events ---
    event EscrowCreated(uint256 indexed escrowId, address indexed depositor, address indexed recipient, uint256 amount);
    event FundsReleased(uint256 indexed escrowId, address recipient, uint256 amount);
    event FundsRefunded(uint256 indexed escrowId, address depositor, uint256 amount);

   // Constructor only sets the token address
    constructor(address _token) {
        token = IERC20(_token);
    }

    /// @notice Anyone can call this to initiate a new escrow deal with a recipient and referee (arbiter)
    function createEscrow(address _recipient, address _arbiter, uint256 _amount) external returns (uint256) {
        uint256 escrowId = nextEscrowId;
        nextEscrowId++;

        // Store the new agreement inside our mapping
        escrows[escrowId] = EscrowAgreement({
            depositor: msg.sender,
            recipient: _recipient,
            arbiter: _arbiter,
            amount: _amount,
            status: EscrowStatus.Active
        });

        // Pulls the tokens into this contract from the depositor and checks that it succeeds!
        if (!token.transferFrom(msg.sender, address(this), _amount)) revert TransferFailed();

        emit EscrowCreated(escrowId, msg.sender, _recipient, _amount);
        return escrowId;
    }

    /// @notice The arbiter of the specific escrow ID calls this to release funds to the recipient (seller)
    function release(uint256 _escrowId) external {
        EscrowAgreement storage agreement = escrows[_escrowId];

        if (msg.sender != agreement.arbiter) revert OnlyArbiter();
        if (agreement.status != EscrowStatus.Active) revert NotActive();

        agreement.status = EscrowStatus.Released;
        if (!token.transfer(agreement.recipient, agreement.amount)) revert TransferFailed();

        emit FundsReleased(_escrowId, agreement.recipient, agreement.amount);
    }

    /// @notice The arbiter of the specific escrow ID calls this to refund funds to the depositor (buyer)
    function refund(uint256 _escrowId) external {
        EscrowAgreement storage agreement = escrows[_escrowId];

        if (msg.sender != agreement.arbiter) revert OnlyArbiter();
        if (agreement.status != EscrowStatus.Active) revert NotActive();

        agreement.status = EscrowStatus.Refunded;
        if (!token.transfer(agreement.depositor, agreement.amount)) revert TransferFailed();

        emit FundsRefunded(_escrowId, agreement.depositor, agreement.amount);
    }

}