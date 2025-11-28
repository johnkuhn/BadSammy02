// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/BadSammyNFT.sol";
//import "../contracts/BadSammyNFTStore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeployNFT5 is Ownable {
    // ---- Addresses ----
    // TODO: put our contract/founder owner back in place after remix vm testing.
    address constant CONTRACT_OWNER_MINT_TO = 0x3Cc463fd67146A6951062B85428b5f77828D5D09; // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    // ---- BaseURIs ----
    //TODO: update to proper metadata CID folder for this tier
    string public constant BASEURI = "ipfs://QmaJUpUqt95ztprbgpkkXaVk2o3aoft4XBcndQ4EqaHmU6/";  

    // ---- Names & Symbols ----
    string private constant NAME = "BadSammy Ultra Rare";
    string private constant SYMBOL = "BSULR";

    // ---- Supply----
    uint256 private constant TOTAL_SUPPLY = 100;
    
    // ---- Deployed contracts ----
    BadSammyNFT public thisNFT;

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
