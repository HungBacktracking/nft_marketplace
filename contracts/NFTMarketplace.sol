// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

import 'hardhat/console.sol';

contract NFTMarketplace is ERC721URIStorage {
    uint256 private _tokenIds;
    uint256 private itemMarketCount;
    uint256 private itemAuctionCount;

    uint256 listingPrice = 0.025 ether;
    address payable owner;

    mapping(uint256 => MarketItem) private idToMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        bool directSold;

        uint256 startTime;
        uint256 endTime;

        address payable highestBidder;
        uint256 highestBid;

        bool auctionCompleted;
    }

    event MarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold,
        bool directSold,

        uint256 startTime,
        uint256 endTime,

        address highestBidder,
        uint256 highestBid,
        bool auctionCompleted
    );

    constructor() ERC721('Metaverse Tokens', 'METT') {
        owner = payable(msg.sender);
        _tokenIds = 0;
        itemAuctionCount = 0;
        itemMarketCount = 0;
    }

    /* Updates the listing price of the contract */
    function updateListingPrice(uint256 _listingPrice) public payable {
        require(
            owner == msg.sender,
            'Only marketplace owner can update listing price.'
        );
        listingPrice = _listingPrice;
    }

    /* Returns the listing price of the contract */
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    /* Mints a token and lists it in the marketplace */
    function createToken(string memory tokenURI, uint256 price)
        public
        payable
        returns (uint256)
    {
        _tokenIds++;
        uint256 newTokenId = _tokenIds;

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId, price);
        return newTokenId;
    }

    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, 'Price must be at least 1 wei');
        require(
            msg.value == listingPrice,
            'Price must be equal to listing price'
        );

        idToMarketItem[tokenId] = MarketItem(
            tokenId, // tokenId
            payable(msg.sender), // seller
            payable(address(this)), // owner
            price, // price
            false, // is sold
            true, // type sold

            block.timestamp, // time start auction
            block.timestamp, // time end auction

            payable(address(0)), // highest bidder
            price, // highest bid
            false // auction completed
        );
        itemMarketCount++;

        _transfer(msg.sender, address(this), tokenId);
        emit MarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false,
            true,

            block.timestamp,
            block.timestamp,

            address(0),
            price,
            false
        );
    }

    function startAuction(uint256 tokenId, uint256 price, uint256 durations) public payable {
        require(
            idToMarketItem[tokenId].owner == msg.sender,
            'Only item owner can perform this operation'
        );
        // require(
        //     msg.value == listingPrice,
        //     'Price must be equal to listing price'
        // );

        idToMarketItem[tokenId].directSold = false;
        idToMarketItem[tokenId].auctionCompleted = false;
        idToMarketItem[tokenId].highestBidder = payable(msg.sender);
        idToMarketItem[tokenId].highestBid = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));
        idToMarketItem[tokenId].startTime = block.timestamp;
        idToMarketItem[tokenId].endTime = block.timestamp + durations;
        idToMarketItem[tokenId].sold = false;

        itemAuctionCount++;
        _transfer(msg.sender, address(this), tokenId);
    }

    /* allows someone to resell a token they have purchased */
    function resellToken(uint256 tokenId, uint256 price) public payable {
        require(
            idToMarketItem[tokenId].owner == msg.sender,
            'Only item owner can perform this operation'
        );
        require(
            msg.value == listingPrice,
            'Price must be equal to listing price'
        );
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));
        idToMarketItem[tokenId].directSold = true;
        itemMarketCount++;

        _transfer(msg.sender, address(this), tokenId);
    }

    function placeBid(uint256 tokenId) public payable{
        MarketItem storage auction = idToMarketItem[tokenId];

        require(msg.value > auction.highestBid, "Bid must be greater than highest bid");
        require(block.timestamp >= auction.startTime, "Auction not yet started");
        require(!auction.auctionCompleted, "Auction already completed");

        auction.highestBid = msg.value;
        auction.highestBidder = payable(msg.sender);

        idToMarketItem[tokenId] = auction;
        payable(owner).transfer(msg.value);
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketSale(uint256 tokenId) public payable {
        uint256 price = idToMarketItem[tokenId].price;
        require(
            msg.value == price,
            'Please submit the asking price in order to complete the purchase'
        );
        idToMarketItem[tokenId].owner = payable(msg.sender);
        idToMarketItem[tokenId].sold = true;

        itemMarketCount--;
        _transfer(address(this), msg.sender, tokenId);
        payable(owner).transfer(listingPrice);
        payable(idToMarketItem[tokenId].seller).transfer(msg.value);
        idToMarketItem[tokenId].seller = payable(address(0));
    }

    /* Returns all unsold market items */
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds;
        uint256 unsoldItemCount = itemMarketCount;
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(this) 
            && idToMarketItem[i + 1].directSold == true
            && idToMarketItem[i + 1].sold == false) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items that a user has purchased */
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items a user has listed */
    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchAuctionItems() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds;
        uint256 itemCount = itemAuctionCount;
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(this) 
            && idToMarketItem[i + 1].directSold == false
            && idToMarketItem[i + 1].sold == false) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}