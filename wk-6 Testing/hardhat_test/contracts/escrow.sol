// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Escrow {

    uint256 public escrowCount;

    enum State {
        OPEN,
        FUNDED,
        COMPLETE,
        CANCELLED
    }

    struct EscrowDeal {
        uint256 id;
        address buyer;
        address seller;
        uint256 amount;
        State state;
        uint256 createdAt;
    }

    mapping(uint256 => EscrowDeal) public escrows;

   

    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed buyer,
        address indexed seller
    );

    event Deposited(
        uint256 indexed escrowId,
        address indexed buyer,
        uint256 amount
    );

    event DeliveryConfirmed(
        uint256 indexed escrowId,
        address indexed seller,
        uint256 amount
    );

    event EscrowCancelled(
        uint256 indexed escrowId
    );

   

    error NotBuyer();
    error NotSeller();
    error InvalidState();
    error ZeroAmount();
    error TransferFailed();
    error InvalidAddress();

  

    modifier onlyBuyer(uint256 _id) {
        if (msg.sender != escrows[_id].buyer)
            revert NotBuyer();
        _;
    }

    modifier onlySeller(uint256 _id) {
        if (msg.sender != escrows[_id].seller)
            revert NotSeller();
        _;
    }

    modifier inState(uint256 _id, State expectedState) {
        if (escrows[_id].state != expectedState)
            revert InvalidState();
        _;
    }

   

    function createEscrow(
        address _buyer,
        address _seller
    ) external returns (uint256 escrowId) {

        if (_buyer == address(0) || _seller == address(0))
            revert InvalidAddress();

        escrowCount++;

        escrowId = escrowCount;

        escrows[escrowId] = EscrowDeal({
            id: escrowId,
            buyer: _buyer,
            seller: _seller,
            amount: 0,
            state: State.OPEN,
            createdAt: block.timestamp
        });

        emit EscrowCreated(
            escrowId,
            _buyer,
            _seller
        );
    }


    function deposit(uint256 _id)
        external
        payable
        onlyBuyer(_id)
        inState(_id, State.OPEN)
    {
        if (msg.value == 0)
            revert ZeroAmount();

        EscrowDeal storage escrow = escrows[_id];

        escrow.amount = msg.value;

        escrow.state = State.FUNDED;

        emit Deposited(
            _id,
            msg.sender,
            msg.value
        );
    }

   

    function confirmDelivery(uint256 _id)
        external
        onlyBuyer(_id)
        inState(_id, State.FUNDED)
    {
        EscrowDeal storage escrow = escrows[_id];

        uint256 payment = escrow.amount;

        escrow.amount = 0;

        escrow.state = State.COMPLETE;

        (bool success,) = payable(
            escrow.seller
        ).call{value: payment}("");

        if (!success)
            revert TransferFailed();

        emit DeliveryConfirmed(
            _id,
            escrow.seller,
            payment
        );
    }


    function cancelEscrow(uint256 _id)
        external
        onlyBuyer(_id)
        inState(_id, State.OPEN)
    {
        escrows[_id].state = State.CANCELLED;

        emit EscrowCancelled(_id);
    }

  

    function refund(uint256 _id)
        external
        onlySeller(_id)
        inState(_id, State.FUNDED)
    {
        EscrowDeal storage escrow = escrows[_id];

        uint256 payment = escrow.amount;

        escrow.amount = 0;

        escrow.state = State.CANCELLED;

        (bool success,) = payable(
            escrow.buyer
        ).call{value: payment}("");

        if (!success)
            revert TransferFailed();
    }



    function getEscrow(uint256 _id)
        external
        view
        returns (EscrowDeal memory)
    {
        return escrows[_id];
    }
}