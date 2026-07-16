// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC165, IERC721, IERC721Metadata, IERC721Receiver} from "./interfaces/IERC721.sol";

error LeviNFT__NotOwner();
error LeviNFT__NotApprovedOrOwner();
error LeviNFT__TokenDoesNotExist();
error LeviNFT__ZeroAddressRecipient();
error LeviNFT__AlreadyMinted();
error LeviNFT__TransferToNonERC721Implementer();

contract LeviNFT is IERC721Metadata {
    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // --- ERC165 ---
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    // --- ERC721 Metadata ---
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_owners[tokenId] == address(0)) revert LeviNFT__TokenDoesNotExist();
        return _tokenURIs[tokenId];
    }

    // --- ERC721 Queries ---
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert LeviNFT__ZeroAddressRecipient();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert LeviNFT__TokenDoesNotExist();
        return owner;
    }

    // --- Approvals ---
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        if (to == owner) revert LeviNFT__ZeroAddressRecipient();
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert LeviNFT__NotApprovedOrOwner();
        }
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        if (_owners[tokenId] == address(0)) revert LeviNFT__TokenDoesNotExist();
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == msg.sender) revert LeviNFT__ZeroAddressRecipient();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // --- Transfers ---
    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert LeviNFT__NotApprovedOrOwner();
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        transferFrom(from, to, tokenId);
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, "") returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert LeviNFT__TransferToNonERC721Implementer();
                }
            } catch {
                revert LeviNFT__TransferToNonERC721Implementer();
            }
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
        transferFrom(from, to, tokenId);
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert LeviNFT__TransferToNonERC721Implementer();
                }
            } catch {
                revert LeviNFT__TransferToNonERC721Implementer();
            }
        }
    }

    // --- Minting ---
    function mint(address to, uint256 tokenId) external returns (uint256) {
        if (to == address(0)) revert LeviNFT__ZeroAddressRecipient();
        if (_owners[tokenId] != address(0)) revert LeviNFT__AlreadyMinted();
        _balances[to]++;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }

    // --- Internal ---
    function _transfer(address from, address to, uint256 tokenId) private {
        if (ownerOf(tokenId) != from) revert LeviNFT__NotOwner();
        if (to == address(0)) revert LeviNFT__ZeroAddressRecipient();

        _tokenApprovals[tokenId] = address(0);
        emit Approval(from, address(0), tokenId);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) private view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
}
