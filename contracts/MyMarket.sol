// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "contracts/MyToken.sol";


contract MyMarket {
  using Counters for Counters.Counter;
   Counters.Counter private _itemIds;
   Counters.Counter private _itemsSold;

   address payable owner;
   uint256 listingPrice = 2 ether;

   constructor(){
       owner = payable(msg.sender);
   }

   struct MarketItem{
       uint itemId;
       address nftContract;
       uint256 tokenId;
       address payable seller;
       address payable owner;
       uint256 price;
   } 

   mapping(uint256 => MarketItem) private idToMarketItem;

   event newMarketItem(
       uint indexed itemId,
       address indexed nftContract,
       uint256 indexed tokenId,
       address seller,
       address owner,
       uint256 price
   );

   function createMarketItem(address nftContract, uint256 tokenId,uint256 price) public payable {
       require(price > 0, "Price cannot be zero");
       require(msg.value == listingPrice, "Minimum price should be 2 ether");

       _itemIds.increment();
       uint256 marketItemId = _itemIds.current();

        //setting values for a market item
       idToMarketItem[marketItemId] = MarketItem(
           marketItemId,
           nftContract,
           tokenId,
           payable(msg.sender),
           payable(address(0)),
           price
        );

        //transfer ownership from creator/sender to receiver
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);


        emit newMarketItem(
            marketItemId, 
            nftContract,
            tokenId, 
            msg.sender,
            address(0),
            price
        );
   }

    function marketSell(
        address nftContract,
        uint256 marketItemId
    ) public payable {
        uint sellPrice = idToMarketItem[marketItemId].price;
        uint sellTokenId = idToMarketItem[marketItemId].tokenId;
        require(msg.value == sellPrice, "Enter the required selling price");

        idToMarketItem[marketItemId].seller.transfer(msg.value); //transfering amount 
        IERC721(nftContract).transferFrom(address(this), msg.sender, sellTokenId); //transfering asset/art/nft
        idToMarketItem[marketItemId].owner = payable(msg.sender);
        _itemsSold.increment();
        payable(owner).transfer(listingPrice);
    }


    function remainingMarketItems() public view returns(MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItems = itemCount - _itemsSold.current();
        uint x = 0;

        MarketItem[] memory remainingItems = new MarketItem[](unsoldItems);
        for(uint i = 0; i < itemCount; i++){
            if(idToMarketItem[i+1].owner == address(0)){              //checking if address is empty which means item is unsold
                uint currentId = idToMarketItem[i+1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                remainingItems[x] = currentItem;
                x = x+1;
            }
        }
        return remainingItems;
    }
        
    function myItems() public view returns (MarketItem[] memory){
        uint totalItems = _itemIds.current();
        uint itemCount = 0;
        uint x = 0;

        for(uint i = 0; i < totalItems; i++){
            if(idToMarketItem[i+1].owner == msg.sender){
                itemCount = itemCount + 1;
            }
        }
        MarketItem[] memory purchasedItems = new MarketItem[](itemCount);
        for(uint i = 0; i < itemCount; i++){
            if(idToMarketItem[i+1].owner == msg.sender){
                uint currentId = idToMarketItem[i+1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                purchasedItems[x] = currentItem;
                x = x+1;
            }
         }
            return purchasedItems;
    }

}