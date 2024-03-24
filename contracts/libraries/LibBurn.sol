// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibAuctionStorage} from "../libraries/LibAuctionStorage.sol";

library LibBurn {
    function _burn(uint256 _amount) internal {
        LibAuctionStorage.Layout storage l = LibAuctionStorage.layoutStorage();
        require(l.balances[msg.sender] >= _amount, "Insufficient balance");
        l.balances[msg.sender] -= _amount;
        l.totalSupply -= _amount;
        emit LibAuctionStorage.Burn(msg.sender, _amount);
        // return l.balances[msg.sender];
    }
}