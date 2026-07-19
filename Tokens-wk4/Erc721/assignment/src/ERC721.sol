// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC165} from "./interfaces/IERC165.sol";
import {IERC721} from "./interfaces/IERC721.sol";
import {IERC721Receiver} from "./interfaces/IERC721Receiver.sol";


/// @title ERC721 — hand-rolled, dependency-free reference implementation
/// @notice Implements the required ERC721 + ERC165 interfaces plus the
///         optional Metadata extension. Deliberately omits Enumerable —
///         see ERC721Enumerable.sol for that, with its gas caveats spelled out.
/// @dev No OpenZeppelin. Every design decision that matters to an auditor is
///      called out in a comment at the point it applies, not just up here.
abstract contract ERC721 is IERC721 {
    // ─────────────────────────────────────────────────────────────────────
    // Errors
    // ─────────────────────────────────────────────────────────────────────

    error ZeroAddress();
    error NonExistentToken(uint256 tokenId);
    error NotOwnerOrApproved(address caller, uint256 tokenId);
    error TransferFromIncorrectOwner(address from, address actualOwner, uint256 tokenId);
    error TransferToZeroAddress();
    error ApproveToCurrentOwner();
    error ApproveCallerNotOwnerNorOperator(address caller);
    error UnsafeRecipient(address to);
    error MintToZeroAddress();
    error TokenAlreadyMinted(uint256 tokenId);

    // ─────────────────────────────────────────────────────────────────────
    // Storage
    // ─────────────────────────────────────────────────────────────────────

    string private _name;
    string private _symbol;

    // tokenId => owner. Absence of an entry (address(0)) means "does not exist",
    // which is exactly the semantics ownerOf() needs to throw on.
    mapping(uint256 => address) private _owners;

    // owner => count of NFTs held. Kept as an explicit counter rather than
    // derived by iteration — iterating to compute a balance does not scale
    // (see the gas note on ERC721Enumerable).
    mapping(address => uint256) private _balances;

    // tokenId => approved single-token spender.
    mapping(uint256 => address) private _tokenApprovals;

    // owner => operator => approved-for-everything.
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // ─────────────────────────────────────────────────────────────────────
    // ERC165
    // ─────────────────────────────────────────────────────────────────────

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721).interfaceId;
    }

    // ─────────────────────────────────────────────────────────────────────
    // Metadata
    // ─────────────────────────────────────────────────────────────────────

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /// @dev Left abstract: how tokenURI is derived (static base URI + tokenId,
    ///      per-token stored URI, on-chain SVG, etc.) is a concrete-contract
    ///      decision, not a base-contract one.
    function tokenURI(uint256 tokenId) public view virtual returns (string memory);

    // ─────────────────────────────────────────────────────────────────────
    // Ownership queries
    // ─────────────────────────────────────────────────────────────────────

    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _requireOwned(tokenId);
    }

    /// @dev Reverts with NonExistentToken instead of silently returning
    ///      address(0) — a caller that forgets to check the return value of a
    ///      non-reverting ownerOf() would otherwise treat "no owner" as a
    ///      valid answer, which is exactly the kind of gap the spec's
    ///      "MUST throw" requirement exists to close.
    function _requireOwned(uint256 tokenId) internal view returns (address owner) {
        owner = _owners[tokenId];
        if (owner == address(0)) revert NonExistentToken(tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    // ─────────────────────────────────────────────────────────────────────
    // Approvals
    // ─────────────────────────────────────────────────────────────────────

    function approve(address to, uint256 tokenId) public payable virtual {
        address owner = _requireOwned(tokenId);

        if (to == owner) revert ApproveToCurrentOwner();
        if (msg.sender != owner && !_operatorApprovals[owner][msg.sender]) {
            revert ApproveCallerNotOwnerNorOperator(msg.sender);
        }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        if (operator == address(0)) revert ZeroAddress();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireOwned(tokenId);
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @dev The single check every transfer path funnels through: owner,
    ///      single-token approval, or blanket operator approval.
    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view returns (bool) {
        return spender == owner || isApprovedForAll(owner, spender) || getApprovedRaw(tokenId) == spender;
    }

    /// @dev Internal, non-reverting read used by _isAuthorized — getApproved()
    ///      itself reverts on a non-existent token, which would be the wrong
    ///      failure mode to trigger from inside an authorization check.
    function getApprovedRaw(uint256 tokenId) internal view returns (address) {
        return _tokenApprovals[tokenId];
    }

    // ─────────────────────────────────────────────────────────────────────
    // Transfers
    // ─────────────────────────────────────────────────────────────────────

    function transferFrom(address from, address to, uint256 tokenId) public payable virtual {
        if (to == address(0)) revert TransferToZeroAddress();

        address owner = _requireOwned(tokenId);
        if (owner != from) revert TransferFromIncorrectOwner(from, owner, tokenId);
        if (!_isAuthorized(owner, msg.sender, tokenId)) revert NotOwnerOrApproved(msg.sender, tokenId);

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable virtual {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(msg.sender, from, to, tokenId, data);
    }

    /// @dev Effects (ownership change, approval reset, Transfer event) all
    ///      happen here, before safeTransferFrom's external call to the
    ///      receiver. Checks-effects-interactions: by the time control leaves
    ///      this contract, on-chain state already reflects the new owner, so
    ///      a reentrant call during onERC721Received sees consistent state
    ///      rather than a half-updated transfer it could exploit.
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        // Clear the approval BEFORE emitting Transfer — a stale approval must
        // never survive past the moment ownership changes, or it becomes a
        // replayable permission for the token's new owner's assets.
        delete _tokenApprovals[tokenId];

        unchecked {
            // Balances can't overflow/underflow here: `from` is verified to
            // hold at least this one token, and the total supply of any real
            // deployment is far below type(uint256).max.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /// @dev Reverts the whole transaction unless `to` is an EOA, or a
    ///      contract that explicitly returns the ERC721 magic value. This is
    ///      what stops NFTs from getting locked forever in a contract that
    ///      has no code path to move them back out.
    function _checkOnERC721Received(address operator, address from, address to, uint256 tokenId, bytes memory data)
        private
    {
        if (to.code.length == 0) return; // EOA — nothing to call.

        try IERC721Receiver(to).onERC721Received(operator, from, tokenId, data) returns (bytes4 retval) {
            if (retval != IERC721Receiver.onERC721Received.selector) revert UnsafeRecipient(to);
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                // The call reverted with no data — most likely `to` doesn't
                // implement onERC721Received at all (or reverted with a
                // custom error via a proxy that swallows the reason).
                revert UnsafeRecipient(to);
            }
            // Bubble up the receiver's own revert reason unchanged.
            assembly {
                revert(add(reason, 32), mload(reason))
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    // Mint / burn — not part of the spec's external interface, but every
    // real deployment needs a way in and (often) a way out.
    // ─────────────────────────────────────────────────────────────────────

    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (_exists(tokenId)) revert TokenAlreadyMinted(tokenId);

        unchecked {
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        _checkOnERC721Received(msg.sender, address(0), to, tokenId, data);
    }

    /// @dev Burning transfers ownership to address(0), following the same
    ///      Transfer(from, to=0x0, tokenId) convention the spec uses for burns.
    ///      No receiver check on the way out — address(0) can't implement
    ///      IERC721Receiver, and isn't meant to.
    function _burn(uint256 tokenId) internal virtual {
        address owner = _requireOwned(tokenId);

        delete _tokenApprovals[tokenId];

        unchecked {
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }
}
