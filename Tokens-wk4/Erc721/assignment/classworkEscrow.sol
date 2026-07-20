// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

// Interface wrapper to access our custom burn functionality
interface IBurnableToken is IERC1155 {
    function burnAfterUse(address account, uint256 id, uint256 amount) external;
}

contract ClassworkEscrow is ERC1155Holder {
    address public escrowAgent;
    address public buyer;
    IBurnableToken public tokenContract;

    // Infinite-Scale Storage Ledger: User => TokenId => Amount Allocated
    mapping(address => mapping(uint256 => uint256)) public claimableBalances;

    error OnlyEscrowAgent();
    error OnlyBuyer();
    error MismatchedInput();
    error NoClaimableTokens();

    event DepositAllocated(uint256 tokenId, uint256 totalAmount);
    event TokensClaimed(address indexed recipient, uint256 indexed tokenId, uint256 amount);
    event ItemConsumedAndBurned(address indexed user, uint256 indexed tokenId, uint256 amount);

    modifier onlyAgent() {
        if (msg.sender != escrowAgent) revert OnlyEscrowAgent();
        _;
    }

    modifier onlyBuyer() {
        if (msg.sender != buyer) revert OnlyBuyer();
        _;
    }

    constructor(address _buyer, address _escrowAgent, address _tokenContract) {
        buyer = _buyer;
        escrowAgent = _escrowAgent;
        tokenContract = IBurnableToken(_tokenContract);
    }

    /**
     * @notice Tutor Requirement 1: Single deposit system that supports batch allocation setup.
     * @dev Escrow agent or buyer locks up the tokens and outlines who gets what.
     */
    function depositAssetAllocation(
        address[] calldata recipients, 
        uint256[] calldata amounts, 
        uint256 tokenId
    ) external onlyBuyer {
        if (recipients.length != amounts.length) revert MismatchedInput();

        uint256 totalRequired = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            claimableBalances[recipients[i]][tokenId] += amounts[i];
            totalRequired += amounts[i];
        }

        // Pull the entire required batch into this contract escrow safe in one transfer
        tokenContract.safeTransferFrom(msg.sender, address(this), tokenId, totalRequired, "");

        emit DepositAllocated(tokenId, totalRequired);
    }

    /**
     * @notice Tutor Requirement 2: Scalable architecture for 1 million+ users via the Pull Pattern.
     * @dev No looping over user lists. Users pay their own gas to claim their specific allocation.
     */
    function claimTokens(uint256 tokenId) external {
        uint256 allocatedAmount = claimableBalances[msg.sender][tokenId];
        if (allocatedAmount == 0) revert NoClaimableTokens();

        // Anti-Draining & Reentrancy protection: Clear mapping state before transferring assets
        claimableBalances[msg.sender][tokenId] = 0;

        // Execute the direct asset transfer out of the escrow vault
        tokenContract.safeTransferFrom(address(this), msg.sender, tokenId, allocatedAmount, "");

        emit TokensClaimed(msg.sender, tokenId, allocatedAmount);
    }

    /**
     * @notice Tutor Requirement 3: Tokens are burned after use.
     * @dev Simulates consuming/using an asset, destroying it permanently from the economy.
     */
    function consumeItemFromEscrow(uint256 tokenId, uint256 amount) external {
        uint256 allocatedAmount = claimableBalances[msg.sender][tokenId];
        if (allocatedAmount < amount) revert NoClaimableTokens();

        // Update accounting ledger state first
        claimableBalances[msg.sender][tokenId] -= amount;

        // Trigger the token contract's burn manager mechanism
        tokenContract.burnAfterUse(address(this), tokenId, amount);

        emit ItemConsumedAndBurned(msg.sender, tokenId, amount);
    }
}