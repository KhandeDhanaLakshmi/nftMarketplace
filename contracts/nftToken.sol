// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTContract is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    address marketPlaceAddress;

    constructor(address contractAddress) ERC721("DK NFT", "DK") {
        marketPlaceAddress = contractAddress;
    }

    function createToken(string memory tokenURI)
        public
        returns (uint)
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        approve(marketPlaceAddress, tokenId);
        return tokenId;
    }

    
}
