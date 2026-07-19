//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "./interfaces/IERC20.sol";

contract MyToken is IERC20 {
    //metadata
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;

    //--core state ---
    uint256 private _totalSupply;
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    //--custom errors
    error InsufficientBalance(address account, uint256 balance, uint256 amount);
    error InsufficientAllowance(address owner, address spender, uint256 amount);
    error TransferToZeroAddress();
    error TransferFromZeroAddress();
    error ApprovalToZeroAddress();
    error ApprovalFromZeroAddress();
    error CannotSendZero();

    //--core reads --
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balance[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 initialSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        if (initialSupply_ > 0) {
            mint(msg.sender, initialSupply_);
        }
    }

    //--metadata getter----
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    //--Internals---
    function _transfer(address from, address to, uint256 amount) internal {
        if (from == address(0)) revert TransferFromZeroAddress();
        if (to == address(0)) revert TransferToZeroAddress();
        if (amount == 0) revert CannotSendZero();

        uint256 fromBal = _balance[from];
        if (fromBal < amount) revert InsufficientBalance(from, fromBal, amount);

        _balance[from] = fromBal - amount;
        _balance[to] = _balance[to] + amount;

        emit TransferToken(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        if (owner == address(0)) revert ApprovalFromZeroAddress();
        if (spender == address(0)) revert ApprovalToZeroAddress();

        _allowances[owner][spender] = amount;
        emit ApproveToken(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert InsufficientAllowance(owner, spender, currentAllowance);
            }
            _approve(owner, spender, currentAllowance - value);
        }
    }

    function mint(address to, uint256 value) internal {
        if (to == address(0)) revert TransferToZeroAddress();
        _totalSupply = _totalSupply + value;
        _balance[to] = _balance[to] + value;

        emit TransferToken(address(0), to, value);
    }

    function burn(address from, uint256 value) internal {
        if (from == address(0)) revert TransferFromZeroAddress();
        uint256 bal = _balance[from];
        if (bal < value) revert InsufficientBalance(from, bal, value);

        _totalSupply = _totalSupply - value;
        _balance[from] = _balance[from] - value;

        emit TransferToken(from, address(0), value);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, value);

        return true;
    }
}

// sepolia address and ethercan api for mytoken.sol is 0xF251E976C2c54ef10b6Da88FA572ef35886aa7Cb,https://sepolia.etherscan.io/address/0xF251E976C2c54ef10b6Da88FA572ef35886aa7Cb

//
