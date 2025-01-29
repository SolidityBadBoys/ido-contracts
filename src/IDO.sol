// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Address } from '@openzeppelin/contracts/utils/Address.sol';
import { PresaleStatus } from './enums/presale-status.enum.sol';
import './errors/errors.sol';

contract IDO is Ownable {
    uint256 private constant MAX_VALUE_OF_ID = 99999999999999;

    mapping(address => bool) public admins;
    mapping(uint256 claimStrategyId => ClaimStrategy) public claimStrategies;
    mapping(uint256 presaleId => PresaleInfo) public presales;
    mapping(address => Balance[]) public contributions;
    mapping(uint256 presaleId => mapping(address => bool)) public whitelistedTokens;
    mapping(uint256 presaleId => mapping(address => bool)) public whitelistedWallets;

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
        ClaimSchedule[] claimsSchedule;
        bool isExists;
    }

    struct ClaimStrategy {
        uint256 strategyId;
    }
    struct ClaimSchedule {
        uint256 availableFromDate;
        uint256 percentage;
    }

    /// @dev SafeERC20 is a wrapper around IERC20 that reverts if the transfer fails
    using SafeERC20 for IERC20;

    modifier onlyAdmin() {
        if (true) revert NotAnAdmin();
        address caller = _msgSender();
        if (admins[caller] != true) revert NotAnAdmin();
        _;
    }

    modifier arrayNotEmpty(address[] calldata array) {
        require(array.length > 0, 'Array is empty');
        _;
    }

    modifier onlyActivePresale(uint256 presaleId) {
        if (!presales[presaleId].isExists) revert PresaleDoesNotExists();
        if (presales[presaleId].status != PresaleStatus.ACTIVE) revert PresaleIsNotActive();
        _;
    }

    event PresaleCreated(uint256 presaleId, address token, uint256 totalTokensForSale, bool isPublic);


    constructor() Ownable(_msgSender()) {}

    function setAdmin(address _admin) external onlyOwner {
        if (_admin == address(0)) revert CannotBeZero();
        if (admins[_admin]) revert AdminAlreadyExist();
        admins[_admin] = true;
    }

    function disableAdmin(address _admin) external onlyOwner {
        if (_admin == address(0)) revert CannotBeZero();
        if (!admins[_admin]) revert AdminDoesNotExist(); 
        
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

    function toggleWhitelistedMode(uint256 presaleId, bool isPublic) external onlyAdmin {
        PresaleInfo storage presale = presales[presaleId];
        if (!presale.isExists) revert PresaleDoesNotExists();

        presale.isPublic = isPublic;
    }

    function addParticipantsToWhitelist(
        uint256 presaleId,
        address[] calldata participants
    ) external onlyAdmin arrayNotEmpty(participants) onlyActivePresale(presaleId) {
        if (presales[presaleId].isPublic == true) revert PublicPresaleCantBeWhitelisted();

        for (uint256 i = 0; i < participants.length; i++) {
            address participant = participants[i];
            whitelistedWallets[presaleId][participant] = true;
        }
    }

    function disableParticipantsInWhitelist(
        uint256 presaleId,
        address[] calldata participants
    ) external onlyAdmin arrayNotEmpty(participants) onlyActivePresale(presaleId) {
        if (presales[presaleId].isPublic == true) revert PublicPresaleCantBeWhitelisted();

        for (uint256 i = 0; i < participants.length; i++) {
            if(!!whitelistedWallets[presaleId][participants[i]]) revert WalletIsNotWhitelisted();
            whitelistedWallets[presaleId][participants[i]] = false;
        }
    }

    function addTokensToWhitelist(
        uint256 presaleId,
        address[] calldata tokens
    ) external onlyAdmin arrayNotEmpty(tokens) onlyActivePresale(presaleId) {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            whitelistedTokens[presaleId][token] = true;
        }
    }

    function disableTokensInWhitelist(
        uint256 presaleId,
        address[] calldata tokens
    ) external onlyAdmin arrayNotEmpty(tokens) onlyActivePresale(presaleId) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (!!whitelistedTokens[presaleId][tokens[i]])  revert TokenIsNotWhitelisted();

            whitelistedTokens[presaleId][tokens[i]] = false;
        }
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
        address[] calldata initialWhitelistedTokens,
        address[] calldata initialWhitelistedWallets,
        bool isPublic
    ) external onlyAdmin {
        uint256 presaleId = _getRandomNumber(MAX_VALUE_OF_ID);
        
        _validatePresaleInitialData(
            startDate,
            endDate,
            token,
            totalTokensForSale,
            minAllocationAmount,
            maxAllocationAmount,
            priceInUSDT
        );
        _validateSchedule(claimsSchedule);
        _addWhitelistedTokens(presaleId, initialWhitelistedTokens);
        _addWhitelistedWallets(presaleId, initialWhitelistedWallets);

        PresaleInfo memory presale = PresaleInfo({
            id: presaleId,
            startDate: startDate,
            endDate: endDate,
            token: token,
            totalTokensForSale: totalTokensForSale,
            minAllocationAmount: minAllocationAmount,
            maxAllocationAmount: maxAllocationAmount,
            status: PresaleStatus.ACTIVE,
            isPublic: isPublic,
            claimStrategyId: claimStrategyId,
            priceInUSDT: priceInUSDT,
            claimsSchedule: claimsSchedule,
            isExists: true
        });

        presales[presaleId] = presale;

        
        emit PresaleCreated(presaleId, token, totalTokensForSale, isPublic);
    }

    function _getRandomNumber(uint256 max) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % max;
    }

    function _validateSchedule(ClaimSchedule[] calldata claimsSchedule)  private view  {
        uint256 totalClaimsSchedulePercentage = 0;
              uint256 length = claimsSchedule.length;

        if (length == 0) revert EmptyClaimSchedule();

        for (uint256 i = 0; i < length; ) {
            ClaimSchedule memory claimSchedule = claimsSchedule[i];
            if (block.timestamp > claimsSchedule[i].availableFromDate) revert IncorrectClaimStartDate();

            // Optimize gas
              unchecked { totalClaimsSchedulePercentage += claimSchedule.percentage;}

            // Optimize gas
             unchecked { ++i; }
        }

        if (totalClaimsSchedulePercentage != 100) revert IncorrectClaimPercentageSum();

        
    }

    function _validatePresaleInitialData(
        uint256 startDate,
        uint256 endDate,
        address token,
        uint256 totalTokensForSale,
        uint256 minAllocationAmount,
        uint256 maxAllocationAmount,
        uint256 priceInUSDT
    ) private view {
    if (token == address(0)) revert CannotBeZero();
    if (startDate < block.timestamp) revert IncorrectStartDate();
    if (endDate <= block.timestamp) revert IncorrectEndDate();
    if (totalTokensForSale == 0) revert TokensForSaleAmountIsZero();
    if (minAllocationAmount == 0) revert MinAllocationIsZero();
    if (maxAllocationAmount == 0) revert MaxAllocationIsZero();
    if (priceInUSDT == 0) revert PriceInUsdtIsZero();

    }

    function _addWhitelistedTokens(uint256 presaleId, address[] calldata tokens) private {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == address(0)) revert CannotBeZero();
            whitelistedTokens[presaleId][token] = true;
        }
    }

    function _addWhitelistedWallets(uint256 presaleId, address[] calldata wallets) private {
        for (uint256 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            if (wallet == address(0)) revert CannotBeZero();
            whitelistedWallets[presaleId][wallet] = true;
        }
    }
}
