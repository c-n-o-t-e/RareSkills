// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IRewardToken {
    function mint(address account, uint amount) external;
}
