// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IRewardToken {
    function mint(address account, uint amount) external;
}
