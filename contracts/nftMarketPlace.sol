// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract NFTMarketPlace is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemCount;
    Counters.Counter private _ItemsSoldOut;
    address payable owner;
    uint256 private _marketplaceFee = 25;
    address private _marketplaceFeeRecipient;
    IERC20 public erc20tokenAddress;

    //uint256 public rate = (100 * 10) ^ 18;

    constructor(address _tokenAddress) {
        erc20tokenAddress = IERC20(_tokenAddress);
        owner = payable(msg.sender);
        _marketplaceFeeRecipient = owner;
    }

    struct MarketItem {
        uint256 itemId;
        IERC721 nftContractAdd;
        uint256 tokenId;
        uint256 price;
        address payable seller;
        bool isItemSold;
        IERC20 erc20TokenAddress;
        address payable owner;
        uint256 royality;
    }

    mapping(uint256 => MarketItem) private marketItems;

    event nftTransferToMarket(
        uint256 itemId,
        uint256 tokenId,
        uint256 price,
        address indexed nftContract,
        address indexed seller
    );

    function getMarketplaceFee() public view virtual returns (uint256) {
        return _marketplaceFee;
    }

    function getMarketplaceFeeRecipient()
        public
        view
        virtual
        returns (address)
    {
        return _marketplaceFeeRecipient;
    }

    function setMarketplaceFee(uint256 fee) public {
        require(msg.sender == owner, "only owner can set marketplace fees");
        _marketplaceFee = fee;
    }

    function setMarketplaceFeeRecipient(address recipient) public virtual {
        _marketplaceFeeRecipient = recipient;
    }

    function calculateTotalPrice(uint256 sellingPrice)
        public
        view
        returns (uint256)
    {
        return (sellingPrice * (100 + _marketplaceFee)) / 100;
    }

    function calculateMarketPlaceFee(uint256 totalPrice, uint256 sellingPrice)
        public
        pure
        returns (uint256)
    {
        return totalPrice - sellingPrice;
        //return (sellingPrice * 25) / 1000;
    }

    function calculateRoyality(uint256 salePrice, uint256 royalityInBips)
        public
        pure
        returns (uint256)
    {
        return (salePrice / 10000) * royalityInBips;
    }

    function withdraw() public {
        require(msg.sender == owner, "Only owner can withdraw");
        bool iswithdrawTxSuccess = erc20tokenAddress.transferFrom(
            address(this),
            msg.sender,
            erc20tokenAddress.balanceOf(address(this))
        );
        require(iswithdrawTxSuccess, "ERC20 token withdraw failed!");
    }

    function addItemToMarket(
        IERC721 nftContract,
        uint256 tokenId,
        uint256 sellingPrice,
        uint256 royality
    ) public nonReentrant {
        require(sellingPrice > 0, "Price must be greater than zero");
        require(
            IERC721(nftContract).getApproved(tokenId) == address(this),
            "NFT must be approved to market"
        );

        uint256 itemId = _itemCount.current();
        _itemCount.increment();
        marketItems[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            sellingPrice,
            payable(msg.sender),
            false,
            erc20tokenAddress,
            payable(address(0)),
            royality
        );
        nftContract.transferFrom(msg.sender, address(this), tokenId);
        emit nftTransferToMarket(
            itemId,
            tokenId,
            sellingPrice,
            address(nftContract),
            msg.sender
        );
    }

    function purchaseItem(address nftContract, uint256 itemId)
        public
        payable
        nonReentrant
    {
        uint256 price = marketItems[itemId].price;
        uint256 tokenId = marketItems[itemId].tokenId;
        uint256 totalPrice = calculateTotalPrice(price);

        require(
            itemId >= 0 && itemId <= _itemCount.current(),
            "item doesn't exist"
        );
        require(
            msg.sender != marketItems[itemId].seller,
            "seller should not be same as buyer"
        );
        require(
            totalPrice >= IERC20(erc20tokenAddress).balanceOf(msg.sender),
            "Not enough tokens to purchase"
        );
        require(
            !marketItems[itemId].isItemSold,
            "Item is sold out. Can't purchase."
        );
        //updating state variables before transfer calls to avoid reenterancy vulnerabilities
        marketItems[itemId].owner = payable(msg.sender);
        marketItems[itemId].isItemSold = true;
        _ItemsSoldOut.increment();

        bool issalePriceTxSuccess = erc20tokenAddress.transferFrom(
            msg.sender,
            marketItems[itemId].seller,
            price
        );
        require(
            issalePriceTxSuccess,
            "ERC20 token transfer of sale price failed!"
        );

        bool isMarketPalceFeeTxSuccess = erc20tokenAddress.transferFrom(
            msg.sender,
            address(this),
            calculateMarketPlaceFee(totalPrice, price)
        );
        require(
            isMarketPalceFeeTxSuccess,
            "ERC20 token transfer of marketplace fee failed!"
        );

        bool isRoyalityTxSuccess = erc20tokenAddress.transferFrom(
            msg.sender,
            address(marketItems[itemId].owner),
            calculateRoyality(totalPrice, marketItems[itemId].royality)
        );
        require(
            isRoyalityTxSuccess,
            "ERC20 token transfer of royality failed!"
        );

        IERC721(nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }
}
