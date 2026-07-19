// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract OurNft is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    
    // To know which Address owns what NFT i.e Token ID 
    mapping(uint256 => address) public tokenVault;
    
    // Events
    event NFTMinted(address indexed to, uint256 tokenId, address indexed vault);
    event NFTBurned(uint256 tokenId, address indexed vault);
    
    constructor() ERC721("Vault Receipt NFT", "vNFT") Ownable(msg.sender) {}
    
    // Only the vault (owner) can mint
    function mint(address to) external onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);
        tokenVault[tokenId] = msg.sender;
        
        emit NFTMinted(to, tokenId, msg.sender);
        return tokenId; 
    }
    
    // Only the vault (owner) can burn
    function burn(uint256 tokenId) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        tokenVault[tokenId] = address(0);
        _burn(tokenId);
        
        emit NFTBurned(tokenId, msg.sender);
    }
    
    // Get the vault that minted this NFT
    function getVault(uint256 tokenId) external view returns (address) {
        return tokenVault[tokenId];
    }
    
    // Check if token exists
    function exists(uint256 tokenId) external view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
    
    // Get current token ID counter (next token ID to be minted)
    function getCurrentTokenId() external view returns (uint256) {
        return _tokenIdCounter;
    }
}