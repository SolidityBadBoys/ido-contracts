// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IdoTest } from '../IdoTest.sol';
import '../../src/errors/errors.sol';
import { IIDO } from '../../src/interfaces/IDO.interface.sol';

/**
 * @title IdoClaimTokens
 * @dev Тестирование ошибок в функции claim
 */
contract IdoClaimTokens is IdoTest {
    function setUp() external {
        fixture();

        deal(chuck, 500 ether);
    }

    function test_WhenPresaleDoesNotExists() external {
        vm.expectRevert(abi.encodeWithSelector(PresaleDoesNotExists.selector));
        vm.prank(chuck);
        ido.claim(113);
    }

    function test_WhenPresaleIsNotActive() external {
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);

        vm.expectRevert(abi.encodeWithSelector(PresaleIsNotActive.selector));
        vm.prank(chuck);
        ido.claim(presaleId);
    }

    function test_CaseWithReentrancy() external {}

    function test_SuccessfulClaim() external {
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);
        
        vm.startPrank(deployer);
        presaleToken.approve(address(ido), 100 * (10 ** presaleToken.decimals()));
        ido.deposit(presaleId, 100 * (10 ** presaleToken.decimals()));
        vm.stopPrank();

        vm.startPrank(chuck);
        uint256 amount = defaultParams.presaleParams.priceInETH * 100;
        ido.buy{ value: amount }(presaleId);

        ido.claim(presaleId);

        uint256 finalBalance = presaleToken.balanceOf(chuck);
        assertEq(finalBalance, 100 * (10 ** presaleToken.decimals()));

        vm.stopPrank();
    }

    function test_WhenClaimIsNotAvailable() external {
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);

        vm.startPrank(deployer);
        presaleToken.approve(address(ido), 100 * (10 ** presaleToken.decimals()));
        ido.deposit(presaleId, 100 * (10 ** presaleToken.decimals()));
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(ClaimIsNotAvailable.selector));
        vm.prank(alina);
        ido.claim(presaleId);
    }

    function test_WhenAllocationIsAlreadyClaimed() external {
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);
        
        vm.startPrank(deployer);
        presaleToken.approve(address(ido), 100 * (10 ** presaleToken.decimals()));
        ido.deposit(presaleId, 100 * (10 ** presaleToken.decimals()));
        vm.stopPrank();

        vm.startPrank(chuck);
        uint256 amount = defaultParams.presaleParams.priceInETH * 100;
        ido.buy{ value: amount }(presaleId);

        ido.claim(presaleId);

        vm.expectRevert(abi.encodeWithSelector(AllocationAlreadyClaimed.selector));
        ido.claim(presaleId);

        vm.stopPrank();
    }

    function test_WhenAvalableAllocationIsAlreadyClaimed() external {
        IIDO.ClaimSchedule[] memory claimsSchedule = new IIDO.ClaimSchedule[](2);
        claimsSchedule[0] = IIDO.ClaimSchedule({ availableFromDate: block.timestamp, percentage: 50 });
        claimsSchedule[1] = IIDO.ClaimSchedule({ availableFromDate: block.timestamp + 1 days, percentage: 50 });

        vm.startPrank(admin);
        uint256 claimStrategyId = ido.createClaimStrategy(claimsSchedule);
        defaultParams.presaleParams.claimStrategyId = claimStrategyId;
        uint256 presaleId = createPresaleWithId(defaultParams);
        vm.stopPrank();

        vm.startPrank(deployer);
        presaleToken.approve(address(ido), 100 * (10 ** presaleToken.decimals()));
        ido.deposit(presaleId, 100 * (10 ** presaleToken.decimals()));
        vm.stopPrank();

        vm.startPrank(chuck);
        uint256 amount = defaultParams.presaleParams.priceInETH * 100;
        ido.buy{ value: amount }(presaleId);

        ido.claim(presaleId);

        vm.expectRevert(abi.encodeWithSelector(AllocationIsNotAvailable.selector));
        ido.claim(presaleId);

        vm.stopPrank();
    }

    function test_SuccessfulMultipleClaim() external {
        IIDO.ClaimSchedule[] memory claimsSchedule = new IIDO.ClaimSchedule[](2);
        claimsSchedule[0] = IIDO.ClaimSchedule({ availableFromDate: block.timestamp, percentage: 50 });
        claimsSchedule[1] = IIDO.ClaimSchedule({ availableFromDate: block.timestamp + 1 days, percentage: 50 });

        vm.startPrank(admin);
        uint256 claimStrategyId = ido.createClaimStrategy(claimsSchedule);
        defaultParams.presaleParams.claimStrategyId = claimStrategyId;
        uint256 presaleId = createPresaleWithId(defaultParams);
        vm.stopPrank();

        vm.startPrank(deployer);
        presaleToken.approve(address(ido), 100 * (10 ** presaleToken.decimals()));
        ido.deposit(presaleId, 100 * (10 ** presaleToken.decimals()));
        vm.stopPrank();

        vm.startPrank(chuck);
        uint256 amount = defaultParams.presaleParams.priceInETH * 100;
        ido.buy{ value: amount }(presaleId);

        ido.claim(presaleId);

        vm.warp(block.timestamp + 1 days);
        ido.claim(presaleId);

        vm.stopPrank();
    }
}