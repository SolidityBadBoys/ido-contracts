// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { PresaleStatus } from '../enums/presale-status.enum.sol';

interface IIDO {
    struct CreatePresaleParams {
        uint256 startDate;
        uint256 endDate;
        address token;
        uint256 totalTokensForSale;
        uint256 minAllocationAmount;
        uint256 maxAllocationAmount;
        uint256 claimStrategyId;
        uint256 priceInUSDT;
        bool isPublic;
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

    struct Balance {
        uint256 presaleId;
        uint256 allocatedAmount;
        uint256 claimedAmount;
    }

    struct ClaimStrategy {
        uint256 strategyId;
    }

    struct ClaimSchedule {
        uint256 availableFromDate;
        uint256 percentage;
    }

    event PresaleCreated(uint256 indexed presaleId, address token, uint256 totalTokensForSale, bool isPublic);

    function withdraw(address token, uint256 amount, address recipient) external;
    function toggleWhitelistedMode(uint256 presaleId, bool isPublic) external;
    function addParticipantsToWhitelist(uint256 presaleId, address[] calldata participants) external;
    function disableParticipantsInWhitelist(uint256 presaleId, address[] calldata participants) external;
    function addTokensToWhitelist(uint256 presaleId, address[] calldata tokens) external;
    function disableTokensInWhitelist(uint256 presaleId, address[] calldata tokens) external;
    function createPresale(
        CreatePresaleParams calldata presaleParams,
        ClaimSchedule[] calldata claimsSchedule,
        address[] calldata initialWhitelistedTokens,
        address[] calldata initialWhitelistedWallets

    ) external;

    // function getPresaleInfo(uint256 presaleId) external view returns (PresaleInfo memory);
    // function getBalance(address participant, uint256 presaleId) external view returns (Balance memory);
}