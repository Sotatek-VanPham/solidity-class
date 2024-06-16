// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTMarketplace {
    /**
     * @dev Lists an NFT for sale or auction.
     * @param nftContract Address of the NFT contract.
     * @param tokenId ID of the NFT token.
     * @param price Price of the NFT in wei.
     * @param paymentToken Address of the payment token (address(0) for ETH).
     * @param isERC1155 Bool nft of type 1155.
     * @param amount Number of tokens.
     */
    function listFixedPriceNft(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        address paymentToken,
        bool isERC1155,
        uint256 amount
    ) external;


    /**
     * @dev Lists an NFT for sale or auction.
     * @param nftContract Address of the NFT contract.
     * @param tokenId ID of the NFT token.
     * @param auctionEndTime Auction ends.
     * @param paymentToken Address of the payment token (address(0) for ETH)
     * @param isERC1155 bool nft of type 1155.
     * @param amount Number of tokens
     */
    function listAuctionNft(
        address nftContract,
        uint256 tokenId,
        uint256 auctionEndTime,
        address paymentToken,
        bool isERC1155,
        uint256 amount
    ) external;

    /**
     * @dev Buys an NFT that is listed for sale.
     * @param listingId ID of the listing.
     */
    function buyNFT(bytes32 listingId) external payable;

    /**
     * @dev Places a bid on an NFT that is listed for auction.
     * @param listingId ID of the listing.
     * @param bidAmount Amount of the bid in wei.
     */
    function placeBid(bytes32 listingId, uint256 bidAmount) external payable;

    /**
     * @dev Withdraws a bid from an NFT auction.
     * @param listingId ID of the listing.
     */
    function withdrawBid(bytes32 listingId) external;

    /**
     * @dev Closes an NFT auction.
     * @param listingId ID of the listing.
     */
    function closeAuction(bytes32 listingId) external;

    /**
     * @dev Cancels an NFT listing.
     * @param listingId ID of the listing.
     */
    function cancelListingFixedPriceNFT(bytes32 listingId) external;
}
