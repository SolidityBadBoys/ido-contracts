// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;
import { ERC20Burnable } from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import { ReentrancyGuard } from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { AccessControl } from '@openzeppelin/contracts/access/AccessControl.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IERC20Metadata } from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Address } from '@openzeppelin/contracts/utils/Address.sol';

import { PresaleStatus } from './enums/presale-status.enum.sol';
import './errors/errors.sol';
import './interfaces/IDO.interface.sol';

contract IDO is IIDO, Ownable, AccessControl, ReentrancyGuard {
    /// @dev SafeERC20 is a wrapper around IERC20 that reverts if the transfer fails
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

    uint256 private constant MAX_VALUE_OF_ID = 99999999999999;
    uint256 private constant MULTIPLIER_PERCENTAGE = 100;

    IERC20 public immutable USDT_CONTRACT_ADDRESS;

    mapping(uint256 claimStrategyId => ClaimSchedule[] claimsSchedule) public claimStrategies;
    mapping(uint256 presaleId => PresaleInfo) public presales;
    mapping(address => Balance[]) public contributions;
    mapping(uint256 presaleId => mapping(address => bool)) public whitelistedTokens;
    mapping(uint256 presaleId => mapping(address => bool)) public whitelistedWallets;

    modifier onlyActivePresale(uint256 presaleId) {
        if (!presales[presaleId].isExists) revert PresaleDoesNotExists();
        if (presales[presaleId].status != PresaleStatus.ACTIVE) revert PresaleIsNotActive();
        _;
    }

    constructor(address usdtContractAddress) Ownable(_msgSender()) {
        if (!isContract(usdtContractAddress)) revert AddressIsNotContract();

        try IERC20(usdtContractAddress).totalSupply() returns (uint256 totalSupply) {
            totalSupply;
        } catch {
            revert AddressIsNonErc20();
        }

        USDT_CONTRACT_ADDRESS = IERC20(usdtContractAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function withdraw(address token, uint256 amount, address recipient) external onlyOwner {
        if (recipient == address(0)) revert CannotBeZero();

        if (token == address(0)) {
            Address.sendValue(payable(recipient), amount);
        } else {
            IERC20(token).safeTransfer(recipient, amount);
        }
    }

    function deposit(uint256 presaleId, uint256 amount) external onlyOwner {
        if (amount == 0) revert CannotBeZero();

        PresaleInfo storage presale = presales[presaleId];
        if (!presale.isExists) revert PresaleDoesNotExists();

        IERC20(presale.token).safeTransferFrom(msg.sender, address(this), amount);

        presale.status = PresaleStatus.ACTIVE;
        presale.isDeposited = true;

        emit TokensDeposited(presaleId, presale.token, amount);
    }

    function toggleWhitelistedMode(uint256 presaleId, bool isPublic) external onlyRole(ADMIN_ROLE) {
        PresaleInfo storage presale = presales[presaleId];
        if (!presale.isExists) revert PresaleDoesNotExists();

        presale.isPublic = isPublic;
    }

    function addParticipantsToWhitelist(
        uint256 presaleId,
        address[] calldata participants
    ) external onlyRole(ADMIN_ROLE) onlyActivePresale(presaleId) {
        _validateAddressesArray(participants);

        if (presales[presaleId].isPublic == true) revert PublicPresaleCantBeWhitelisted();

        uint256 length = participants.length;
        for (uint256 i = 0; i < length; i++) {
            address participant = participants[i];
            whitelistedWallets[presaleId][participant] = true;
        }
    }

    function disableParticipantsInWhitelist(
        uint256 presaleId,
        address[] calldata participants
    ) external onlyRole(ADMIN_ROLE) onlyActivePresale(presaleId) {
        _validateAddressesArray(participants);

        if (presales[presaleId].isPublic == true) revert PublicPresaleCantBeWhitelisted();

        uint256 length = participants.length;
        for (uint256 i = 0; i < length; i++) {
            if (!whitelistedWallets[presaleId][participants[i]]) revert WalletIsNotWhitelisted();
            whitelistedWallets[presaleId][participants[i]] = false;
        }
    }

    function addTokensToWhitelist(
        uint256 presaleId,
        address[] calldata tokens
    ) external onlyRole(ADMIN_ROLE) onlyActivePresale(presaleId) {
        _validateAddressesArray(tokens);

        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i++) {
            address token = tokens[i];
            _validateToken(token);
            whitelistedTokens[presaleId][token] = true;
        }
    }

    function disableTokensInWhitelist(
        uint256 presaleId,
        address[] calldata tokens
    ) external onlyRole(ADMIN_ROLE) onlyActivePresale(presaleId) {
        _validateAddressesArray(tokens);

        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i++) {
            if (!whitelistedTokens[presaleId][tokens[i]]) revert TokenIsNotWhitelisted();

            whitelistedTokens[presaleId][tokens[i]] = false;
        }
    }

    function createPresale(
        CreatePresaleParams calldata presaleParams,
        address[] calldata initialWhitelistedTokens,
        address[] calldata initialWhitelistedWallets
    ) external onlyRole(ADMIN_ROLE) {
        uint256 presaleId = _getRandomNumber(MAX_VALUE_OF_ID);

        _validatePresaleInitialData(
            presaleParams.startDate,
            presaleParams.endDate,
            presaleParams.token,
            presaleParams.totalSupply,
            presaleParams.minAllocationAmount,
            presaleParams.maxAllocationAmount,
            presaleParams.priceInUSDT,
            presaleParams.priceInETH
        );

        _addWhitelistedTokens(presaleId, initialWhitelistedTokens);

        if (presaleParams.isPublic == false) {
            _addWhitelistedWallets(presaleId, initialWhitelistedWallets);
        }

        PresaleInfo memory presale = PresaleInfo({
            id: presaleId,
            startDate: presaleParams.startDate,
            endDate: presaleParams.endDate,
            token: presaleParams.token,
            totalSupply: presaleParams.totalSupply,
            remainedSupply: presaleParams.totalSupply,
            minAllocationAmount: presaleParams.minAllocationAmount,
            maxAllocationAmount: presaleParams.maxAllocationAmount,
            status: PresaleStatus.PENDING,
            isPublic: presaleParams.isPublic,
            claimStrategyId: presaleParams.claimStrategyId,
            priceInUSDT: presaleParams.priceInUSDT,
            priceInETH: presaleParams.priceInETH,
            isExists: true,
            isDeposited: false
        });

        presales[presaleId] = presale;

        emit PresaleCreated(presaleId, presaleParams.token, presaleParams.totalSupply, presaleParams.isPublic);
    }

    function buy(uint256 presaleId) external payable onlyActivePresale(presaleId) {
        if (msg.value == 0) revert CannotBeZero();

        PresaleInfo storage presale = presales[presaleId];
        uint256 estimatedTokensAmount = ((msg.value * (10 ** 18)) / presale.priceInETH);

        // @TODO: Вынести в util функцию
        _validateAndUpdateBalance(presaleId, estimatedTokensAmount, presale);
        presale.remainedSupply -= estimatedTokensAmount;
        emit AllocationBought(presaleId, msg.sender, estimatedTokensAmount);
    }

    function buy(uint256 presaleId, address token, uint256 amount) external onlyActivePresale(presaleId) {
        if (amount == 0) revert CannotBeZero();

        _validateToken(token);

        PresaleInfo storage presale = presales[presaleId];
        uint256 estimatedTokensAmount = (amount * (10 ** IERC20Metadata(token).decimals())) / presale.priceInUSDT;

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        
        // @TODO: Вынести в util функцию (повторяется код)
        _validateAndUpdateBalance(presaleId, estimatedTokensAmount, presale);
        presale.remainedSupply -= estimatedTokensAmount;
        emit AllocationBought(presaleId, msg.sender, estimatedTokensAmount);
    }

    function claim(uint256 presaleId) external onlyActivePresale(presaleId) nonReentrant() {
        PresaleInfo memory presale = presales[presaleId];

        (uint256 index, bool found) = _findBalanceIndex(msg.sender, presaleId);
        if(!found) revert ClaimIsNotAvailable();

        uint256 claimable = _calculateClaimableAmount(presale, index);

        IERC20(presale.token).safeTransferFrom(address(this), msg.sender, claimable);
    }

    function createClaimStrategy(
        ClaimSchedule[] calldata claimsSchedule
    ) external onlyRole(ADMIN_ROLE) returns (uint256) {
        _validateSchedule(claimsSchedule);
        
        uint256 claimStrategyId = _getRandomNumber(MAX_VALUE_OF_ID);

       claimStrategies[claimStrategyId] = claimsSchedule;

        return claimStrategyId;
    }

    function getAvailableClaimAmount(uint256 presaleId) external view returns (uint256) {
        PresaleInfo memory presale = presales[presaleId];

        (uint256 index, bool found) = _findBalanceIndex(msg.sender, presaleId);
        if(!found) revert ClaimIsNotAvailable();

        Balance storage presaleBalance = contributions[msg.sender][index];
        if (presaleBalance.claimedAmount >= presaleBalance.allocatedAmount) return 0;

        uint256 totalClaimablePercentage;

        ClaimSchedule[] memory presaleClaimStrategies = claimStrategies[presale.claimStrategyId];

        uint256 length = presaleClaimStrategies.length;
        for (uint256 i = 0; i < length; i++) {
            ClaimSchedule memory presaleClaimStrategy = presaleClaimStrategies[i];

            if (presaleClaimStrategy.availableFromDate <= block.timestamp) {
                totalClaimablePercentage += presaleClaimStrategy.percentage;
            }
        }

        uint256 claimable = (presaleBalance.allocatedAmount / MULTIPLIER_PERCENTAGE * totalClaimablePercentage) - presaleBalance.claimedAmount;
        if (claimable == 0) revert AllocationAlreadyClaimed();

        return claimable; 
    }

    function _calculateClaimableAmount(PresaleInfo memory presale, uint256 index) private returns (uint256) {
        Balance storage presaleBalance = contributions[msg.sender][index];
        if (presaleBalance.claimedAmount >= presaleBalance.allocatedAmount) revert AllocationAlreadyClaimed();

        uint256 totalClaimablePercentage;

        ClaimSchedule[] memory presaleClaimStrategies = claimStrategies[presale.claimStrategyId];

        uint256 length = presaleClaimStrategies.length;
        for (uint256 i = 0; i < length; i++) {
            ClaimSchedule memory presaleClaimStrategy = presaleClaimStrategies[i];

            if (presaleClaimStrategy.availableFromDate <= block.timestamp) {
                totalClaimablePercentage += presaleClaimStrategy.percentage;
            }
        }

        uint256 claimable = (presaleBalance.allocatedAmount / MULTIPLIER_PERCENTAGE * totalClaimablePercentage) - presaleBalance.claimedAmount;
        if (claimable == 0) revert AllocationAlreadyClaimed();

        presaleBalance.claimedAmount += claimable;
        return claimable;
    }

    function _validateAndUpdateBalance(
        uint256 presaleId,
        uint256 estimatedTokensAmount,
        PresaleInfo storage presale
    ) private {
        if (!presale.isPublic && whitelistedWallets[presaleId][msg.sender] != true) {
            revert WalletIsNotWhitelisted();
        }

        Balance[] storage userBalances = contributions[msg.sender];
        uint256 balancesLength = userBalances.length;

        bool found = false;
        uint256 allocatedAmount = 0;

        for (uint256 i = 0; i < balancesLength; i++) {
            Balance storage userBalance = userBalances[i];
            if (userBalance.presaleId == presaleId) {
                allocatedAmount += userBalance.allocatedAmount;
                userBalance.allocatedAmount += estimatedTokensAmount;
                found = true;
                break;
            }
        }

        _validatePresaleTokenBuyAmount(estimatedTokensAmount, presale, allocatedAmount);

        if (!found) {
            userBalances.push(
                Balance({ presaleId: presaleId, allocatedAmount: estimatedTokensAmount, claimedAmount: 0 })
            );
        }

        presale.remainedSupply -= estimatedTokensAmount;
        emit AllocationBought(presaleId, msg.sender, estimatedTokensAmount);
    }

    function getMyBalance(uint256 presaleId) external view returns (uint256) {
        if (!presales[presaleId].isExists) revert PresaleDoesNotExists();

        Balance[] storage userBalances = contributions[msg.sender];
        uint256 balancesLength = userBalances.length;

        for (uint256 i = 0; i < balancesLength; i++) {
            Balance storage userBalance = userBalances[i];
            if (userBalance.presaleId == presaleId) {
                return userBalance.allocatedAmount;
            }
        }

        return 0;
    }

    function burnTokens(address token, uint256 amount) external onlyOwner {
        if (amount == 0) revert CannotBeZero();
        if (IERC20(token).balanceOf(address(this)) < amount) revert InsufficientBalance();

        ERC20Burnable(token).burn(amount);
    }

    function _validatePresaleTokenBuyAmount(
        uint256 estimatedTokensAmount,
        PresaleInfo storage presale,
        uint256 allocatedAmount
    ) private view {
        if (estimatedTokensAmount < presale.minAllocationAmount) revert AmountIsLessThanMinAllocation();
        if (estimatedTokensAmount + allocatedAmount > presale.maxAllocationAmount)
            revert AmountIsMoreThanMaxAllocation();
        if (estimatedTokensAmount > presale.remainedSupply) revert AmountIsMoreThanMaxRemainedSupply();
    }

    function _validateAddressesArray(address[] calldata array) private pure {
        if (array.length <= 0) revert ArrayIsEmpty();
    }

    function _getRandomNumber(uint256 max) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, _msgSender()))) % max;
    }

    function _validateSchedule(ClaimSchedule[] calldata claimsSchedule) private view {
        uint256 totalClaimsSchedulePercentage = 0;
        uint256 length = claimsSchedule.length;

        if (length == 0) revert EmptyClaimSchedule();

        for (uint256 i = 0; i < length; ) {
            ClaimSchedule memory claimSchedule = claimsSchedule[i];
            if (block.timestamp > claimsSchedule[i].availableFromDate) revert IncorrectClaimStartDate();

            // Optimize gas
            unchecked {
                totalClaimsSchedulePercentage += claimSchedule.percentage;
            }

            // Optimize gas
            unchecked {
                ++i;
            }
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
        uint256 priceInUSDT,
        uint256 priceInETH
    ) private view {
        if (token == address(0)) revert CannotBeZero();
        if (startDate < block.timestamp) revert IncorrectStartDate();
        if (endDate <= block.timestamp) revert IncorrectEndDate();
        if (totalTokensForSale == 0) revert TokensForSaleAmountIsZero();
        if (minAllocationAmount == 0) revert MinAllocationIsZero();
        if (maxAllocationAmount == 0) revert MaxAllocationIsZero();
        if (priceInUSDT == 0) revert PriceInUsdtIsZero();
        if (priceInETH == 0) revert PriceInEthIsZero();
    }

    function _addWhitelistedTokens(uint256 presaleId, address[] calldata tokens) private {
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i++) {
            address token = tokens[i];
            _validateToken(token);
            whitelistedTokens[presaleId][token] = true;
        }
    }

    function _addWhitelistedWallets(uint256 presaleId, address[] calldata wallets) private {
        uint256 length = wallets.length;
        for (uint256 i = 0; i < length; i++) {
            address wallet = wallets[i];
            if (wallet == address(0)) revert CannotBeZero();
            whitelistedWallets[presaleId][wallet] = true;
        }
    }

    function _validateToken(address token) private view {
        if (token != address(0) && token != address(USDT_CONTRACT_ADDRESS)) revert NonAvailablePresaleToken();
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function _findBalanceIndex(address participant, uint256 presaleId) private view returns (uint256 foundIndex, bool isFound) {
        Balance[] storage userContributions = contributions[participant];

        uint256 length = userContributions.length;
         for (uint256 i = 0; i < length; i++) {
            if (userContributions[i].presaleId == presaleId) {
                return (i, true);
            }
         }

        return (0, false);
    }
}