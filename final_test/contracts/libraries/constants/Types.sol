// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Types {
    struct FixedPriceNFT {
        address nftContract;
        uint256 tokenId;
        address seller;
        address paymentToken;
        uint256 price;
        bool isActive;
        bool isERC1155;
        uint256 amount;
    }

    struct AuctionNFT {
        address nftContract;
        uint256 tokenId;
        address seller;
        address paymentToken;
        uint256 auctionEndTime;
        uint256 highestBid;
        address highestBidder;
        bool isERC1155;
        uint256 amount;
    }

    struct Bid {
        address bidder;
        uint256 bidAmount;
    }
}
