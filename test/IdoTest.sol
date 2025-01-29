// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from './Test.sol';

import { IDO } from '../src/IDO.sol';
import { Token } from '../src/Token.sol';

contract IdoTest is Test {
    IDO internal ido;
    Token internal presaleToken;

    struct DefaultParams {
        uint256 startDate;
        uint256 endDate;
        address token;
        uint256 totalTokensForSale;
        uint256 minAllocationAmount;
        uint256 maxAllocationAmount;
        uint256 claimStrategyId;
        uint256 priceInUSDT;
        bool isPublic;
        IDO.ClaimSchedule[] claimsSchedule;
        address[]  initialWhitelistedTokens;
        address[]  initialWhitelistedWallets;
    }

    DefaultParams public defaultParams; 

    function fixture() internal {
        vm.startPrank(deployer);

        ido = new IDO();

        presaleToken = new Token();

        IDO.ClaimSchedule[] memory claimsSchedule = new IDO.ClaimSchedule[](1);
        claimsSchedule[0] = IDO.ClaimSchedule({ availableFromDate: block.timestamp, percentage: 10 });

        address[] memory initialWhitelistedTokens = new address[](2);
        address[] memory initialWhitelistedWallets;

        address ethToken = address(0);
        address usdtToken = vm.envAddress('USDT_CONTRACT_ADDRESS');

        initialWhitelistedTokens[0] = ethToken;
        initialWhitelistedTokens[1] = usdtToken;

        defaultParams = DefaultParams({
            startDate: block.timestamp,
            endDate: block.timestamp + 1 days,
            token: address(presaleToken),
            totalTokensForSale: 1_000_000 * (10 ** 18),
            minAllocationAmount: 10,
            maxAllocationAmount: 1000,
            claimStrategyId: 1,
            priceInUSDT: 1,
            isPublic: true,
            claimsSchedule: claimsSchedule,
            initialWhitelistedTokens: initialWhitelistedTokens,
            initialWhitelistedWallets: initialWhitelistedWallets
        });



        presaleToken.transfer(bob, 1_000_000 * 1e18);

        ido.setAdmin(admin);

        vm.stopPrank();
    }

    function createPresale(DefaultParams storage params) internal {



        ido.createPresale(
            params.startDate,
            params.endDate,
            params.token,
            params.totalTokensForSale,
            params.minAllocationAmount,
            params.maxAllocationAmount,
            params.claimStrategyId,
            params.priceInUSDT,
            params.claimsSchedule,
            params.initialWhitelistedTokens,
            params.initialWhitelistedWallets,
            params.isPublic
        );
    }
}
