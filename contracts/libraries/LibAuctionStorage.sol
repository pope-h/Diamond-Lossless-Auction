// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library LibAuctionStorage {
    uint256 public constant FEE_DENOMINATOR = 100;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Burn(address _from, uint256 _amount);

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
        assembly {
            l.slot := 0
        }
    }

    function _transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        Layout storage l = layoutStorage();
        uint256 frombalances = l.balances[msg.sender];
        require(
            frombalances >= _amount,
            "ERC20: Not enough tokens to transfer"
        );
        l.balances[_from] = frombalances - _amount;
        l.balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
    }

    function layoutStorage2() internal pure returns (Layout storage l2) {
        assembly {
            l2.slot := 1
        }
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param amount The amount of token to be burned.
     */
    function burn(uint256 amount) external {
        Layout storage l2 = layoutStorage2(); // Ensure the user has enough balance to burn
        require(l2.balances[msg.sender] >= amount, "Insufficient balance"); // Deduct the tokens from the user's balance 
        l2.balances[msg.sender] -= amount; // Update the total supply
        l2.totalSupply -= uint96(amount); // Emit the Transfer event
        emit Burn(msg.sender, amount);
    }
}