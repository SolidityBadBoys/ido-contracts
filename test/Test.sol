// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test as ForgeTest } from "forge-std/Test.sol";

contract Test is ForgeTest {
    address internal alina = makeAddr("alina");
    address internal bob = makeAddr("bob");
    address internal carol = makeAddr("carol");
    address internal chuck = makeAddr("chuck");
    address internal deployer = makeAddr("deployer");
    address internal admin = makeAddr("admin");

    address[] internal actors = [deployer, alina, bob, carol, chuck, admin];
}
