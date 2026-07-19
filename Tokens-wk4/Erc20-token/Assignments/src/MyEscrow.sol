//SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import {IERC20} from "./interfaces/IERC20.sol";

//status should show pending,paid,not paid
contract MultiEscrow {
    //event Deposited(address indexed Buyer, uint256 amount, uint256 timestamp);
    event Released(uint256 indexed id,address indexed sender, uint256 amount, uint256 releasedAt);
    event Refunded(uint256 indexed id,address indexed buyer, uint256 amount, uint256 RefundedAt);

    //address public immutable buyer;
    //address public immutable seller;
    //IERC20 public immutable token;

    //uint256 public amount;

    //uint256 public deadline;

    enum State {
        AWAITING_PAYMENT,
        PENDING,
        PAID,
        REFUNDED
    }

    //State public state;

    struct Escrow {
        address buyer;
        address seller;
        address token;
        uint256 amount;
        uint256 deadline;
        State state;
    }

    mapping (uint256 => Escrow) public escrows;

    uint256 public nextEscrowid; // ill use this to  auto increment an id whenevr a buyer creates a contract

// i need an event that will be emitted when one call the "create escrow contract" and can be indexed with an id
    event EscrowCreated( uint256 indexed escrowid, address indexed buyer, address indexed seller, address token, uint256 amount, uint256 deadline, uint256 timestamp);


    // So turns out i can take this in two ways i can make the msg.sender to be the buyer or just pass and address for the buyer
    //ill take it the buyer being deployer cause
 error ZeroAddress();
 error ZeroAmount();
 error DeadlineisNotinFuture();
 error NotDepositor();
 error EscrowNotActive();
 error DeadlinePassed();
 error DeadlineNotPassed();
   // constructor(address _buyer, address _seller, address _tokenaddress, uint256 _duration) {
     //   require(_duration > 0, "Duration must be greater than Zero !!");
       // buyer = _buyer;
        //seller = _seller;
        //token = IERC20(_tokenaddress);
        //deadline = block.timestamp + _duration;
        //state = State.AWAITING_PAYMENT;
    //}
    //buyer 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    //Seller 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2

   // modifier onlyBuyer() {
     //   require(msg.sender == buyer, " Only Buyer Can Call this function please ");
       // _;
    //}


///@dev  since no state variables ,i cant use "require (msg.sender== buyer)..." so ill reference it using the struct and mapping then.


modifier canRelease(uint256 _escrowid){
  require(escrows[_escrowid].buyer==msg.sender,"Not authorized for this function");
  require(escrows[_escrowid].state == State.PENDING,"You can't perform this operation atp");
  require(escrows[_escrowid].deadline > block.timestamp," sorry but the deadline has been passed");
  _;
}
modifier canRefund(uint256 _escrowid){
  require(escrows[_escrowid].buyer==msg.sender,"Not authorized for this function");
  require(escrows[_escrowid].state == State.PENDING,"You can't perform this operation atp");
  require(escrows[_escrowid].deadline < block.timestamp," sorry but the deadline has passed yet");
  _;
}



// so i can't use a constructor again cause this contract belongs to multiple people and first user setting will affect the overall flow for next person
// also im merging the deposit to the createescrow,cause theres no need creating a contract if i'm not going to deposit
    function createEscrow( address _seller, address _token, uint256 _amount, uint256 _deadline) external returns (uint256 escrowid){
          if (_seller == address(0) || _token == address(0)) revert ZeroAddress();
          if (_amount==0) revert ZeroAmount();   
          if( _deadline <= block.timestamp) revert DeadlineisNotinFuture();
          // the transfrer from function requires a return of bool, so ill create a bool variable set to true i.e using require to check the transaction working else return false
          bool success = IERC20(_token).transferFrom(msg.sender, address(this), _amount);
          require(success, "payment failed,did you forget to approve");


          escrowid = nextEscrowid;
          escrows[escrowid]=Escrow({
            buyer: msg.sender,
            seller:_seller,
            token:_token,
            amount:_amount,
            deadline:_deadline,
            state:State.PENDING

          });

          nextEscrowid++;

          emit EscrowCreated(escrowid,msg.sender,_seller,_token,_amount,_deadline, block.timestamp);
    }

  

    function release(uint256 _escrowid) external  canRelease( _escrowid) {
        Escrow storage e = escrows[_escrowid];
        e.state=State.PAID;
        require(IERC20(e.token).transfer(e.seller,e.amount), "transfer failed");
        emit Released( _escrowid,e.seller, e.amount,block.timestamp);
    }

    function refund(uint256 _escrowid) external  canRefund(_escrowid) {
        Escrow storage e =escrows[_escrowid];
        e.state= State.REFUNDED;
        require(IERC20(e.token).transfer(e.buyer, e.amount), "transfer failed");
        emit Refunded(_escrowid,msg.sender, e.amount, block.timestamp);
    }

    // escrow created as 0xCe71536bdF17292ca9e783267E677345D2da32E1,https://sepolia.etherscan.io/address/0xce71536bdf17292ca9e783267e677345d2da32e1
}
