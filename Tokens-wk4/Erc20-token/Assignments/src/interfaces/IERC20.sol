// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    event TransferToken(address indexed from, address indexed to, uint256 value);

    event ApproveToken(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}
