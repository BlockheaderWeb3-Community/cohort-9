// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Adashe {
    uint8 public noOfPeople;
    uint8 public maxPeople;
    uint256 public amountPerHead;
    uint64 public duration;
    uint8 currentTurn;

    enum Packed {
        PENDING,
        PACKED
    }

    struct Person {
        string name;
        address addr;
        uint256 turn;
    }

    mapping(uint8 => Person) adashePeople;

    constructor(uint8 _maxAmountOfPeople, uint256 _amount, uint64 _duration) {
        maxPeople = _maxAmountOfPeople;
        amountPerHead = _amount;
        duration = _duration;
    }

    modifier adasheIsNotFull() {
        require(noOfPeople < maxPeople, "Adashe is full");
        _;
    }

    function registerForAdashe(string memory _name) public adasheIsNotFull returns (uint256 turn_) {
        require(msg.sender != address(0), "address zero detected");

        noOfPeople++;
        currentTurn++;

        adashePeople[noOfPeople] = Person({
            name: _name,
            addr: msg.sender,
            turn: currentTurn
        });

        turn_ = currentTurn;
        return turn_;
    }

    function getAdasheMember(uint8 _personId) public view returns (Person memory person_) {
        // reading from a mapping (storage) into memory
        person_ = adashePeople[_personId];
    }
}
