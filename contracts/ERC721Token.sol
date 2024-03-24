// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MyERC721Token is ERC721 {
    uint256 private _tokenId;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _tokenId = 0;
    }

    // function mint(address recipient, string memory tokenURI) public returns (uint256)
    function mint(address recipient) public returns (uint256) {
        _tokenId++;

        uint256 newItemId = _tokenId;
        _mint(recipient, newItemId);
        // _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}