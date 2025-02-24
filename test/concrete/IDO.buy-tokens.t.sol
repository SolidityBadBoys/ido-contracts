// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAccessControl } from '@openzeppelin/contracts/access/IAccessControl.sol';

import { Vm, console } from 'forge-std/Test.sol';

import { IdoTest } from '../IdoTest.sol';
import { IDO } from '../../src/IDO.sol';
import { IIDO } from '../../src/interfaces/IDO.interface.sol';
import '../../src/errors/errors.sol';

contract IdoBuyTokens is IdoTest {
    function setUp() external {
        fixture();

        deal(chuck, 500 ether);
    }

    function test_WhenPresaleDoesNotExists() external {
        vm.expectRevert(abi.encodeWithSelector(PresaleDoesNotExists.selector));
        vm.prank(chuck);
        ido.buy{ value: 0 }(1);
    }

    function test_WhenPresaleIsNotActive() external {
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);

        vm.expectRevert(abi.encodeWithSelector(PresaleIsNotActive.selector));
        vm.prank(chuck);
        ido.buy{ value: 0 }(presaleId);
    }

    function test_WhenAmountIsZero() external {
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);

        vm.startPrank(deployer);
        presaleToken.approve(address(ido), 100 * (10 ** 18));
        ido.deposit(presaleId, 100 * (10 ** 18));
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(CannotBeZero.selector));
        vm.prank(chuck);
        ido.buy{ value: 0 }(presaleId);
    }

    function test_WhenBuyPublicPresaleTokenWithEth() external {
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);

        vm.startPrank(deployer);
        presaleToken.approve(address(ido), 100);
        ido.deposit(presaleId, 100);
        vm.stopPrank();

        vm.startPrank(chuck);
        uint256 amount = defaultParams.presaleParams.priceInETH * 100;
        ido.buy{ value: amount }(presaleId);

        uint256 newPresaleTokenBalance = ido.getMyBalance(presaleId);
        assertEq(newPresaleTokenBalance, 100);
        vm.stopPrank();
    }

    function test_WhenBuyNonPublicPresaleTokenWithEth() external {
        address[] memory initialWhitelistedWallets = new address[](1);
        initialWhitelistedWallets[0] = address(chuck);

        defaultParams.presaleParams.isPublic = false;
        defaultParams.initialWhitelistedWallets = initialWhitelistedWallets;
        
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);

        vm.startPrank(deployer);
        uint256 depositedAmount = defaultParams.presaleParams.totalSupply;
        presaleToken.approve(address(ido), depositedAmount);
        ido.deposit(presaleId, depositedAmount);
        vm.stopPrank();

        vm.startPrank(chuck);
        uint256 amount = defaultParams.presaleParams.priceInETH * 100;
        ido.buy{ value: amount }(presaleId);

        uint256 newPresaleTokenBalance = ido.getMyBalance(presaleId);
        assertEq(newPresaleTokenBalance, 100);
        vm.stopPrank();
    }
}