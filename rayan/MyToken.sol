// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MyToken
/// @notice Minimal, standards-compliant ERC-20 implementation.
contract MyToken {
    // ─────────────────────────────────────────────────────────────
    // Metadata
    // ─────────────────────────────────────────────────────────────
    string public name;
    string public symbol;
    uint8 public decimals;

    // ─────────────────────────────────────────────────────────────
    // Accounting
    // ─────────────────────────────────────────────────────────────
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // ─────────────────────────────────────────────────────────────
    // Events (must match the ERC-20 interface exactly)
    // ─────────────────────────────────────────────────────────────
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // ─────────────────────────────────────────────────────────────
    // Custom errors (cheaper than require+string, and required by spec)
    // ─────────────────────────────────────────────────────────────
    error ZeroAddress();
    error InsufficientBalance(address from, uint256 balance, uint256 needed);
    error InsufficientAllowance(address owner, address spender, uint256 allowance_, uint256 needed);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;

        // ERC-20 spec: minting should still emit a Transfer event from the zero address.
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    // ─────────────────────────────────────────────────────────────
    // Core ERC-20
    // ─────────────────────────────────────────────────────────────

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        // NOTE: approve only ever *sets* the allowance. It must never revert
        // because msg.sender lacks balance — that check belongs in transferFrom.
        if (spender == address(0)) revert ZeroAddress();

        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, value);
        return true;
    }

    // ─────────────────────────────────────────────────────────────
    // Internal helpers
    // ─────────────────────────────────────────────────────────────

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0) || to == address(0)) revert ZeroAddress();

        uint256 fromBalance = balanceOf[from];
        if (fromBalance < value) revert InsufficientBalance(from, fromBalance, value);

        unchecked {
            balanceOf[from] = fromBalance - value;
            balanceOf[to] += value;
        }

        emit Transfer(from, to, value);
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal {
        uint256 currentAllowance = allowance[owner][spender];

        // Infinite approval convention: an allowance of type(uint256).max is
        // treated as "unlimited" and must never be decremented. Silently
        // burning down a max allowance breaks the standard "approve once,
        // transferFrom many times" gas-saving pattern that integrators rely on.
        if (currentAllowance == type(uint256).max) {
            return;
        }

        if (currentAllowance < value) {
            revert InsufficientAllowance(owner, spender, currentAllowance, value);
        }

        unchecked {
            allowance[owner][spender] = currentAllowance - value;
        }

        emit Approval(owner, spender, allowance[owner][spender]);
    }
}
