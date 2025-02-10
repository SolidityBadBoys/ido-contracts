// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { MockNonErc20Token } from '../../src/MockNonErc20Token.sol';
import { Token } from '../../src/Token.sol';
import { IdoTest } from '../IdoTest.sol';
import { IDO } from '../../src/IDO.sol';
import '../../src/errors/errors.sol';

/**
 * @title IdoDeployContract
 * @dev Test IDO contract deploying
 */
contract IdoDeployContract is IdoTest {
    function test_WhenIdoInitialAddressIsErc20() external {
        vm.prank(deployer);

        Token usdtToken = new Token();
        new IDO(address(usdtToken));      

        vm.stopPrank();
    }

        function test_WhenIdoInitialAddressIsNotContract() external {    
        vm.expectRevert(abi.encodeWithSelector(AddressIsNotContract.selector));
        
        vm.prank(deployer);
        new IDO(address(0));

        vm.stopPrank();
    }

    function test_WhenIdoInitialAddressIsNonErc20() external {    
        vm.startPrank(deployer);
        MockNonErc20Token nonErc20Token = new MockNonErc20Token();
        vm.expectRevert(abi.encodeWithSelector(AddressIsNonErc20.selector));
        new IDO(address(nonErc20Token));
        vm.stopPrank();
    }

}