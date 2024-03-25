// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/IERC20.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibAuctionStorage} from "../libraries/LibAuctionStorage.sol";
import {LibBurn} from "../libraries/LibBurn.sol";
import {AUCFacet} from "./AUCFacet.sol";

contract AuctionHouseFacet {
    LibAuctionStorage.Layout internal l;


    constructor(address _aucTokenAddress) {
        l.aucTokenAddr = IERC20(_aucTokenAddress);
        l.teamWallet = address(this); // AutionHouseFauset is the teamWallet but funds is held by diamond.
    }

    function createAuction(uint256 _tokenId, uint256 _endTime, bool _isERC1155, uint256 _amount, address _nftContract) external {
        LibDiamond.setContractOwner(msg.sender);
        require(l.auctions[_tokenId].endTime == 0, "Auction already exists");
        require(_nftContract != address(0), "Invalid Contract Address");
        require(
            IERC721(_nftContract).ownerOf(_tokenId) == msg.sender,
            "Not Owner"
        );
        require(_endTime > block.timestamp, "Invalid Close Time");

        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);

        l.auctions[_tokenId] = LibAuctionStorage.Auction({
            seller: msg.sender,
            tokenId: _tokenId,
            highestBidder: address(0),
            highestBid: _amount,
            prevBid: 0,
            endTime: _endTime,
            ended: false,
            isERC1155: _isERC1155,
            amount: _amount
        });

        emit LibAuctionStorage.AuctionCreated(_tokenId, _endTime, _isERC1155, _amount);
    }

    function bid(uint256 _tokenId, uint256 _bidAmount) external {
        LibAuctionStorage.Auction storage auction = l.auctions[_tokenId];
        require(block.timestamp < auction.endTime, "Auction already ended");
        require(_bidAmount > auction.highestBid, "There already is a higher bid");

        if (auction.highestBidder == address(0)) {
            l.aucTokenAddr.transferFrom(msg.sender, address(this), _bidAmount);
            return;
        }

        auction.prevBid = _bidAmount;

        l.aucTokenAddr.transferFrom(msg.sender, address(this), _bidAmount);

        uint256 _prevBidderProfit = distributeFees(_tokenId, _bidAmount);
        uint256 totalRefund = auction.prevBid + _prevBidderProfit;
        // return prev.Bid to auction.highestBid as it is the prev highest bidder as of now
        l.aucTokenAddr.transferFrom(address(this), auction.highestBidder, totalRefund);

        auction.highestBidder = msg.sender;

        emit LibAuctionStorage.NewBid(_tokenId, msg.sender, _bidAmount);
    }

    function endAuction(uint256 _tokenId, address _nftContract) external {
        LibDiamond.enforceIsContractOwner();
        // In future implementation, the contract should self terminate on time-out
        LibAuctionStorage.Auction storage auction = l.auctions[_tokenId];
        require(!auction.ended, "Auction end already called");

        // The below commented out in case the seller is satisfied with the price
        // require(block.timestamp >= auction.endTime, "Auction not yet ended");

        auction.ended = true;
        if (auction.highestBidder != address(0)) {
            // Transfer the token to the highest bidder
            if (auction.isERC1155) {
                IERC1155(_nftContract).safeTransferFrom(address(this), auction.highestBidder, auction.tokenId, auction.amount, "");
            } else {
                IERC721(_nftContract).safeTransferFrom(address(this), auction.highestBidder, auction.tokenId);
            }
            // Transfer the highest bid to the seller
            l.aucTokenAddr.transfer(auction.seller, auction.highestBid);
        } else {
            if (auction.isERC1155) {
                IERC1155(_nftContract).safeTransferFrom(address(this), auction.seller, auction.tokenId, auction.amount, "");
            } else {
                IERC721(_nftContract).safeTransferFrom(address(this), auction.seller, auction.tokenId);
            }
        }

        emit LibAuctionStorage.AuctionEnded(_tokenId, auction.highestBidder, auction.highestBid);
    }

     // Function to distribute fees
    function distributeFees(uint256 _tokenId, uint256 _bidAmount) internal returns(uint256) {
        LibAuctionStorage.Auction storage auction = l.auctions[_tokenId];
        uint256 totalFee = _bidAmount * 10 / LibAuctionStorage.FEE_DENOMINATOR;
        auction.highestBid = _bidAmount - totalFee;
        uint256 prevBidderProfit = totalFee * 30 / LibAuctionStorage.FEE_DENOMINATOR;
        uint256 burnAmount = totalFee * 20 / LibAuctionStorage.FEE_DENOMINATOR;
        uint256 daoAmount = totalFee * 20 / LibAuctionStorage.FEE_DENOMINATOR;
        uint256 teamAmount = totalFee * 20 / LibAuctionStorage.FEE_DENOMINATOR;
        uint256 lastInteractorAmount = totalFee * 10 / LibAuctionStorage.FEE_DENOMINATOR;

        // Burn the tokens
        burn(burnAmount);

        // Send fee to DAO (random DAO address logic to be implemented)
        l.aucTokenAddr.transfer(LibAuctionStorage.DAO_ADDRESS, daoAmount);

        // Send fee to team wallet
        l.aucTokenAddr.transfer(l.teamWallet, teamAmount);

        // Send fee to last interactor
        l.aucTokenAddr.transfer(l.lastInteractor, lastInteractorAmount);

        emit LibAuctionStorage.FeesDistributed(_tokenId, burnAmount, daoAmount, teamAmount, lastInteractorAmount);

        return prevBidderProfit;
    }

    function burn(uint256 amount) internal {
        LibBurn._burn(amount);
    }
}