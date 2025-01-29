// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

    /// @dev Error when the user is not an admin
    error NotAnAdmin();

    /// @dev Error when the token or amount is zero
    error CannotBeZero();

    /// @dev Error when the presale doesn't exists
    error PresaleDoesNotExists();

    /// @dev Error when the presale is not active
    error PresaleIsNotActive();

    /// @dev Error when the start date is in the past.
    error IncorrectStartDate();

    /// @dev Error when the end date is not in the future.
    error IncorrectEndDate();

    /// @dev Error when the tokens for sale amount is zero.
    error TokensForSaleAmountIsZero();

    /// @dev Error when the minimum allocation is zero.
    error MinAllocationIsZero();

    /// @dev Error when the maximum allocation is zero.
    error MaxAllocationIsZero();

    /// @dev Error when the price in USDT is zero.
    error PriceInUsdtIsZero();

    /// @dev Error when the claim schedule array is empty.
    error EmptyClaimSchedule();

    /// @dev Error when a claim start date is incorrect.
    error IncorrectClaimStartDate();

    /// @dev Error when the total claim schedule percentage is not 100.
    error IncorrectClaimPercentageSum();

    /// @dev Error when token is not in whitelist.
    error TokenIsNotWhitelisted();


    /// @dev Error when wallet is not in whitelist.
    error WalletIsNotWhitelisted();

    /// @dev Error when try to update wallets whitelist on public presale.
    error PublicPresaleCantBeWhitelisted();


    /// @dev Error when admin already exists.
    error AdminAlreadyExist();

    /// @dev Error when admin doesn't exists.
    error AdminDoesNotExist();