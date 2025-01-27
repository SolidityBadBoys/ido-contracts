// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from './Test.sol';

import { IDO } from '../src/IDO.sol';
import { Token } from '../src/Token.sol';

contract IdoTest is Test {
    IDO internal ido;
    Token internal presaleToken;

    function fixture() internal {
        vm.startPrank(deployer);

        ido = new IDO();

        presaleToken = new Token();

        presaleToken.transfer(bob, 1_000_000 * 1e18);

        ido.setAdmin(admin);

        vm.stopPrank();
    }

    function createPresale(bool isPublic) internal {
        IDO.ClaimSchedule[] memory claimsSchedule = new IDO.ClaimSchedule[](1);
        claimsSchedule[0] = IDO.ClaimSchedule({ availableFromDate: block.timestamp, percentage: 10 });

        address[] memory initialWhitelistedTokens = new address[](2);
        address[] memory initialWhitelistedWallets;

        address ethToken = address(0);
        address usdtToken = vm.envAddress('USDT_CONTRACT_ADDRESS');

        initialWhitelistedTokens[0] = ethToken;
        initialWhitelistedTokens[1] = usdtToken;

        uint8 decimals = 18;
        uint256 startDate = block.timestamp;
        uint256 endDate = block.timestamp + 1 days;
        address token = address(presaleToken);
        uint256 totalTokensForSale = 1_000_000 * (10 ** decimals);
        uint256 minAllocationAmount = 10;
        uint256 maxAllocationAmount = 1000;
        uint256 claimStrategyId = 1;
        uint256 priceInUSDT = 1;
        ido.createPresale(
            startDate,
            endDate,
            token,
            totalTokensForSale,
            minAllocationAmount,
            maxAllocationAmount,
            claimStrategyId,
            priceInUSDT,
            claimsSchedule,
            initialWhitelistedTokens,
            initialWhitelistedWallets,
            isPublic
        );
    }
}
