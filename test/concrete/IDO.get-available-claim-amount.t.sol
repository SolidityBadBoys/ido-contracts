// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IdoTest } from '../IdoTest.sol';
import { IIDO } from '../../src/interfaces/IDO.interface.sol';
import '../../src/errors/errors.sol';

/**
 * @title IdoGetAvailableClaimAmount
 * @dev
 */
contract IdoGetAvailableClaimAmount is IdoTest {
    function setUp() external {
        fixture();

        deal(chuck, 500 ether);
    }

    function test_WhenPresaleDoesNotExists() external {
        vm.expectRevert(abi.encodeWithSelector(PresaleDoesNotExists.selector));
        vm.prank(chuck);
        ido.getAvailableClaimAmount(113);
    }

    function test_WhenAddressPresaleIsNotActive() external {
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);

        vm.expectRevert(abi.encodeWithSelector(PresaleIsNotActive.selector));

        vm.prank(carol);
        ido.getAvailableClaimAmount(presaleId);
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

        uint256 availableAmount = ido.getAvailableClaimAmount(presaleId);
        assertEq(availableAmount, 0, 'Claimable amount should be 0');

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

        uint256 claimableAmount = ido.getAvailableClaimAmount(presaleId);
        assertEq(claimableAmount, 0, 'Claimable amount should be 0');

        vm.stopPrank();
    }

    function test_ReturnsFullClaimAmount_When100PercentUnlocked() external {
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);

        uint256 totalToDeposit = 100 * (10 ** presaleToken.decimals());

        vm.startPrank(deployer);
        presaleToken.approve(address(ido), totalToDeposit);
        ido.deposit(presaleId, totalToDeposit);
        vm.stopPrank();

        vm.startPrank(chuck);
        uint256 amount = defaultParams.presaleParams.priceInETH * 100;
        ido.buy{ value: amount }(presaleId);
        vm.stopPrank();

        vm.prank(chuck);
        uint256 available = ido.getAvailableClaimAmount(presaleId);

        assertEq(available, 100 * (10 ** presaleToken.decimals()), 'Should be full amount available');
    }

    function test_ReturnsPartialClaim_WhenVestingScheduleIsSplit() external {
        IIDO.ClaimSchedule[] memory splitSchedule = new IIDO.ClaimSchedule[](2);
        splitSchedule[0] = IIDO.ClaimSchedule({ availableFromDate: block.timestamp, percentage: 50 });
        splitSchedule[1] = IIDO.ClaimSchedule({ availableFromDate: block.timestamp + 1 days, percentage: 50 });

        vm.startPrank(admin);
        uint256 splitClaimStrategyId = ido.createClaimStrategy(splitSchedule);

        defaultParams.presaleParams.claimStrategyId = splitClaimStrategyId;

        uint256 presaleId = createPresaleWithId(defaultParams);

        uint256 totalToDeposit = 100 * (10 ** presaleToken.decimals());
        vm.stopPrank();

        vm.startPrank(deployer);
        presaleToken.approve(address(ido), totalToDeposit);
        ido.deposit(presaleId, totalToDeposit);
        vm.stopPrank();

        vm.startPrank(chuck);
        uint256 amount = defaultParams.presaleParams.priceInETH * 100;
        ido.buy{ value: amount }(presaleId);
        vm.stopPrank();

        uint256 expected = 50 * (10 ** presaleToken.decimals());

        vm.prank(chuck);
        uint256 available = ido.getAvailableClaimAmount(presaleId);

        assertEq(available, expected, 'Should return only 50% as available claim');
    }
}
