// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from './Test.sol';
import { IIDO } from '../src/interfaces/IDO.interface.sol';
import { IDO } from '../src/IDO.sol';
import { Token } from '../src/Token.sol';

contract IdoTest is Test {
    IDO internal ido;
    Token internal presaleToken;
    struct DefaultParams {
        IIDO.CreatePresaleParams presaleParams;
        IIDO.ClaimSchedule[] claimsSchedule;
        address[] initialWhitelistedTokens;
        address[] initialWhitelistedWallets;
    }

    DefaultParams public defaultParams;

    function fixture() internal {
        vm.startPrank(deployer);

        ido = new IDO();

        presaleToken = new Token();

        IIDO.ClaimSchedule[] memory claimsSchedule = new IDO.ClaimSchedule[](1);
        claimsSchedule[0] = IIDO.ClaimSchedule({ availableFromDate: block.timestamp, percentage: 10 });

        address[] memory initialWhitelistedTokens = new address[](2);
        address[] memory initialWhitelistedWallets;

        address ethToken = address(0);
        address usdtToken = vm.envAddress('USDT_CONTRACT_ADDRESS');

        initialWhitelistedTokens[0] = ethToken;
        initialWhitelistedTokens[1] = usdtToken;

        defaultParams = DefaultParams({
            presaleParams: IIDO.CreatePresaleParams({
                startDate: block.timestamp,
                endDate: block.timestamp + 1 days,
                token: address(presaleToken),
                totalTokensForSale: 1_000_000 * (10 ** 18),
                minAllocationAmount: 10,
                maxAllocationAmount: 1000,
                claimStrategyId: 1,
                priceInUSDT: 1,
                isPublic: true
                }),
            claimsSchedule: claimsSchedule,
            initialWhitelistedTokens: initialWhitelistedTokens,
            initialWhitelistedWallets: initialWhitelistedWallets
        });

        presaleToken.transfer(bob, 1_000_000 * 1e18);
        
        ido.grantRole(ido.ADMIN_ROLE(), admin);
        vm.stopPrank();
    }

    function createPresale(DefaultParams storage params) internal {
        ido.createPresale(
            params.presaleParams,
            params.claimsSchedule,
            params.initialWhitelistedTokens,
            params.initialWhitelistedWallets
        );
    }
}
