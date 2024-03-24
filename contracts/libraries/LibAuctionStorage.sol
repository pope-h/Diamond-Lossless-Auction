// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

library LibAuctionStorage {
    // bytes32 constant TF_STORAGE_POSITION =
    //     keccak256("transferFrom.standard.diamond.storage");

    uint256 public constant FEE_DENOMINATOR = 100;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Burn(address _from, uint256 _amount);

    event test(uint);

    event AuctionCreated(uint256 indexed tokenId, uint256 endTime, bool isERC1155, uint256 amount);
    event NewBid(uint256 indexed tokenId, address bidder, uint256 bid);
    event AuctionEnded(uint256 indexed tokenId, address winner, uint256 bid);
    event FeesDistributed(uint256 indexed tokenId, uint256 feesBurned, uint256 feesToDAO, uint256 feesToTeam, uint256 feesToLastInteractor);

    struct Auction {
        address seller;
        uint256 tokenId;
        address highestBidder;
        uint256 highestBid;
        uint256 endTime;
        bool ended;
        bool isERC1155;
        uint256 amount; // For ERC1155 tokens
    }

    struct Layout{
        // AUC
        string name;
        string symbol;
        uint256 totalSupply;
        uint8 decimals;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;

        // AuctionHouse
        IERC20 aucTokenAddr;
        mapping(uint256 => Auction) auctions;
        address teamWallet;
        address lastInteractor;
    }

    function layoutStorage() internal pure returns (Layout storage l) {
        // bytes32 position = TF_STORAGE_POSITION;
        assembly {
            l.slot := 0
        }
    }
}