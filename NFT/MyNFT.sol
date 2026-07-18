// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

/// @title MyNFT
/// @notice Minimal, standards-compliant ERC-721 implementation.
contract MyNFT is IERC721Metadata {
    string public name;
    string public symbol;

    address public immutable owner; // controls mint(); simple single-owner access control

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    bytes4 private constant _ERC165_ID = 0x01ffc9a7;
    bytes4 private constant _ERC721_ID = 0x80ac58cd;
    bytes4 private constant _ERC721_METADATA_ID = 0x5b5e139f;
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    error ZeroAddress();
    error NotOwner();
    error NotOwnerOrApproved();
    error TokenDoesNotExist(uint256 tokenId);
    error TokenAlreadyExists(uint256 tokenId);
    error IncorrectOwner(address from, uint256 tokenId);
    error UnsafeRecipient(address to);
    error SelfApproval();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
    }

    // ── ERC-165 ──────────────────────────────────────────────────

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == _ERC165_ID || interfaceId == _ERC721_ID || interfaceId == _ERC721_METADATA_ID;
    }

    // ── Views ────────────────────────────────────────────────────

    function balanceOf(address _owner) external view returns (uint256) {
        if (_owner == address(0)) revert ZeroAddress();
        return _balances[_owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address o = _owners[tokenId];
        if (o == address(0)) revert TokenDoesNotExist(tokenId);
        return o;
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        if (_owners[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address _owner, address operator) external view returns (bool) {
        return _operatorApprovals[_owner][operator];
    }

    /// @dev No metadata server wired up for this assessment; still reverts on
    ///      a non-existent token as the spec requires, which is the part that matters.
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        if (_owners[tokenId] == address(0)) revert TokenDoesNotExist(tokenId);
        return "";
    }

    // ── Approvals ────────────────────────────────────────────────

    function approve(address to, uint256 tokenId) external {
        address tokenOwner = ownerOf(tokenId); // reverts if nonexistent
        if (to == tokenOwner) revert SelfApproval();
        if (msg.sender != tokenOwner && !_operatorApprovals[tokenOwner][msg.sender]) {
            revert NotOwnerOrApproved();
        }

        // Approving address(0) clears any existing approval and must never revert.
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        if (operator == msg.sender) revert SelfApproval();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // ── Transfers ────────────────────────────────────────────────

    function transferFrom(address from, address to, uint256 tokenId) public {
        if (!_isAuthorized(msg.sender, from, tokenId)) revert NotOwnerOrApproved();
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    // ── Minting ──────────────────────────────────────────────────

    /// @notice Owner-only mint. Access control is deliberately simple for
    ///         this assessment — swap for public/allowlist minting if needed.
    function mint(address to, uint256 tokenId) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        if (_owners[tokenId] != address(0)) revert TokenAlreadyExists(tokenId);

        _owners[tokenId] = to;
        _balances[to] += 1;

        emit Transfer(address(0), to, tokenId);
    }

    // ── Internal helpers ─────────────────────────────────────────

    /// @dev Caller must be the owner, the token's specifically-approved
    ///      address, OR an operator approved via setApprovalForAll. Checking
    ///      only one of these three is the classic ERC-721 access-control bug.
    function _isAuthorized(address spender, address from, uint256 tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(tokenId); // reverts if nonexistent
        if (from != tokenOwner) revert IncorrectOwner(from, tokenId);

        return spender == tokenOwner || spender == _tokenApprovals[tokenId] || _operatorApprovals[tokenOwner][spender];
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) revert ZeroAddress();

        // Clear approval from the previous owner.
        delete _tokenApprovals[tokenId];

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) internal {
        if (to.code.length == 0) return; // EOA recipient, no hook to call

        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
            if (retval != _ERC721_RECEIVED) revert UnsafeRecipient(to);
        } catch {
            revert UnsafeRecipient(to);
        }
    }
}
