// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IEscrowFactory} from "./IEscrowFactory.sol";
import {IEscrow} from "./IEscrow.sol";
import {Escrow} from "./Escrow.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @author c-n-o-t-e
/// @title EscrowFactory
/// @notice Factory contract for deploying Escrow contracts.
contract EscrowFactory is IEscrowFactory {
    using SafeERC20 for IERC20;

    address owner;

    mapping(address => bool) private escrows;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Escrow__Only_Owner();
        }
        _;
    }

    /// @inheritdoc IEscrowFactory
    /// @dev msg.sender must approve the token contract to spend the price amount before calling this function.
    /// @dev There is a risk that if a malicious token is used, the dispute process could be manipulated.
    /// Therefore, careful consideration should be taken when chosing the token.
    function newEscrow(
        uint256 price,
        IERC20 tokenContract,
        address seller,
        uint256 arbiterFee,
        uint256 depositTime,
        bytes32 salt
    ) external returns (IEscrow) {
        address computedAddress = computeEscrowAddress(
            type(Escrow).creationCode,
            address(this),
            uint256(salt),
            price,
            tokenContract,
            msg.sender,
            seller,
            arbiterFee,
            depositTime
        );

        tokenContract.safeTransferFrom(msg.sender, computedAddress, price);

        Escrow escrow = new Escrow{salt: salt}(
            price,
            tokenContract,
            msg.sender,
            seller,
            address(this),
            arbiterFee,
            depositTime
        );

        if (address(escrow) != computedAddress)
            revert EscrowFactory_Addresses_Differ();

        escrows[address(escrow)] = true;

        emit EscrowCreated(address(escrow), msg.sender, seller);
        return escrow;
    }

    /// @inheritdoc IEscrowFactory
    function resolveDispute(
        IEscrow tokenContract,
        uint256 buyerAward
    ) external onlyOwner {
        if (!escrows[address(tokenContract)])
            revert EscrowFactory_AddressNotAnEscrowContract();

        tokenContract.resolveDispute(buyerAward);
    }

    /// @dev See https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2
    function computeEscrowAddress(
        bytes memory byteCode,
        address deployer,
        uint256 salt,
        uint256 price,
        IERC20 tokenContract,
        address buyer,
        address seller,
        uint256 arbiterFee,
        uint256 depositTime
    ) public view returns (address) {
        address predictedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            deployer,
                            salt,
                            keccak256(
                                abi.encodePacked(
                                    byteCode,
                                    abi.encode(
                                        price,
                                        tokenContract,
                                        buyer,
                                        seller,
                                        address(this),
                                        arbiterFee,
                                        depositTime
                                    )
                                )
                            )
                        )
                    )
                )
            )
        );
        return predictedAddress;
    }
}
