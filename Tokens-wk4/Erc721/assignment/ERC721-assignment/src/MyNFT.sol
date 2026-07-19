// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC165} from "./interfaces/IERC165.sol";
import {IERC721} from "./interfaces/IERC721.sol";
import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {IERC721Receiver} from "./interfaces/IERC721Receiver.sol";

contract MyNFT is IERC721, IERC721Metadata {
    // Custom errors
   

    error ZeroAddress();
    error NotOwner();
    error NotOwnerOrApproved();
    error TransferToZeroAddress();
    error TokenDoesNotExist(uint256 tokenId);
    error AlreadyExists(uint256 tokenId);
    error InvalidReceiver(address receiver);

    // State

    string private _name;
    string private _symbol;

    address private immutable _contractOwner;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Constructor

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _contractOwner = msg.sender;
    }

   
    // Modifiers

    modifier onlyContractOwner() {
        if (msg.sender != _contractOwner) revert NotOwner();
        _;
    }

    modifier tokenMustExist(uint256 tokenId) {
        if (_owners[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);
        _;
    }

    // ERC-721 Metadata

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view tokenMustExist(tokenId) returns (string memory) {
        return string(abi.encodePacked("https://example.com/metadata/", _uintToString(tokenId)));
    }

    // ERC-721 Core

    function balanceOf(address owner) external view returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view tokenMustExist(tokenId) returns (address) {
        return _owners[tokenId];
    }

    function approve(address to, uint256 tokenId) external tokenMustExist(tokenId) {
        address tokenOwner = _owners[tokenId];
        if (msg.sender != tokenOwner && !_operatorApprovals[tokenOwner][msg.sender]) {
            revert NotOwnerOrApproved();
        }
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view tokenMustExist(tokenId) returns (address) {
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external {
        if (operator == address(0)) revert ZeroAddress();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public tokenMustExist(tokenId) {
        if (to == address(0)) revert TransferToZeroAddress();
        address tokenOwner = _owners[tokenId];
        if (tokenOwner != from) revert NotOwner();

        bool isOwner    = msg.sender == tokenOwner;
        bool isApproved = msg.sender == _tokenApprovals[tokenId];
        bool isOperator = _operatorApprovals[tokenOwner][msg.sender];
        if (!isOwner && !isApproved && !isOperator) revert NotOwnerOrApproved();

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    // ERC-165

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    // Mint (owner-only)

    function mint(address to, uint256 tokenId) external onlyContractOwner {
        if (to == address(0)) revert ZeroAddress();
        if (_owners[tokenId] != address(0)) revert AlreadyExists(tokenId);

        _owners[tokenId] = to;
        _balances[to] += 1;
        emit Transfer(address(0), to, tokenId);
    }

    // Internal helpers

    function _transfer(address from, address to, uint256 tokenId) internal {
        _owners[tokenId] = to;
        _balances[from] -= 1;
        _balances[to]   += 1;
        delete _tokenApprovals[tokenId];
        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) internal {
        if (to.code.length == 0) return;
        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
            if (retval != IERC721Receiver.onERC721Received.selector) revert InvalidReceiver(to);
        } catch {
            revert InvalidReceiver(to);
        }
    }

    function _uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
