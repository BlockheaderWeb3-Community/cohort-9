// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import {IERC20} from "../interfaces/IERC20.sol";

contract MyToken is IERC20 {
    // --- Core State (Private) ---
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;
    
    uint256 private _totalSupply;
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;

    

    // --- Custom Errors ---
    error ZeroAddress();
    error InsufficientBalance();
    error InsufficientAllowance();

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 initialSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        if (initialSupply_ > 0) {
            _totalSupply = initialSupply_;
            _balance[msg.sender] = initialSupply_;
            emit Transfer(address(0), msg.sender, initialSupply_);
        }
    }

    // --- Getters (Required because state is private) ---
    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public view returns (uint8) { return _decimals; }
    function totalSupply() public view returns (uint256) { return _totalSupply; }
    function balanceOf(address owner) public view returns (uint256) { return _balance[owner]; }
    function allowance(address owner, address spender) public view returns (uint256) { return _allowances[owner][spender]; }

    // --- Core Logic ---
    function transfer(address to, uint256 value) external returns (bool) {
        if (to == address(0) || msg.sender == address(0)) revert ZeroAddress();
        if (_balance[msg.sender] < value) revert InsufficientBalance();

        _balance[msg.sender] -= value;
        _balance[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        if (spender == address(0) || msg.sender == address(0)) revert ZeroAddress();

        _allowances[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        if (from == address(0) || to == address(0)) revert ZeroAddress();
        
        // 1. Check and deduct allowance
        uint256 currentAllowance = _allowances[from][msg.sender];
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) revert InsufficientAllowance();
            _allowances[from][msg.sender] -= value;
        }

        // 2. Check and deduct balance
        if (_balance[from] < value) revert InsufficientBalance();

        _balance[from] -= value;
        _balance[to] += value;

        emit Transfer(from, to, value);
        return true;
    }
}