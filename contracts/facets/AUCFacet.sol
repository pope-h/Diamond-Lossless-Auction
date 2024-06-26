// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibAuctionStorage} from "../libraries/LibAuctionStorage.sol";
import {LibTransferFrom} from "../libraries/LibTransferFrom.sol";

contract AUCFacet {
    LibAuctionStorage.Layout internal l;
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    function name() external view returns (string memory) {
        return l.name;
    }

    function symbol() external view returns (string memory) {
        return l.symbol;
    }

    function decimals() external view returns (uint8) {
        return l.decimals;
    }

    function totalSupply() public view returns (uint256) {
        return l.totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        balance = l.balances[_owner];
    }

    function setLastInterractor() internal {
        l.lastInteractor = msg.sender;
    }

    function getLastInterractor() external view returns (address) {
        return l.lastInteractor;
    }

    function transfer(
        address _to,
        uint256 _value
    ) public returns (bool success) {
        LibTransferFrom._transferFrom(msg.sender, _to, _value);
        setLastInterractor();
        success = true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        uint256 l_allowance = l.allowances[_from][address(this)];
        if (msg.sender == _from || l.allowances[_from][address(this)] >= _value) {
            l.allowances[_from][msg.sender] = l_allowance - _value;
            LibTransferFrom._transferFrom(_from, _to, _value);

            setLastInterractor();
            emit Approval(_from, msg.sender, l_allowance - _value);

            success = true;
        } else {
            revert("ERC20: Not enough allowance to transfer");
        }
    }

    function approve(
        address _spender,
        uint256 _value
    ) public returns (bool success) {
        l.allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        success = true;
    }

    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint256 remaining_) {
        remaining_ = l.allowances[_owner][_spender];
    }

    function mintTo(address _user) external {
        LibDiamond.enforceIsContractOwner();
        uint256 amount = 100_000_000e18;
        l.balances[_user] += amount;
        l.totalSupply += uint96(amount);
        emit LibAuctionStorage.Transfer(address(0), _user, amount);
    }
}

// address(this) ==> diamond not diamond deployer