// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAccessControl } from '@openzeppelin/contracts/access/IAccessControl.sol';

import { IdoTest } from '../IdoTest.sol';
import { IDO } from '../../src/IDO.sol';
import '../../src/errors/errors.sol';

/**
 * @title IDOTest
 * @dev Тестирование основных функций контракта IDO
 */
contract IdoCreatePresale is IdoTest {
    function setUp() external {
        fixture();
    }

    function test_WhenCallerIsNotAdmin() external {
        // it reverts
        // Expect revert with AccessControlUnauthorizedAccount
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alina, ido.ADMIN_ROLE()));

        vm.prank(alina);

        createPresale(defaultParams);
    }
}
