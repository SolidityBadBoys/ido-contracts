// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { PresaleStatus } from "./enums/presale-status.enum.sol";

 contract IDO is Ownable {
    mapping(address => bool) admins;
    mapping (uint256 claimStrategyId => ClaimStrategy) claimStrategies;
    mapping (uint256 presaleId => PresaleInfo) presales;
    mapping (address => Balance[]) contributions;

    struct Balance {
        uint256 presaleId;
        uint256 allocatedAmount;
        uint256 claimedAmount;
    }

    struct PresaleInfo {
        uint256 id;
        uint256 startDate;
        uint256 endDate;
        address token;
        uint256 totalTokensForSale;
        uint256 minAllocationAmount;
        uint256 maxAllocationAmount;
        PresaleStatus status;
        bool isPublic;
        uint256 claimStrategyId;
        uint256 priceInUSDT;
        mapping(address => bool) whitelistedTokens;
        mapping (address => bool) whitelistedWallets;
    }
    
    struct ClaimStrategy {
        uint256 strategyId;
    }

    modifier onlyAdmin() {
        address caller = _msgSender();
        require(admins[caller] == true, 'Only admin can perform this action');
        _;
    }


    /// @dev Error when the token or amount is zero
    error CannotBeZero();

    /// @dev SafeERC20 is a wrapper around IERC20 that reverts if the transfer fails
    using SafeERC20 for IERC20;
    
    constructor() Ownable(_msgSender()) {}

    function setAdmin(address _admin) external onlyOwner {
        if (_admin == address(0)) revert CannotBeZero();
        require(!admins[_admin], 'Admin with this address already exists');
        admins[_admin] = true;
    }

    function disableAdmin(address _admin) external onlyOwner {
        if (_admin == address(0)) revert CannotBeZero();
        require(admins[_admin], "Admin with this address doesn't exist");
        admins[_admin] = false;
    }

    function withdraw(address token, uint256 amount, address recipient) external onlyOwner {
        if (recipient == address(0)) revert CannotBeZero();

        if (token == address(0)) {
            Address.sendValue(payable(recipient), amount);
        } else {
            IERC20(token).safeTransfer(recipient, amount);
        }
    }

    function addParticipantsToWhitelist(uint256 presaleId, address[] calldata participants) external onlyAdmin {
        require(participants.length > 0, "Participants array is empty");

        PresaleInfo storage presale = presales[presaleId];
        require(presale.status == PresaleStatus.ACTIVE, "Presale is not active");

        for (uint i = 0; i < participants.length; i++) {
            address participant = participants[i];
            presale.whitelistedWallets[participant] = true;
        }
    } 


    function disableParticipantsInWhitelist(uint256 presaleId, address[] calldata participants) external onlyAdmin {
        // TODO Remove duplicate code
        require(participants.length > 0, "Participants array is empty");

        PresaleInfo storage presale = presales[presaleId];
        require(presale.status == PresaleStatus.ACTIVE, "Presale is not active");
        
        for (uint i = 0; i < participants.length; i++) {
            require(presale.whitelistedWallets[participants[i]], "Wallet is not in whitelist");
            presale.whitelistedWallets[participants[i]] = false;
        }
    }
}