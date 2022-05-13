//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NFT721 is ERC721URIStorage, AccessControl {
  uint256 public tokenCounter;

  bytes32 public constant MINTER = keccak256("MINTER");

  constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    tokenCounter = 0;
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }
  
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
      return super.supportsInterface(interfaceId);
      }

  function createNft(address to, string memory tokenURI) external onlyRole(MINTER) returns (uint256) {
    uint256 newItemId = tokenCounter;
    _safeMint(to, newItemId);
    _setTokenURI(newItemId, tokenURI);
    tokenCounter = tokenCounter ++;
    return newItemId;
  }

  function setMinter(address marketplace) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(MINTER, marketplace);
  }

}