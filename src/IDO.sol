// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;


import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

contract IDO is Ownable {


    mapping(address => bool) admins;
    // mapping(presale, address[]) public whitelist;
    mapping(address => bool) public whitelistedTokens;

    /// @dev Error when the token or amount is zero
    error CannotBeZero();

    /// @dev SafeERC20 is a wrapper around IERC20 that reverts if the transfer fails
    using SafeERC20 for IERC20;
    
    constructor() Ownable(_msgSender()) {}

    function setAdmin(address _admin) external onlyOwner {
        if (_admin == address(0)) revert CannotBeZero();
        require(!admins[_admin], 'Admin with this address already exists');
        admins[_admin] = true;
    }

    function disableAdmin(address _admin) external onlyOwner {
        if (_admin == address(0)) revert CannotBeZero();
        require(admins[_admin], "Admin with this address doesn't exist");
        admins[_admin] = false;
    }

    function withdraw(address token, uint256 amount, address recipient) external onlyOwner {
        if (recipient == address(0)) revert CannotBeZero();

        if (token == address(0)) {
            Address.sendValue(payable(recipient), amount);
        } else {
            IERC20(token).safeTransfer(recipient, amount);
        }

    }
}