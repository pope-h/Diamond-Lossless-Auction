// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibAuctionStorage} from "../libraries/LibAuctionStorage.sol";

library LibBurn {
    function burn(uint256 amount) external {
        LibAuctionStorage.Layout storage l = LibAuctionStorage.layoutStorage();
        require(l.balances[msg.sender] >= amount, "Insufficient balance");
        l.balances[msg.sender] -= amount;
        l.totalSupply -= amount;
        emit LibAuctionStorage.Burn(msg.sender, amount);
    }
}