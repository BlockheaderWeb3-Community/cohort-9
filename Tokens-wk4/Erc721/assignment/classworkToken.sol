// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ClassworkToken is ERC1155, Ownable {
    uint256 public constant SWORD = 0;
    uint256 public constant SHIELD = 1;
    uint256 public constant POTION = 2;

    // Track authorized game modules (like your Escrow contract)
    mapping(address => bool) public authorizedManagers;

    error NotAuthorized();

    modifier onlyManager() {
        if (!authorizedManagers[msg.sender] && msg.sender != owner()) {
            revert NotAuthorized();
        }
        _;
    }

    constructor() ERC1155("https://api.mygame.com/metadata/{id}.json") Ownable(msg.sender) {
        // Minting to the deployer admin. The admin will deposit these into the Escrow contract.
        _mint(msg.sender, SWORD, 100, "");
        _mint(msg.sender, SHIELD, 100, "");
        _mint(msg.sender, POTION, 500, "");
    }

    // Authorize the Escrow contract to manage actions
    function setManager(address _manager, bool _status) external onlyOwner {
        authorizedManagers[_manager] = _status;
    }

    // THE FIX FOR CONSUMABLES: Allows the Escrow contract to burn used items
    function burnAfterUse(address account, uint256 id, uint256 amount) external onlyManager {
        _burn(account, id, amount);
    }
}