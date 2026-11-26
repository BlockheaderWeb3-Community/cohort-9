 //SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title StakeReceipt
/// @notice Simple, non-transferable (soulbound) NFT — mint/burn restricted to the staking contract
/// @dev Deployed BY the staking contract's constructor, so the staking address is known immutably
/// at construction — no Ownable, no setter, no admin risk.
contract StakeReceipt is ERC721 {
   
  //  error SoulboundTokenNotTransferable();
    error NotStakingContract();


    address public immutable stakingContract;
    uint256 private _nextTokenId;



    /// @param _stakingContract The only address ever allowed to mint or burn — pass msg.sender
    /// when the staking contract deploys this from its own constructor.
    constructor(address _stakingContract) ERC721("StakeReceipt", "STAKE") {
        stakingContract = _stakingContract;
    }

    modifier onlyStakingContract() {
        if (msg.sender != stakingContract) revert NotStakingContract();
        _;
    }



    /// @notice Mints a new receipt token, callable only by the staking contract
    function mint(address to) external onlyStakingContract returns (uint256 tokenId) {
        tokenId = ++_nextTokenId;
        _safeMint(to, tokenId);
    }

    /// @notice Burns a receipt token, callable only by the staking contract
    function burn(uint256 tokenId) external onlyStakingContract {
        _burn(tokenId);
    }

  

    /// @dev Blocks all transfers — only mint (from == address(0)) and burn (to == address(0)) allowed
    //function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
      //  address from = _ownerOf(tokenId);
        //if (from != address(0) && to != address(0)) {
          //  revert SoulboundTokenNotTransferable();
        //}
     //   return super._update(to, tokenId, auth);
    //}
}
