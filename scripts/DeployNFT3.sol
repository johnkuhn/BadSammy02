// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/BadSammyNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeployNFT3 is Ownable {
    // ---- Addresses ----
    // TODO: put our contract/founder owner back in place after remix vm testing.
    address constant CONTRACT_OWNER_MINT_TO = 0x832F90cf5374DC89D7f8d2d2ECb94337f54Dd537; // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    // ---- BaseURIs ----
    //TODO: update to proper metadata CID folder for this tier
    string public constant BASEURI = "ipfs://QmVfqoFUZ1wKd6F2AUQ24hffVUgJGXqcaX7qs9ZYmvSsfP/";  

    // ---- Names & Symbols ----
    string private constant NAME = "BadSammy Epic";   
    string private constant SYMBOL = "BSEPIC";

    // ---- Supply ----
    uint256 private constant TOTAL_SUPPLY = 1000;

 
    
    // ---- Deployed contracts ----
    BadSammyNFT public thisNFT;

    //BadSammyNFTStore public store;

    // ---- Events ----
    event NFTDeployed(address nft1);
    event BaseURIFrozen();
    event OwnershipTransferred(address newOwner);

    constructor() Ownable(msg.sender) {}

    // STEP 1: Deploy NFTs
    function deployNFT() external onlyOwner returns (address) {
        require(address(thisNFT) == address(0), "NFT already deployed");

        thisNFT = new BadSammyNFT(NAME, SYMBOL, TOTAL_SUPPLY, address(this));

        thisNFT.setBaseURI(BASEURI);

        thisNFT.transferOwnership(CONTRACT_OWNER_MINT_TO);

        emit NFTDeployed(address(thisNFT));
        return (address(thisNFT));
    }


}
