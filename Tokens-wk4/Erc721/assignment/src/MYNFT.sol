// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "./ERC721.sol";

/// @title MyNFT — a minimal concrete ERC721, base-URI + sequential tokenIds

contract MyNFT is ERC721 {
    error CallerNotOwner();
    error MaxSupplyReached();

    address public immutable owner;
    uint256 public immutable maxSupply;
    uint256 public nextTokenId;
    string private _baseTokenURI;

    modifier onlyOwner() {
        if (msg.sender != owner) revert CallerNotOwner();
        _;
    }

    constructor(string memory name_, string memory symbol_, string memory baseTokenURI_, uint256 maxSupply_)
        ERC721(name_, symbol_)
    {
        owner = msg.sender;
        _baseTokenURI = baseTokenURI_;
        maxSupply = maxSupply_;
    }

    /// @notice Mint the next sequential tokenId to `to`.
    /// @dev tokenId is sequential and therefore predictable by design — see
    ///      the audit note on tokenURI() below regarding "reveal" mechanics
    ///      if that predictability matters for your use case.
    function mint(address to) external onlyOwner returns (uint256 tokenId) {
        tokenId = nextTokenId;
        if (tokenId >= maxSupply) revert MaxSupplyReached();
        nextTokenId = tokenId + 1;
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) external {
        address tokenOwner = ownerOf(tokenId);
        if (msg.sender != tokenOwner && !isApprovedForAll(tokenOwner, msg.sender) && getApproved(tokenId) != msg.sender)
        {
            revert NotOwnerOrApproved(msg.sender, tokenId);
        }
        _burn(tokenId);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /// @dev Simple `{baseURI}{tokenId}` scheme. Throws via _requireOwned if
    ///      the token doesn't exist, per the spec's requirement for tokenURI.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return string.concat(_baseTokenURI, _toString(tokenId));
    }

    /// @dev Minimal uint256 -> decimal string, no external library needed.
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
