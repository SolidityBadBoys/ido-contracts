// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IdoTest } from '../IdoTest.sol';
import { console } from 'forge-std/Test.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import '../../src/errors/errors.sol';

/**
 * @title IdoBurnTokens
 * @dev Тестирование ошибок в функции burnTokens
 */
contract IdoBurnTokens is IdoTest {
    function setUp() external {
        fixture();
    }

    function test_WhenAmountIsZero() external {
        vm.startPrank(deployer);
        uint256 tokenBalance = presaleToken.balanceOf(address(ido));
        vm.expectRevert(abi.encodeWithSelector(CannotBeZero.selector));
        ido.burnTokens(address(presaleToken), tokenBalance);
        vm.stopPrank();
    }

    function test_WhenCallerIsNotOwner() external {
        vm.prank(deployer);
        presaleToken.transfer(address(ido), 1_000_000 * (10 ** 18));

        vm.startPrank(chuck);
        uint256 tokenBalance = presaleToken.balanceOf(address(ido));
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, chuck)
        );
        ido.burnTokens(address(presaleToken), tokenBalance);
        vm.stopPrank();
    }

    function test_WhenOwnerBurnTokens() external {
        vm.startPrank(deployer);
        presaleToken.transfer(address(ido), 1_000_000 * (10 ** 18));
        uint256 tokenBalanceBefore = presaleToken.balanceOf(address(ido));
        ido.burnTokens(address(presaleToken), tokenBalanceBefore);
        uint256 tokenBalanceAfter = presaleToken.balanceOf(address(ido));
        assertEq(tokenBalanceAfter, 0, 'IDO contract balance should be 0 after burning');
        vm.stopPrank();
    }
}