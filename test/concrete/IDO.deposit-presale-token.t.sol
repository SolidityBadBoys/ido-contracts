// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAccessControl } from '@openzeppelin/contracts/access/IAccessControl.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

import { Vm, console } from 'forge-std/Test.sol';

import { IdoTest } from '../IdoTest.sol';
import { IDO } from '../../src/IDO.sol';
import '../../src/errors/errors.sol';
import '../../src/enums/presale-status.enum.sol';
import { IIDO } from '../../src/interfaces/IDO.interface.sol';
import { MockNonErc20Token } from '../../src/MockNonErc20Token.sol';

/**
 * @title IdoDepositPresaleToken
 * @dev
 */
contract IdoDepositPresaleToken is IdoTest {
    function setUp() external {
        fixture();
    }

    function test_WhenCallerIsNotOwner() external {
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, carol));
        
        vm.prank(carol);
        ido.deposit(presaleId, 100);
    }

    function test_WhenAmountIsZero() external {
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);

        vm.expectRevert(abi.encodeWithSelector(CannotBeZero.selector));
        
        vm.prank(deployer);
        ido.deposit(presaleId, 0);
    }

    function test_WhenPresaleDoesNotExist() external {
        vm.expectRevert(abi.encodeWithSelector(PresaleDoesNotExists.selector));
        
        vm.prank(deployer);
        ido.deposit(353, 100);
    }


    function test_WhenDepositPresaleToken() external {
        vm.prank(admin);
        uint256 presaleId = createPresaleWithId(defaultParams);

        vm.startPrank(deployer);

        uint256 amount = defaultParams.presaleParams.totalSupply;

        presaleToken.approve(address(ido), amount);

        vm.expectEmit(true, true, false, true);

        emit IIDO.TokensDeposited(
            presaleId,
            defaultParams.presaleParams.token,
            amount
        );
    
        ido.deposit(presaleId, amount);

        (
        uint256 id,
        uint256 startDate,
        uint256 endDate,
        address token,
        uint256 totalSupply,
        uint256 remainedSupply,
        uint256 minAllocationAmount,
        uint256 maxAllocationAmount,
        PresaleStatus status,
        bool isPublic,
        uint256 claimStrategyId,
        uint256 priceInUSDT,
        uint256 priceInETH,
        bool isExists,
        bool isDeposited
        ) = ido.presales(presaleId); 

        assertEq(isDeposited, true, 'Presale should be deposited');
        assertTrue(status == PresaleStatus.ACTIVE, 'Presale should be active');

        vm.stopPrank();
    }
}
