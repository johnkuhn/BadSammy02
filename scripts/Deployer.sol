// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/BadSammyNFT.sol";
import "../contracts/BadSammyNFTStore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BadSammyDeployer is Ownable {
    // ---- Addresses ----
    // TODO: put our contract/founder owner back in place after remix vm testing.
    address constant CONTRACT_OWNER_MINT_TO = 0x832F90cf5374DC89D7f8d2d2ECb94337f54Dd537; // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    // TODO: put our Treasury wallet address back in after remix vm testing.
    address payable public constant TREASURY = payable(0x643A87055213c3ce6d0BE9B1762A732e9E059536); // payable(0x6150518d33Cfa0e9B9afFd13795a1C2540c972d7);

    // TODO: make sure below is valid USDC address on Base.
    address public constant USDC = 0x36952592150f3AED54c1EC3C85213e1eD5CC1559; // 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // USDC on Base chain

    // ❌ ETH/USD feed no longer needed – commenting out
    // address public constant ETH_USD_FEED = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70; // Chainlink ETH/USD on Base

    // ---- BaseURIs ----
    string public constant BASEURI1 = "ipfs://QmVfqoFUZ1wKd6F2AUQ24hffVUgJGXqcaX7qs9ZYmvSsfP/";  
    string public constant BASEURI2 = "ipfs://QmewsSBD8QiZsr1o3FC8WjR55Ypv7kmE8trdmygNqqS4pY/"; 
    string public constant BASEURI3 = "ipfs://QmPXK2EqWmfDgs6UKHn57SYdeN2nhiKcPnsV6yUuoXcVgR/"; 
    string public constant BASEURI4 = "ipfs://Qme2PPT9rwbf28WvufUVzsPYfVfgFcDgCdeyerN6SDssUy/"; 
    string public constant BASEURI5 = "ipfs://QmQWGVVYUA9bRQH1wgHzTXr9o6kFcXeBwwKF961BRMeT2P/"; 

    // ---- Names & Symbols ----
    string private constant NAME1 = "BadSammy Common";
    string private constant NAME2 = "BadSammy Rare";
    string private constant NAME3 = "BadSammy Epic";
    string private constant NAME4 = "BadSammy Legendary";
    string private constant NAME5 = "BadSammy Ultra Rare";

    string private constant SYM1 = "BSCOM";
    string private constant SYM2 = "BSRARE";
    string private constant SYM3 = "BSEPIC";
    string private constant SYM4 = "BSLEG";
    string private constant SYM5 = "BSULR";

    // ---- Supplies ----
    uint256 private constant SUP1 = 5000;
    uint256 private constant SUP2 = 2500;
    uint256 private constant SUP3 = 1000;
    uint256 private constant SUP4 = 500;
    uint256 private constant SUP5 = 100;

    // ---- USDC Prices (ETH disabled) ----
    uint256 private constant USD1 = 100_000_000;    // $100
    uint256 private constant USD2 = 250_000_000;    // $250
    uint256 private constant USD3 = 500_000_000;    // $500
    uint256 private constant USD4 = 1_000_000_000;  // $1,000
    uint256 private constant USD5 = 2_500_000_000;  // $2,500

    // ---- Deployed contracts ----
    BadSammyNFT public nft1;
    BadSammyNFT public nft2;
    BadSammyNFT public nft3;
    BadSammyNFT public nft4;
    BadSammyNFT public nft5;
    BadSammyNFTStore public store;

    // ---- Events ----
    event NFTsDeployed(address nft1, address nft2, address nft3, address nft4, address nft5);
    event StoreDeployed(address store);
    event AllBaseURIsFrozen();
    event TiersConfigured();
    event OwnershipTransferredAll(address newOwner);

    constructor() Ownable(msg.sender) {}

    // STEP 1: Deploy NFTs
    function deployNFTs() external onlyOwner returns (address, address, address, address, address) {
        require(address(nft1) == address(0), "NFTs already deployed");

        nft1 = new BadSammyNFT(NAME1, SYM1, SUP1, address(this));
        nft2 = new BadSammyNFT(NAME2, SYM2, SUP2, address(this));
        nft3 = new BadSammyNFT(NAME3, SYM3, SUP3, address(this));
        nft4 = new BadSammyNFT(NAME4, SYM4, SUP4, address(this));
        nft5 = new BadSammyNFT(NAME5, SYM5, SUP5, address(this));

        emit NFTsDeployed(address(nft1), address(nft2), address(nft3), address(nft4), address(nft5));
        return (address(nft1), address(nft2), address(nft3), address(nft4), address(nft5));
    }

    // STEP 2: Deploy Store
    function deployStore() external onlyOwner returns (address) {
        require(address(nft1) != address(0), "Deploy NFTs first");
        require(address(store) == address(0), "Store already deployed");

        // 🚀 ETH payment disabled — calling constructor without ETH feed
        // store = new BadSammyNFTStore(address(this), TREASURY, USDC, ETH_USD_FEED);
        store = new BadSammyNFTStore(address(this), TREASURY, USDC); // <--- FINAL

        emit StoreDeployed(address(store));
        return address(store);
    }

    function setAllBaseURI() external onlyOwner {
        nft1.setBaseURI(BASEURI1);
        nft2.setBaseURI(BASEURI2);
        nft3.setBaseURI(BASEURI3);
        nft4.setBaseURI(BASEURI4);
        nft5.setBaseURI(BASEURI5);
    }

    /* 
    // TODO: Re-enable when ready to mass mint after testing.
    function mintAllFull() external onlyOwner {
        nft1.mintTo(CONTRACT_OWNER_MINT_TO, SUP1);
        nft2.mintTo(CONTRACT_OWNER_MINT_TO, SUP2);
        nft3.mintTo(CONTRACT_OWNER_MINT_TO, SUP3);
        nft4.mintTo(CONTRACT_OWNER_MINT_TO, SUP4);
        nft5.mintTo(CONTRACT_OWNER_MINT_TO, SUP5);
    }
    */

    function mintSpecificAmountByTier(uint256 tierId, uint256 quantity) external onlyOwner {
        if (tierId == 1) nft1.mintTo(CONTRACT_OWNER_MINT_TO, quantity);
        if (tierId == 2) nft2.mintTo(CONTRACT_OWNER_MINT_TO, quantity);
        if (tierId == 3) nft3.mintTo(CONTRACT_OWNER_MINT_TO, quantity);
        if (tierId == 4) nft4.mintTo(CONTRACT_OWNER_MINT_TO, quantity);
        if (tierId == 5) nft5.mintTo(CONTRACT_OWNER_MINT_TO, quantity);
    }

    function configureStoreTiers() external onlyOwner {
        // ETH pricing removed — USDC only
        store.setTier(1, address(nft1), USD1, true);
        store.setTier(2, address(nft2), USD2, true);
        store.setTier(3, address(nft3), USD3, true);
        store.setTier(4, address(nft4), USD4, true);
        store.setTier(5, address(nft5), USD5, true);
        emit TiersConfigured();
    }

    function freezeAllBaseURI() external onlyOwner {
        if (!nft1.uriFrozen()) nft1.freezeBaseURI();
        if (!nft2.uriFrozen()) nft2.freezeBaseURI();
        if (!nft3.uriFrozen()) nft3.freezeBaseURI();
        if (!nft4.uriFrozen()) nft4.freezeBaseURI();
        if (!nft5.uriFrozen()) nft5.freezeBaseURI();
        emit AllBaseURIsFrozen();
    }

    function transferAllContractsToOwner() external onlyOwner {
        require(CONTRACT_OWNER_MINT_TO != address(0), "Invalid owner");

        nft1.transferOwnership(CONTRACT_OWNER_MINT_TO);
        nft2.transferOwnership(CONTRACT_OWNER_MINT_TO);
        nft3.transferOwnership(CONTRACT_OWNER_MINT_TO);
        nft4.transferOwnership(CONTRACT_OWNER_MINT_TO);
        nft5.transferOwnership(CONTRACT_OWNER_MINT_TO);
        store.transferOwnership(CONTRACT_OWNER_MINT_TO);

        emit OwnershipTransferredAll(CONTRACT_OWNER_MINT_TO);
    }
}
