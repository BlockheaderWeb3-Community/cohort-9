// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract StakingNFT is ERC721 {

    address public stakingContract;

    uint256 public nextTokenId = 1;

    // tier (1, 2 or 3) for each token
    mapping(uint256 => uint8) public tokenTier;

    // metadata URLs per tier: Bronze, Silver, Gold
    string public bronzeURI = "ipfs://YOUR_BRONZE_CID/bronze.json";
    string public silverURI = "ipfs://YOUR_SILVER_CID/silver.json";
    string public goldURI   = "ipfs://YOUR_GOLD_CID/gold.json";

    constructor(address _stakingContract) ERC721("StakingNFT", "SNFT") {
        stakingContract = _stakingContract;
    }

    // returns the metadata URL for the token based on its tier
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");

        uint8 tier = tokenTier[tokenId];

        if (tier == 3) {
            return goldURI;
        } else if (tier == 2) {
            return silverURI;
        } else {
            return bronzeURI;
        }
    }

    // mints a tier NFT to the user, only the staking contract can call this
    function mint(address user, uint8 tier) external returns (uint256) {
        require(msg.sender == stakingContract, "Only the staking contract can mint");

        uint256 tokenId = nextTokenId;
        nextTokenId++;

        _mint(user, tokenId);
        tokenTier[tokenId] = tier;

        return tokenId;
    }

    // burns the NFT when the user withdraws, only the staking contract can call this
    function burn(uint256 tokenId) external {
        require(msg.sender == stakingContract, "Only the staking contract can burn");

        _burn(tokenId);
        delete tokenTier[tokenId];
    }
}
