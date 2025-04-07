// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import { IdoTest } from '../IdoTest.sol';
import { IDO } from '../../src/IDO.sol';
import '../../src/errors/errors.sol';
import { IIDO } from '../../src/interfaces/IDO.interface.sol';
import { MockNonErc20Token } from '../../src/MockNonErc20Token.sol';

/**
 * @title IdoCreateClaimStrategy
 * @dev Тестирование ошибок в функции createClaimStrategy
 */
contract IdoCreateClaimStrategy is IdoTest {
    function setUp() external {
        fixture();
    }

    function test_WhenClaimScheduleIsEmpty() external {
        IIDO.ClaimSchedule[] memory claimsSchedule = new IIDO.ClaimSchedule[](0);
        vm.expectRevert(abi.encodeWithSelector(EmptyClaimSchedule.selector));
        vm.prank(admin);
        ido.createClaimStrategy(claimsSchedule);
        vm.stopPrank();
    }

    function test_WhenClaimStartDateIsInPast() external {
        IIDO.ClaimSchedule[] memory claimsSchedule = new IIDO.ClaimSchedule[](1);
        claimsSchedule[0] = IIDO.ClaimSchedule({
            availableFromDate: block.timestamp - 1,
            percentage: 100
        });
        vm.expectRevert(abi.encodeWithSelector(IncorrectClaimStartDate.selector));
        vm.prank(admin);
        ido.createClaimStrategy(claimsSchedule);
        vm.stopPrank();
    }

    function test_WhenClaimPercentageSumIsNot100() external {
        IIDO.ClaimSchedule[] memory claimsSchedule = new IIDO.ClaimSchedule[](1);
        claimsSchedule[0] = IIDO.ClaimSchedule({
            availableFromDate: block.timestamp,
            percentage: 50
        });
        vm.expectRevert(abi.encodeWithSelector(IncorrectClaimPercentageSum.selector));
        vm.prank(admin);
        createPresale(defaultParams);
        vm.stopPrank();
    }

}
