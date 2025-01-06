// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { PresaleStatus } from "./enums/presale-status.enum.sol";

 contract IDO is Ownable {
    uint256 constant MAX_VALUE_OF_ID = 99999999999999;
    
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
        ClaimSchedule[] claimsSchedule;
    }
    
    struct ClaimStrategy {
        uint256 strategyId;
    }

    struct ClaimSchedule {
        uint256 availableFromDate; // Дата, начиная с которой можно клеймить токены
        uint256 percentage;        // Процент от общего количества токенов, который можно клеймить
    }


    modifier onlyAdmin() {
        address caller = _msgSender();
        require(admins[caller] == true, 'Only admin can perform this action');
        _;
    }

    modifier arrayNotEmpty(address[] calldata array) {
        require(array.length > 0, "Array is empty");
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
 
    function addParticipantsToWhitelist(uint256 presaleId, address[] calldata participants) external onlyAdmin arrayNotEmpty(participants) {
        PresaleInfo storage presale = getValidatedPresaleById(presaleId);

        for (uint i = 0; i < participants.length; i++) {
            address participant = participants[i];
            presale.whitelistedWallets[participant] = true;
        }
    } 


    function disableParticipantsInWhitelist(uint256 presaleId, address[] calldata participants) external onlyAdmin arrayNotEmpty(participants) {
        PresaleInfo storage presale = getValidatedPresaleById(presaleId);
        
        for (uint i = 0; i < participants.length; i++) {
            require(presale.whitelistedWallets[participants[i]], "Wallet is not in whitelist");
            presale.whitelistedWallets[participants[i]] = false;
        }
    }

    function getValidatedPresaleById(uint256 presaleId) view internal returns(PresaleInfo storage) {
        PresaleInfo storage presale = presales[presaleId];
        require(presale.status == PresaleStatus.ACTIVE, "Presale is not active");

        return presale;
    }

    function createPresale(
    uint256 startDate,
    uint256 endDate,
    address token,
    uint256 totalTokensForSale,
    uint256 minAllocationAmount,
    uint256 maxAllocationAmount,
    uint256 claimStrategyId,
    uint256 priceInUSDT,
    ClaimSchedule[] calldata claimsSchedule,
    address[] calldata whitelistedTokens,
    address[] calldata whitelistedWallets,
    bool isPublic
    ) external onlyAdmin {
        uint256 presaleId = getRandomNumber(MAX_VALUE_OF_ID);
        
        require(startDate >= block.timestamp, 'Incorrect start date');
        require(endDate > block.timestamp, 'Incorrect end date');
        require(token != address(0), 'Token address cannot be zero');
        require(totalTokensForSale > 0, 'Total tokens for sale cannot be zero');
        require(minAllocationAmount > 0, 'Min allocation amount cannot be zero');
        require(maxAllocationAmount > 0, 'Max allocation amount cannot be zero');
        require(priceInUSDT > 0, 'Price in USDT cannot be zero');



        //TODO: add in validate schedule func
        uint256 totalClaimsSchedulePercentage = 0;
        for (uint i = 0; i < claimsSchedule.length; i++) {
            ClaimSchedule memory claimSchedule = claimsSchedule[i];
            require(block.timestamp <= claimSchedule.availableFromDate, "Claim start date is incorrect");
            
            totalClaimsSchedulePercentage += claimSchedule.percentage;
        }
        require(totalClaimsSchedulePercentage == 100, 'Sum of claims schedule percentage should be 100');

        // TODO: need to do that

        // mapping(address => bool) memory whitelistedTokensMap;
        // for (uint tokenIndex = 0; tokenIndex < whitelistedTokens.length; tokenIndex++) {
        //     address token = whitelistedTokens[tokenIndex];
        //     whitelistedTokensMap[token] = true;
        // }

        // mapping(address => bool) memory whitelistedWalletsMap;
        // for (uint walletIndex = 0; walletIndex < whitelistedWallets.length; walletIndex++) {
        //     address wallet = whitelistedWallets[walletIndex];
        //     whitelistedWalletsMap[wallet] = true;
        // }

    
        PresaleInfo memory presale = PresaleInfo({
            id: presaleId,
            startDate: startDate,
            endDate: endDate,
            token: token,
            totalTokensForSale: totalTokensForSale,
            minAllocationAmount: minAllocationAmount,
            maxAllocationAmount: maxAllocationAmount,
            status: PresaleStatus.ACTIVE,
            isPublic: isPublic,isPublic: isPublic,
            claimStrategyId: claimStrategyId,
            priceInUSDT: priceInUSDT,
            // whitelistedTokens: [],
            // whitelistedWallets: [],
            claimsSchedule: claimsSchedule
        });
        
        presales[presaleId] = presale;
    }

    function getRandomNumber(uint256 max) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % max;
    }
}