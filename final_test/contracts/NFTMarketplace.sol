// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "contracts/interfaces/INFTMarketplace.sol";
import {Events} from "contracts/libraries/constants/Events.sol";
import {ValidateLib} from "./libraries/ValidateLib.sol";
import {Types} from "contracts/libraries/constants/Types.sol";
import {Errors} from "contracts/libraries/constants/Errors.sol";

contract NFTMarketplace is INFTMarketplace, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    mapping(bytes32 => Types.FixedPriceNFT) public fixedPriceNfts;
    mapping(bytes32 => Types.AuctionNFT) public auctionNfts;
    mapping(address => bool) private _blacklist;
    mapping(bytes32 => mapping(address => uint256)) public bids;
    address public treasury;
    uint256 public buyerFee;
    uint256 public sellerFee;

    constructor(address _treasury, uint256 _buyerFee, uint256 _sellerFee) {
        treasury = _treasury;
        buyerFee = _buyerFee;
        sellerFee = _sellerFee;
    }

    modifier notBlacklisted() {
        ValidateLib.validateNotBlacklisted(_msgSender(), _blacklist);
        _;
    }

    modifier nftNotZeroAddress(bytes32 listingId) {
        ValidateLib.validateNFTNotZeroAddress(
            fixedPriceNfts[listingId].nftContract
        );
        _;
    }

    function listFixedPriceNft(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        address paymentToken,
        bool isERC1155,
        uint256 amount
    ) external override notBlacklisted {
        ValidateLib.validateNFTContract(nftContract);
        ValidateLib.validatePrice(price);

        bytes32 listingId = keccak256(
            abi.encode(nftContract, tokenId, _msgSender())
        );

        fixedPriceNfts[listingId] = Types.FixedPriceNFT({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            isActive: true,
            paymentToken: paymentToken,
            isERC1155: isERC1155,
            amount: amount
        });

        if (isERC1155) {
            IERC1155(nftContract).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                amount,
                ""
            );
        } else {
            IERC721(nftContract).transferFrom(
                msg.sender,
                address(this),
                tokenId
            );
        }

        emit Events.ListFixedPriceNft(
            listingId,
            _msgSender(),
            nftContract,
            tokenId,
            price,
            paymentToken
        );
    }

    function listAuctionNft(
        address nftContract,
        uint256 tokenId,
        uint256 auctionEndTime,
        address paymentToken,
        bool isERC1155,
        uint256 amount
    ) external override notBlacklisted {
        ValidateLib.validateAuctionEndTime(auctionEndTime);
        bytes32 listingId = keccak256(
            abi.encode(nftContract, tokenId, _msgSender())
        );

        auctionNfts[listingId] = Types.AuctionNFT({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            highestBid: 0,
            highestBidder: address(0),
            auctionEndTime: auctionEndTime,
            paymentToken: paymentToken,
            isERC1155: isERC1155,
            amount: amount
        });

        if (isERC1155) {
            IERC1155(nftContract).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                amount,
                ""
            );
        } else {
            IERC721(nftContract).transferFrom(
                msg.sender,
                address(this),
                tokenId
            );
        }

        emit Events.AuctionNftListed(
            listingId,
            msg.sender,
            nftContract,
            tokenId,
            auctionEndTime,
            paymentToken
        );
    }

    function buyNFT(
        bytes32 listingId
    )
        external
        payable
        override
        nonReentrant
        notBlacklisted
        nftNotZeroAddress(listingId)
    {
        Types.FixedPriceNFT storage nft = fixedPriceNfts[listingId];
        if (!nft.isActive) {
            revert Errors.InvalidNFTContract();
        }
        address paymentToken = nft.paymentToken;
        uint256 price = nft.price;
        uint256 buyerFeeAmount = (price * buyerFee) / 10000;
        uint256 sellerFeeAmount = (price * sellerFee) / 10000;
        uint256 totalPrice = price + buyerFeeAmount;
        if (paymentToken == address(0)) {
            ValidateLib.validatePayment(totalPrice, msg.value);
            payable(treasury).transfer(buyerFeeAmount + sellerFeeAmount);
            payable(nft.seller).transfer(price - sellerFeeAmount);
        } else {
            IERC20(paymentToken).safeTransferFrom(
                msg.sender,
                address(this),
                totalPrice
            );
            IERC20(paymentToken).safeTransfer(
                treasury,
                buyerFeeAmount + sellerFeeAmount
            );
            IERC20(paymentToken).safeTransfer(
                nft.seller,
                price - sellerFeeAmount
            );
        }

        if (nft.isERC1155) {
            IERC1155(nft.nftContract).safeTransferFrom(
                address(this),
                msg.sender,
                nft.tokenId,
                nft.amount,
                ""
            );
        } else {
            IERC721(nft.nftContract).transferFrom(
                address(this),
                msg.sender,
                nft.tokenId
            );
        }

        nft.isActive = false;

        emit Events.NFTSold(
            listingId,
            _msgSender(),
            nft.seller,
            nft.nftContract,
            nft.tokenId,
            nft.price
        );
    }

    function placeBid(
        bytes32 listingId,
        uint256 bidAmount
    )
        external
        payable
        override
        nonReentrant
        notBlacklisted
        nftNotZeroAddress(listingId)
    {
        Types.AuctionNFT storage nft = auctionNfts[listingId];
        address paymentToken = nft.paymentToken;
        ValidateLib.validatePlaceBid(nft.auctionEndTime, bidAmount);

        if (bidAmount > nft.highestBid) {
            nft.highestBid = bidAmount;
            nft.highestBidder = _msgSender();
        }

        if (paymentToken == address(0)) {
            if (msg.value != bidAmount) {
                revert Errors.InvalidAmount();
            }
        } else {
            IERC20(paymentToken).safeTransferFrom(
                _msgSender(),
                address(this),
                bidAmount
            );
        }

        bids[listingId][_msgSender()] = bidAmount;

        emit Events.BidPlaced(listingId, _msgSender(), bidAmount);
    }

    function withdrawBid(
        bytes32 listingId
    ) external override nonReentrant nftNotZeroAddress(listingId) {
        Types.AuctionNFT storage nft = auctionNfts[listingId];

        uint256 currentBid = bids[listingId][_msgSender()];
        address paymentToken = nft.paymentToken;
        ValidateLib.validateWithdrawBid(nft.auctionEndTime, currentBid);

        if (paymentToken == address(0)) {
            payable(_msgSender()).transfer(currentBid);
        } else {
            IERC20(paymentToken).safeTransfer(_msgSender(), currentBid);
        }

        delete bids[listingId][_msgSender()];
    }

    function closeAuction(
        bytes32 listingId
    ) external override nonReentrant nftNotZeroAddress(listingId) {
        Types.AuctionNFT storage nft = auctionNfts[listingId];

        ValidateLib.validateAuction(nft.auctionEndTime);
        address seller = nft.seller;
        address highestBidder = nft.highestBidder;
        uint256 highestBid = nft.highestBid;
        address paymentToken = nft.paymentToken;

        // Transfer NFT to highest bidder
        IERC721(nft.nftContract).safeTransferFrom(
            seller,
            highestBidder,
            nft.tokenId
        );

        // Calculate fees
        uint256 feeAmount = (highestBid * sellerFee) / 10000;
        uint256 sellerAmount = highestBid - feeAmount;

        // Transfer funds to seller and treasury
        if (paymentToken == address(0)) {
            payable(seller).transfer(sellerAmount);
            payable(treasury).transfer(feeAmount);
        } else {
            IERC20(paymentToken).safeTransfer(seller, sellerAmount);
            IERC20(paymentToken).safeTransfer(treasury, feeAmount);
        }

        delete bids[listingId][_msgSender()];

        emit Events.AuctionClosed(listingId, seller);
    }

    function cancelListingFixedPriceNFT(
        bytes32 listingId
    ) external override nonReentrant nftNotZeroAddress(listingId) {
        Types.FixedPriceNFT storage nft = fixedPriceNfts[listingId];
        if (nft.seller != _msgSender()) {
            revert Errors.InvalidParameter();
        }

        if (!nft.isActive) {
            revert Errors.InvalidParameter();
        }

        if (!nft.isERC1155) {
            IERC721(nft.nftContract).safeTransferFrom(
                address(this),
                nft.seller,
                nft.tokenId
            );
        } else {
            IERC1155(nft.nftContract).safeTransferFrom(
                address(this),
                nft.seller,
                nft.tokenId,
                nft.amount,
                ""
            );
        }

        delete fixedPriceNfts[listingId];
        emit Events.ListingCancelled(listingId, msg.sender);
    }

    function setFee(uint256 _buyerFee, uint256 _sellerFee) external onlyOwner {
        buyerFee = _buyerFee;
        sellerFee = _sellerFee;
    }

    function addToBlacklist(address _user) external onlyOwner {
        if (_blacklist[_user]) {
            revert Errors.BlackListUser();
        }
        _blacklist[_user] = true;
    }

    function removeFromBlacklist(address _user) external onlyOwner {
        if (!_blacklist[_user]) {
            revert Errors.InvalidParameter();
        }
        _blacklist[_user] = false;
    }
}
