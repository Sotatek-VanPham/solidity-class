// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Events {
    event ListFixedPriceNft(
        bytes32 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price,
        address paymentToken
    );

    event AuctionNftListed(
        bytes32 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price,
        address paymentToken
    );
    event NFTSold(
        bytes32 indexed listingId,
        address indexed buyer,
        address indexed seller,
        address nftContract,
        uint256 tokenId,
        uint256 price
    );
    event BidPlaced(
        bytes32 indexed listingId,
        address indexed bidder,
        uint256 amount
    );

    event ListingCancelled(bytes32 indexed listingId, address indexed seller);
    event AuctionClosed(bytes32 indexed listingId, address indexed seller);
}
