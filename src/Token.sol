// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { ERC20Burnable } from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import { ERC20Permit } from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol';

contract Token is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20('Meteor', 'MET') ERC20Permit('Meteor Token') {
        _mint(msg.sender, 100_000_000 * 10 ** decimals());
    }
}
