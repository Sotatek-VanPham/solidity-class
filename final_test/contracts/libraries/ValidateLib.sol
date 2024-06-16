// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Errors} from "contracts/libraries/constants/Errors.sol";

library ValidateLib {
    function validateNotBlacklisted(
        address user,
        mapping(address => bool) storage blacklist
    ) internal view {
        if (blacklist[user]) {
            revert Errors.BlackListUser();
        }
    }

    function validateNFTNotZeroAddress(address nftContract) internal pure {
        if (nftContract == address(0)) {
            revert Errors.InvalidNFTContract();
        }
    }

    function validatePrice(uint256 price) internal pure {
        if (price <= 0) {
            revert Errors.InvalidPrice();
        }
    }

    function validateAuctionEndTime(uint256 auctionEndTime) internal view {
        if (auctionEndTime <= block.timestamp) {
            revert Errors.InvalidNFTAuction();
        }
    }

    function validatePayment(
        uint256 requiredAmount,
        uint256 sentAmount
    ) internal pure {
        if (sentAmount < requiredAmount) {
            revert Errors.InvalidAmount();
        }
    }

    function validateAuction(uint256 auctionEndTime) internal view {
        if (auctionEndTime <= block.timestamp) {
            revert Errors.InvalidNFTAuction();
        }
    }

    function validatePlaceBid(
        uint256 auctionEndTime,
        uint256 bidAmount
    ) internal view {
        validateAuction(auctionEndTime);

        if (bidAmount <= 0) {
            revert Errors.InvalidAmount();
        }
    }

    function validateWithdrawBid(
        uint256 auctionEndTime,
        uint256 currentBid
    ) internal view {
        validateAuction(auctionEndTime);

        if (currentBid <= 0) {
            revert Errors.InvalidAmount();
        }
    }
}
