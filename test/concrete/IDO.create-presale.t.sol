// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        // Expect revert with NotAnAdmin
        vm.expectRevert(NotAnAdmin.selector);

        vm.prank(alina);

        bool isPublic = true;
        createPresale(isPublic);
    }
}
