// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Address } from '@openzeppelin/contracts/utils/Address.sol';

import { PresaleStatus } from './enums/presale-status.enum.sol';

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

    modifier onlyAdmin() {
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

    /// @dev Error when the user is not an admin
    error NotAnAdmin();

    /// @dev Error when the token or amount is zero
    error CannotBeZero();

    /// @dev Error when the presale doesn't exists
    error PresaleDoesNotExists();

    /// @dev Error when the presale is not active
    error PresaleIsNotActive();

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
        require(admins[_admin], 'Admin with this address doesn"t exist');
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
        require(presales[presaleId].isPublic == false, 'Public presales can"t be whitelisted');

        for (uint256 i = 0; i < participants.length; i++) {
            address participant = participants[i];
            whitelistedWallets[presaleId][participant] = true;
        }
    }

    function disableParticipantsInWhitelist(
        uint256 presaleId,
        address[] calldata participants
    ) external onlyAdmin arrayNotEmpty(participants) onlyActivePresale(presaleId) {
        require(presales[presaleId].isPublic == false, 'Public presales can"t be whitelisted');

        for (uint256 i = 0; i < participants.length; i++) {
            require(whitelistedWallets[presaleId][participants[i]], 'Wallet is not in whitelist');
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
            require(whitelistedTokens[presaleId][tokens[i]], 'Token is not in whitelist');
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
    }

    function _getRandomNumber(uint256 max) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % max;
    }

    function _validateSchedule(ClaimSchedule[] calldata claimsSchedule) private view {
        uint256 totalClaimsSchedulePercentage = 0;
        for (uint256 i = 0; i < claimsSchedule.length; i++) {
            ClaimSchedule memory claimSchedule = claimsSchedule[i];
            require(block.timestamp <= claimSchedule.availableFromDate, 'Claim start date is incorrect');

            totalClaimsSchedulePercentage += claimSchedule.percentage;
        }
        require(totalClaimsSchedulePercentage == 100, 'Sum of claims schedule percentage should be 100');
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
        require(startDate >= block.timestamp, 'Incorrect start date');
        require(endDate > block.timestamp, 'Incorrect end date');
        require(totalTokensForSale > 0, 'Total tokens for sale cannot be zero');
        require(minAllocationAmount > 0, 'Min allocation amount cannot be zero');
        require(maxAllocationAmount > 0, 'Max allocation amount cannot be zero');
        require(priceInUSDT > 0, 'Price in USDT cannot be zero');
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
