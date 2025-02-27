// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Vm } from 'forge-std/Test.sol';
import { console } from 'forge-std/console.sol';

import { Test } from './Test.sol';
import { IIDO } from '../src/interfaces/IDO.interface.sol';
import { IDO } from '../src/IDO.sol';
import { Token } from '../src/Token.sol';
import { PresaleStatus } from '../src/enums/presale-status.enum.sol';

contract IdoTest is Test {
    IDO internal ido;
    Token internal presaleToken;
    Token internal usdtToken;

    struct DefaultParams {
        IIDO.CreatePresaleParams presaleParams;
        IIDO.ClaimSchedule[] claimsSchedule;
        address[] initialWhitelistedTokens;
        address[] initialWhitelistedWallets;
    }

    DefaultParams public defaultParams;

    function fixture() internal {
        vm.startPrank(deployer);

        usdtToken = new Token();

        ido = new IDO(address(usdtToken));

        presaleToken = new Token();

        IIDO.ClaimSchedule[] memory claimsSchedule = new IDO.ClaimSchedule[](1);
        claimsSchedule[0] = IIDO.ClaimSchedule({ availableFromDate: block.timestamp, percentage: 100 });

        address[] memory initialWhitelistedTokens = new address[](2);
        address[] memory initialWhitelistedWallets;

        address ethToken = address(0);

        initialWhitelistedTokens[0] = ethToken;
        initialWhitelistedTokens[1] = address(usdtToken);

        defaultParams = DefaultParams({
            presaleParams: IIDO.CreatePresaleParams({
                startDate: block.timestamp,
                endDate: block.timestamp + 1 days,
                token: address(presaleToken),
                totalSupply: 1_000_000 * (10 ** presaleToken.decimals()),
                minAllocationAmount: 10 * (10 ** presaleToken.decimals()),
                maxAllocationAmount: 1000 * (10 ** presaleToken.decimals()),
                claimStrategyId: 1,
                priceInUSDT: 1 * (10 ** usdtToken.decimals()),
                priceInETH: 0.1 ether,
                isPublic: true
            }),
            claimsSchedule: claimsSchedule,
            initialWhitelistedTokens: initialWhitelistedTokens,
            initialWhitelistedWallets: initialWhitelistedWallets
        });

        presaleToken.transfer(deployer, 1_000_000 * (10 ** presaleToken.decimals()));

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

    function createPresaleWithId(DefaultParams storage params) internal returns (uint256) {
        vm.recordLogs();

        try
            ido.createPresale(
                params.presaleParams,
                params.claimsSchedule,
                params.initialWhitelistedTokens,
                params.initialWhitelistedWallets
            )
        {
            Vm.Log[] memory logs = vm.getRecordedLogs();
            require(logs.length > 0, 'No logs found after presale creation');
            uint256 presaleId = uint256(logs[0].topics[1]);
            return presaleId;
        } catch {
            revert('Create presale failed: Vadim transaction was reverted');
        }
    }
}
