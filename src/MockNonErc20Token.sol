// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract MockNonErc20Token is ERC721 {
    constructor() ERC721('Bridger', 'BRD') {}
}
