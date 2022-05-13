//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./ERC20.sol";
import "./NFT721.sol";


contract Marketplace {
    // marketplace to trade NFTs buy direct selling or auction.

    uint constant public AUCTIONTIME = 3; //days - During this period, the auction cannot be cancelled

    uint public constant NEEDEDBIDS = 2; // If after the expiration of the period more than needed bids are collected, the auction is considered to be succeded

    IERC20 public paymentToken;
    ERC721URIStorage public tokenNFT;

    struct NFTonSale {
        bool onSale;
        bool onAuction;
        address lastOwner;
        uint currentPrice;
        uint bids;
        address lastBidder;
        uint time;
        uint price;
    }
    mapping(uint => NFTonSale) public sales;

    uint public tokenId;

    constructor(address _paymentToken, address _tokenNFT) {
        paymentToken = IERC20(_paymentToken);
        tokenNFT = ERC721URIStorage(_tokenNFT);
    }

    function createItem(address to, string memory _tokenURI) external {
        tokenNFT.createNft(to, _tokenURI); //can be called only from this contract Role:Minnter
        tokenId ++;
        //ВОПРОС: можно ли вернуть сюда TokenID из контракта NFT721?
    }

    function listItem(address _from, uint _tokenId, uint _price) external returns(bool) {
        tokenNFT.transferFrom(_from, address(this), _tokenId); //need to be APROVED to this contract address
        sales[_tokenId].price = _price;
        sales[_tokenId].onSale = true;
        sales[_tokenId].lastOwner = _from;
    }

    function buyItem(uint _tokenId) external {
        NFTonSale memory sellingNFT = sales[_tokenId];
        require(sellingNFT.onSale, "NFT not on sale!");
        paymentToken.transferFrom(msg.sender, sellingNFT.lastOwner, sellingNFT.price); //ERC20 from buyer to seller, need to be APROVED to this contract address
        tokenNFT.transferFrom(address(this), msg.sender, _tokenId); //ERC721 from marketplace to buyer
        sales[_tokenId].onSale = false;
    }

    function cancel(uint _tokenId) external { //seller cancel an auction or fix price selling
        NFTonSale memory sellingNFT = sales[_tokenId];
        require(sellingNFT.onSale || sellingNFT.onAuction, "NFT not on sale!");
        require(sellingNFT.lastOwner == msg.sender, "not an owner");
        require(sellingNFT.bids == 0, "Auction has bidder");
        tokenNFT.transferFrom(address(this), sellingNFT.lastOwner, _tokenId); //ERC721 from marketplace to owner
        sales[_tokenId].onSale = false;
        sales[_tokenId].onAuction = false;
    }

    function listOnAuction(address _from, uint _tokenId, uint _minPrice) external {
        tokenNFT.transferFrom(_from, address(this), _tokenId); //need to be APROVED to this contract address
        NFTonSale memory sellingNFT;
        sellingNFT.price = _minPrice;
        sellingNFT.onAuction = true;
        sellingNFT.lastOwner = _from;
        sellingNFT.time = block.timestamp + (AUCTIONTIME * 1 days);
        sales[_tokenId] = sellingNFT;
    }

    function makeBid(uint _tokenId, uint _bidPrice) external {
        NFTonSale memory sellingNFT = sales[_tokenId];
        require(sellingNFT.onAuction, "NFT not on sale!");
        require(sellingNFT.price < _bidPrice, "bid is less then current price");
        if(sellingNFT.bids = 0) {
            paymentToken.transferFrom(msg.sender, address(this), _bidPrice);
            sales[_tokenId].bids ++;
            sales[_tokenId].lastBidder = msg.sender;
            sales[_tokenId].price = _bidPrice;
            } else {
            paymentToken.transfer(sellingNFT.lastBidder, sellingNFT.price); //ERC20 from  marketplace to previous bidder
            paymentToken.transferFrom(msg.sender, address(this), _bidPrice); //ERC20 from bidder to marketplace
            sales[_tokenId].bids ++;
            sales[_tokenId].lastBidder = msg.sender;
            sales[_tokenId].price = _bidPrice;
            }
    }

    function finishAuction(uint _tokenId) external {
        NFTonSale memory sellingNFT = sales[_tokenId];
        require(sellingNFT.onAuction, "NFT not on sale!");
        require(block.timestamp > sellingNFT.time, "auction does not ended");
        if(sellingNFT.bids < NEEDEDBIDS) {
            paymentToken.transfer(sellingNFT.lastBidder, sellingNFT.price); //ERC20 from  marketplace to previous bidder
            tokenNFT.transferFrom(address(this), sellingNFT.lastOwner, _tokenId); //ERC721 from marketplace to owner
        } else {
            paymentToken.transfer(sellingNFT.lastOwner, sellingNFT.price); //ERC20 from  marketplace to previous owner
            tokenNFT.transferFrom(address(this), sellingNFT.lastBidder, _tokenId); //ERC721 from marketplace to bidder
        }
        sales[_tokenId].bids = 0;
        sales[_tokenId].onSale = false;
        sales[_tokenId].onAuction = false;
    }
}