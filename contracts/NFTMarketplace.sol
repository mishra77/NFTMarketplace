// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721URIStorage, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds; // Counter for NFTs
    Counters.Counter private _itemsSold; // Counter for sold NFTs

    uint256 public listingPrice = 0.025 ether; // Listing Fee

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated(uint256 indexed tokenId, address seller, address owner, uint256 price, bool sold);

    constructor() ERC721("Metaverse Tokens", "METT") Ownable() {}

    /** 🔹 Update Listing Price (Only Owner) */
    function updateListingPrice(uint256 _listingPrice) external onlyOwner {
        listingPrice = _listingPrice;
    }

    // function getListingPrice() external view returns (uint256) {
    //     return listingPrice;
    // }

    /** 🔹 Mint NFT (Does NOT list it for sale) */
    function mintNFT(string memory tokenURI) external returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        return newTokenId;
    }

    /** 🔹 List an existing NFT for sale */
    function listNFT(uint256 tokenId, uint256 price) external payable nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "You must own the NFT to list it");
        require(price > 0, "Price must be greater than zero");
        require(msg.value == listingPrice, "Must pay the listing fee");

        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)), // Marketplace holds ownership until sold
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);

        emit MarketItemCreated(tokenId, msg.sender, address(this), price, false);
    }

    /** 🔹 Buy an NFT */
    function createMarketSale(uint256 tokenId) external payable nonReentrant {
        MarketItem storage item = idToMarketItem[tokenId];

        require(msg.value == item.price, "Must pay the exact price");
        require(item.sold == false, "Item already sold");

        address seller = item.seller;

        item.owner = payable(msg.sender);
        item.sold = true;
        item.seller = payable(address(0));

        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenId);

        payable(owner()).transfer(listingPrice);
        payable(seller).transfer(msg.value);
    }

    /** 🔹 Resell an NFT */
    function resellToken(uint256 tokenId, uint256 price) external payable nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "You must own the NFT to resell it");
        require(msg.value == listingPrice, "Must pay the listing fee");

        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _itemsSold.decrement();
        _transfer(msg.sender, address(this), tokenId);
    }

    /** 🔹 Fetch all unsold NFTs */
    function fetchMarketItems() external view returns (MarketItem[] memory) {
        uint256 totalItems = _tokenIds.current();
        uint256 unsoldItemCount = totalItems - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 1; i <= totalItems; i++) {
            if (idToMarketItem[i].owner == address(this)) {
                items[currentIndex] = idToMarketItem[i];
                currentIndex++;
            }
        }
        return items;
    }

    /** 🔹 Fetch NFTs owned by the caller */
    function fetchMyNFTs() external view returns (MarketItem[] memory) {
        uint256 totalItems = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= totalItems; i++) {
            if (idToMarketItem[i].owner == msg.sender) {
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 1; i <= totalItems; i++) {
            if (idToMarketItem[i].owner == msg.sender) {
                items[currentIndex] = idToMarketItem[i];
                currentIndex++;
            }
        }
        return items;
    }

    /** 🔹 Fetch NFTs the caller has listed */
    function fetchItemsListed() external view returns (MarketItem[] memory) {
        uint256 totalItems = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= totalItems; i++) {
            if (idToMarketItem[i].seller == msg.sender) {
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 1; i <= totalItems; i++) {
            if (idToMarketItem[i].seller == msg.sender) {
                items[currentIndex] = idToMarketItem[i];
                currentIndex++;
            }
        }
        return items;
    }

    /** 🔹 Transfer Ownership of Marketplace */
    function transferMarketplaceOwnership(address newOwner) external onlyOwner {
        transferOwnership(newOwner);
    }

    /** 🔹 Renounce Ownership (Disable Owner Functions) */
    function renounceMarketplaceOwnership() external onlyOwner {
        renounceOwnership();
    }
}