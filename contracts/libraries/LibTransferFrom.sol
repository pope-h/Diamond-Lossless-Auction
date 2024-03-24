// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibAuctionStorage} from "../libraries/LibAuctionStorage.sol";

library LibTransferFrom {

    function _transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        LibAuctionStorage.Layout storage l = LibAuctionStorage.layoutStorage();
        uint256 frombalances = l.balances[msg.sender];
        require(
            frombalances >= _amount,
            "ERC20: Not enough tokens to transfer"
        );
        l.balances[_from] = frombalances - _amount;
        l.balances[_to] += _amount;
        emit LibAuctionStorage.Transfer(_from, _to, _amount);
    }
}