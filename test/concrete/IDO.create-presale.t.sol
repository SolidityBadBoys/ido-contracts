// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAccessControl } from '@openzeppelin/contracts/access/IAccessControl.sol';

import { Vm, console } from 'forge-std/Test.sol';

import { IdoTest } from '../IdoTest.sol';
import { IDO } from '../../src/IDO.sol';
import '../../src/errors/errors.sol';
import { IIDO } from '../../src/interfaces/IDO.interface.sol';
import { MockNonErc20Token } from '../../src/MockNonErc20Token.sol';

/**
 * @title IdoCreatePresale
 * @dev Тестирование ошибок в функции createPresale
 */
contract IdoCreatePresale is IdoTest {
    function setUp() external {
        fixture();
    }

    function test_WhenAdminCreatePublicPresale() external {
        vm.prank(admin);

        vm.expectEmit(false, false, false, true);
        
        emit IIDO.PresaleCreated(1, defaultParams.presaleParams.token, defaultParams.presaleParams.totalSupply, defaultParams.presaleParams.isPublic);

        createPresale(defaultParams);

        vm.stopPrank();
    }

    function test_WhenAdminCreateNonPublicPresale() external {
        vm.prank(admin);

        defaultParams.presaleParams.isPublic = false;

        vm.expectEmit(false, false, false, true);
        
        emit IIDO.PresaleCreated(1, defaultParams.presaleParams.token, defaultParams.presaleParams.totalSupply, defaultParams.presaleParams.isPublic);

        createPresale(defaultParams);

        vm.stopPrank();
    }

    function test_WhenAdminCreateNonPublicPresaleWithInitialWallets() external {
        vm.prank(admin);

        address[] memory initialWhitelistedWallets = new address[](2);
        initialWhitelistedWallets[0] = bob;
        initialWhitelistedWallets[1] = alina;

        defaultParams.presaleParams.isPublic = false;
        defaultParams.initialWhitelistedWallets = initialWhitelistedWallets;

        vm.expectEmit(false, false, false, true);
        
        emit IIDO.PresaleCreated(1, defaultParams.presaleParams.token, defaultParams.presaleParams.totalSupply, defaultParams.presaleParams.isPublic);

        vm.recordLogs();
        createPresale(defaultParams);

        Vm.Log[] memory logs = vm.getRecordedLogs();

        uint256 presaleId = uint256(logs[0].topics[1]);

        bool isAlinaParticipant = ido.whitelistedWallets(presaleId, alina);
        bool isBobParticipant = ido.whitelistedWallets(presaleId, bob);

        assertEq(isAlinaParticipant, true, 'Alina should be whitelisted');
        assertEq(isBobParticipant, true, 'Bob should be whitelisted');

        vm.stopPrank();
    }

    function test_WhenCallerIsNotAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alina, ido.ADMIN_ROLE())
        );
        vm.prank(alina);
        createPresale(defaultParams);
        vm.stopPrank();
    }

    function test_WhenStartDateIsInPast() external {
        defaultParams.presaleParams.startDate = block.timestamp - 1;
        vm.expectRevert(abi.encodeWithSelector(IncorrectStartDate.selector));
        vm.prank(admin);
        createPresale(defaultParams);
        vm.stopPrank();
    }

    function test_WhenEndDateIsBeforeStartDate() external {
        defaultParams.presaleParams.endDate = defaultParams.presaleParams.startDate - 1;
        vm.expectRevert(abi.encodeWithSelector(IncorrectEndDate.selector));
        vm.prank(admin);
        createPresale(defaultParams);
        vm.stopPrank();
    }

    function test_WhenTokenAddressIsZero() external {
        defaultParams.presaleParams.token = address(0);
        vm.expectRevert(abi.encodeWithSelector(CannotBeZero.selector));
        vm.prank(admin);
        createPresale(defaultParams);
        vm.stopPrank();
    }

    function test_WhenTotalSupplyIsZero() external {
        defaultParams.presaleParams.totalSupply = 0; 
        vm.expectRevert(abi.encodeWithSelector(TokensForSaleAmountIsZero.selector));
        vm.prank(admin);
        createPresale(defaultParams);
        vm.stopPrank();
    }

    function test_WhenMinAllocationIsZero() external {
        defaultParams.presaleParams.minAllocationAmount = 0;
        vm.expectRevert(abi.encodeWithSelector(MinAllocationIsZero.selector));
        vm.prank(admin);
        createPresale(defaultParams);
        vm.stopPrank();
    }

    function test_WhenMaxAllocationIsZero() external {
        defaultParams.presaleParams.maxAllocationAmount = 0;
        vm.expectRevert(abi.encodeWithSelector(MaxAllocationIsZero.selector));
        vm.prank(admin);
        createPresale(defaultParams);
        vm.stopPrank();
    }

    function test_WhenPriceInUsdtIsZero() external {
        defaultParams.presaleParams.priceInUSDT = 0;
        vm.expectRevert(abi.encodeWithSelector(PriceInUsdtIsZero.selector));
        vm.prank(admin);
        createPresale(defaultParams);
        vm.stopPrank();
    }

    function test_WhenClaimScheduleIsEmpty() external {
        defaultParams.claimsSchedule = new IIDO.ClaimSchedule[](0);
        vm.expectRevert(abi.encodeWithSelector(EmptyClaimSchedule.selector));
        vm.prank(admin);
        createPresale(defaultParams);
        vm.stopPrank();
    }

    function test_WhenClaimStartDateIsInPast() external {
        defaultParams.claimsSchedule[0].availableFromDate = block.timestamp - 1;
        vm.expectRevert(abi.encodeWithSelector(IncorrectClaimStartDate.selector));
        vm.prank(admin);
        createPresale(defaultParams);
        vm.stopPrank();
    }

    function test_WhenClaimPercentageSumIsNot100() external {
        defaultParams.claimsSchedule[0].percentage = 50;
        vm.expectRevert(abi.encodeWithSelector(IncorrectClaimPercentageSum.selector));
        vm.prank(admin);
        createPresale(defaultParams);
        vm.stopPrank();
    }

    function test_WhenIsNotUsdtOrEth() external {
        MockNonErc20Token nonErc20Token = new MockNonErc20Token();
        defaultParams.initialWhitelistedTokens[0] = address(nonErc20Token);
        vm.expectRevert(abi.encodeWithSelector(NonAvailablePresaleToken.selector));
        vm.prank(admin);
        createPresale(defaultParams);
        vm.stopPrank();
    }
}
