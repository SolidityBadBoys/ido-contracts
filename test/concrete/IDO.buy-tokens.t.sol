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
        deal(address(usdtToken), alina, 100 * (10 ** usdtToken.decimals()));
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

    function test_WhenAmountIsZeroForEth() external {
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);

        vm.startPrank(deployer);
        presaleToken.approve(address(ido), 100 * (10 ** presaleToken.decimals()));
        ido.deposit(presaleId, 100 * (10 ** presaleToken.decimals()));
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(CannotBeZero.selector));
        vm.prank(chuck);
        ido.buy{ value: 0 }(presaleId);
    }


    function test_WhenAmountIsZeroForUsdt() external {
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);

        vm.startPrank(deployer);
        presaleToken.approve(address(ido), 100 * (10 ** presaleToken.decimals()));
        ido.deposit(presaleId, 100 * (10 ** presaleToken.decimals()));
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(CannotBeZero.selector));
        vm.prank(alina);
        ido.buy(presaleId, address(usdtToken), 0);
    }


    function test_WhenBuyPublicPresaleTokenWithEth() external {
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);

        vm.startPrank(deployer);
        presaleToken.approve(address(ido), 100 * (10 ** presaleToken.decimals()));
        ido.deposit(presaleId, 100 * (10 ** presaleToken.decimals()));
        vm.stopPrank();

        vm.startPrank(chuck);
        uint256 amount = defaultParams.presaleParams.priceInETH * 10;
        ido.buy{ value: amount }(presaleId);

        uint256 newPresaleTokenBalance = ido.getMyBalance(presaleId);
        assertEq(newPresaleTokenBalance, 10 * (10 ** presaleToken.decimals()));
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
        assertEq(newPresaleTokenBalance, 100 * (10 ** presaleToken.decimals()));
        vm.stopPrank();
    }

    function test_WhenBuyPublicPresaleTokenWithUsdt() external {
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);

        vm.startPrank(deployer);
        uint256 depositedAmount = defaultParams.presaleParams.totalSupply;
        presaleToken.approve(address(ido), depositedAmount);
        ido.deposit(presaleId, depositedAmount);
        vm.stopPrank();

        vm.startPrank(alina);
        uint256 amount = defaultParams.presaleParams.priceInUSDT * 100;
        usdtToken.approve(address(ido), amount);
        ido.buy(presaleId, address(usdtToken), 100 * (10 ** usdtToken.decimals()));
        
        uint256 newPresaleTokenBalance = ido.getMyBalance(presaleId);
        assertEq(newPresaleTokenBalance, 100 * (10 ** presaleToken.decimals()));
        vm.stopPrank();

    }

    function test_WhenBuyNonPublicPresaleTokenWithUsdt() external {
        address[] memory initialWhitelistedWallets = new address[](1);
        initialWhitelistedWallets[0] = address(alina);

        defaultParams.presaleParams.isPublic = false;
        defaultParams.initialWhitelistedWallets = initialWhitelistedWallets;

        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);

        vm.startPrank(deployer);
        uint256 depositedAmount = defaultParams.presaleParams.totalSupply;
        presaleToken.approve(address(ido), depositedAmount);
        ido.deposit(presaleId, depositedAmount);
        vm.stopPrank();

        vm.startPrank(alina);
        uint256 amount = defaultParams.presaleParams.priceInUSDT * 100;
        usdtToken.approve(address(ido), amount);
        ido.buy(presaleId, address(usdtToken), 100 * (10 ** usdtToken.decimals()));
        
        uint256 newPresaleTokenBalance = ido.getMyBalance(presaleId);
        assertEq(newPresaleTokenBalance, 100 * (10 ** presaleToken.decimals()));
        vm.stopPrank();
    }

    function test_WhenPresaleDoesNotExistsWithUsdt() external {
        uint256 decimals = usdtToken.decimals();
        
        vm.expectRevert(abi.encodeWithSelector(PresaleDoesNotExists.selector));

        vm.startPrank(alina);
        uint256 amount = 100 * (10 ** decimals);
        ido.buy(1, address(usdtToken), amount);
        vm.stopPrank();
    }

    function test_WhenPresaleIsNotActiveWithUsdt() external {
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);
    
        uint256 decimals = usdtToken.decimals();

        vm.expectRevert(abi.encodeWithSelector(PresaleIsNotActive.selector));

        vm.startPrank(alina);
        uint256 amount = 100 * (10 ** decimals);
        ido.buy(presaleId, address(usdtToken), amount);
        vm.stopPrank();
    }
}
