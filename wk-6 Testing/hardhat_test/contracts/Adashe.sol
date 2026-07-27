// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title Adashe
/// @notice A rotating savings circle (ROSCA): members register, contribute each round,
///         and the pooled amount goes to the member whose turn matches the current round.
contract Adashe {
    uint8 public noOfPeople;
    uint8 public maxPeople;
    uint256 public amountPerHead;
    uint64 public duration;
    uint8 public currentRound;
    uint64 public roundStartTime;

    enum Packed {
        PENDING,
        PACKED,
        COMPLETED
    }

    Packed public status;

    struct Person {
        string name;
        address addr;
        uint256 turn;
        bool hasPaid;
    }

    mapping(uint8 => Person) public adashePeople;
    mapping(address => bool) public isRegistered;
    mapping(address => uint8) public memberId;

    event MemberRegistered(address indexed member, uint8 personId, uint256 turn, string name);
    event ContributionReceived(address indexed member, uint8 round, uint256 amount);
    event Payout(address indexed recipient, uint8 round, uint256 amount);
    event AdashePacked(uint8 memberCount);
    event AdasheCompleted();

    error AdasheFull();
    error AlreadyRegistered();
    error EmptyName();
    error InvalidMaxPeople();
    error InvalidAmount();
    error InvalidDuration();
    error InvalidPersonId();
    error NotRegistered();
    error AdasheNotPacked();
    error AlreadyPaid();
    error RoundExpired();
    error TransferFailed();

    constructor(uint8 _maxAmountOfPeople, uint256 _amount, uint64 _duration) {
        if (_maxAmountOfPeople == 0) revert InvalidMaxPeople();
        if (_amount == 0) revert InvalidAmount();
        if (_duration == 0) revert InvalidDuration();

        maxPeople = _maxAmountOfPeople;
        amountPerHead = _amount;
        duration = _duration;
        status = Packed.PENDING;
    }

    modifier adasheIsNotFull() {
        if (noOfPeople >= maxPeople) revert AdasheFull();
        _;
    }

    /// @notice Register for the savings circle. Turn order follows registration order.
    function registerForAdashe(string calldata _name) public adasheIsNotFull returns (uint256 turn_) {
        if (isRegistered[msg.sender]) revert AlreadyRegistered();
        if (bytes(_name).length == 0) revert EmptyName();
        noOfPeople++;

        uint8 personId = noOfPeople;
        turn_ = personId;

        adashePeople[personId] = Person({
            name: _name,
            addr: msg.sender,
            turn: turn_,
            hasPaid: false
        });

        isRegistered[msg.sender] = true;
        memberId[msg.sender] = personId;

        emit MemberRegistered(msg.sender, personId, turn_, _name);

        if (noOfPeople == maxPeople) {
            _packAdashe();
        }

        return turn_;
    }

    /// @notice Pay your contribution for the current round.
    function contribute() external payable {
        if (status != Packed.PACKED) revert AdasheNotPacked(); // must be PACKED: registering the last member calls _packAdashe(), which starts the round
        if (!isRegistered[msg.sender]) revert NotRegistered();
        if (block.timestamp > roundStartTime + duration) revert RoundExpired(); // roundStartTime is set at pack time, so the deadline is (packTime + duration)

        uint8 personId = memberId[msg.sender];
        Person storage person = adashePeople[personId];

        if (person.hasPaid) revert AlreadyPaid();
        if (msg.value != amountPerHead) revert InvalidAmount();

        person.hasPaid = true;

        emit ContributionReceived(msg.sender, currentRound, msg.value);

        if (_allPaid()) {
            _distributePayout();
        }
    }

    /// @notice Read a member by 1-based person id.
    function getAdasheMember(uint8 _personId) public view returns (Person memory person_) {
        if (_personId == 0 || _personId > noOfPeople) revert InvalidPersonId();
        person_ = adashePeople[_personId];
    }

    function _packAdashe() internal {
        status = Packed.PACKED;
        currentRound = 1;
        roundStartTime = uint64(block.timestamp);
        emit AdashePacked(maxPeople);
    }

    function _allPaid() internal view returns (bool) {
        for (uint8 i = 1; i <= maxPeople; i++) {
            if (!adashePeople[i].hasPaid) {
                return false;
            }
        }
        return true;
    }

    function _distributePayout() internal {
        Person storage recipient = adashePeople[currentRound];
        uint256 payout = amountPerHead * maxPeople;

        (bool success, ) = recipient.addr.call{value: payout}("");
        if (!success) revert TransferFailed();

        emit Payout(recipient.addr, currentRound, payout);

        for (uint8 i = 1; i <= maxPeople; i++) {
            adashePeople[i].hasPaid = false;
        }

        if (currentRound >= maxPeople) {
            status = Packed.COMPLETED;
            emit AdasheCompleted();
        } else {
            currentRound++;
            roundStartTime = uint64(block.timestamp);
        }
    }
}
