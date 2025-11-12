// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/BadSammyNFT.sol";
import "../contracts/BadSammyNFTStore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BadSammyDeployer is Ownable {
    // ---- Addresses you asked to be constants ----
    //TODO: put our contract/founder owner back in place after remix vm testing.
    address constant CONTRACT_OWNER_MINT_TO = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; // 0x3Cc463fd67146A6951062B85428b5f77828D5D09;
    
    //TODO: put our Treasury wallet address back in after remix vm testing.
    address payable public constant TREASURY = payable(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2); // payable(0xDa8291d1F21643c441d2637da5ae7F0990ab5678);
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // 6 decimals. USDC address on BASE chain.

    // ---- BaseURIs: set these before freezing ----
    string public constant BASEURI1 = "https://test1.com"; // Common
    string public constant BASEURI2 = "https://test2.com"; // Rare
    string public constant BASEURI3 = "https://test3.com"; // Epic
    string public constant BASEURI4 = "https://test4.com"; // Legendary
    string public constant BASEURI5 = "https://test5.com"; // Ultra Rare

    // ---- Tier constants (names, symbols, supply) ----
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

    uint256 private constant SUP1 = 5000;
    uint256 private constant SUP2 = 2500;
    uint256 private constant SUP3 = 1000;
    uint256 private constant SUP4 = 500;
    uint256 private constant SUP5 = 100;

   // ---- ETH prices (wei) ----
    uint256 private constant ETH1 = 29_000_000_000_000_000;    // 0.029 ETH ($100)
    uint256 private constant ETH2 = 72_500_000_000_000_000;    // 0.0725 ETH ($250)
    uint256 private constant ETH3 = 145_000_000_000_000_000;   // 0.145 ETH ($500)
    uint256 private constant ETH4 = 290_000_000_000_000_000;   // 0.29 ETH ($1,000)
    uint256 private constant ETH5 = 725_000_000_000_000_000;   // 0.725 ETH ($2,500)


    // ---- USDC prices (6 decimals) ----
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

    // ---- Events for Remix logs ----
    event Deployed(address indexed nft1, address indexed nft2, address indexed nft3, address nft4, address nft5, address store);
    event BaseURIFrozen(address indexed nft);
    event AllBaseURIsFrozen();
    event TiersConfigured();
    event OwnershipTransferredAll(address newOwner);
    //event OwnershipTransferred(address indexed contractAddress, address indexed newOwner);

    constructor() Ownable(msg.sender) {}

    // Deploy all 5 NFTs + Store. This contract becomes owner of all,
    // so it can set base URIs, mint, freeze, etc.
    function deployAll() external onlyOwner returns (
        address _nft1,
        address _nft2,
        address _nft3,
        address _nft4,
        address _nft5,
        address _store
    ) {
        require(address(nft1) == address(0), "Already deployed");

        nft1 = new BadSammyNFT(NAME1, SYM1, SUP1, address(this));
        nft2 = new BadSammyNFT(NAME2, SYM2, SUP2, address(this));
        nft3 = new BadSammyNFT(NAME3, SYM3, SUP3, address(this));
        nft4 = new BadSammyNFT(NAME4, SYM4, SUP4, address(this));
        nft5 = new BadSammyNFT(NAME5, SYM5, SUP5, address(this));

        store = new BadSammyNFTStore(address(this), TREASURY, USDC);

        emit Deployed(address(nft1), address(nft2), address(nft3), address(nft4), address(nft5), address(store));
        return (address(nft1), address(nft2), address(nft3), address(nft4), address(nft5), address(store));
    }

    // Optionally set all base URIs (call before freezing)
    function setAllBaseURI() external onlyOwner {
        if (bytes(BASEURI1).length > 0) nft1.setBaseURI(BASEURI1);
        if (bytes(BASEURI2).length > 0) nft2.setBaseURI(BASEURI2);
        if (bytes(BASEURI3).length > 0) nft3.setBaseURI(BASEURI3);
        if (bytes(BASEURI4).length > 0) nft4.setBaseURI(BASEURI4);
        if (bytes(BASEURI5).length > 0) nft5.setBaseURI(BASEURI5);
    }

    // Mint full max supply of every tier to the one wallet (can be heavy!)
    function mintAllFull() external onlyOwner {
        nft1.mintTo(CONTRACT_OWNER_MINT_TO, SUP1);
        nft2.mintTo(CONTRACT_OWNER_MINT_TO, SUP2);
        nft3.mintTo(CONTRACT_OWNER_MINT_TO, SUP3);
        nft4.mintTo(CONTRACT_OWNER_MINT_TO, SUP4);
        nft5.mintTo(CONTRACT_OWNER_MINT_TO, SUP5);
    }

    // Safer batching if full mint runs out of gas
    function mintAllInBatches(uint256 batchSize) external onlyOwner {
        _batchMint(nft1, SUP1, batchSize);
        _batchMint(nft2, SUP2, batchSize);
        _batchMint(nft3, SUP3, batchSize);
        _batchMint(nft4, SUP4, batchSize);
        _batchMint(nft5, SUP5, batchSize);
    }

    // ---------------------------------------------------------
    // ✅ Mint a specific quantity for a specific NFT contract
    // ---------------------------------------------------------
    function mintSpecific(address nftAddress, uint256 quantity)
        external
        onlyOwner
    {
        require(nftAddress != address(0), "NFT address required");
        require(quantity > 0, "Quantity must be > 0");

        BadSammyNFT nft = BadSammyNFT(nftAddress);

        // Will revert automatically if it exceeds max supply
        nft.mintTo(CONTRACT_OWNER_MINT_TO, quantity);
    }

    // ---------------------------------------------------------
    // ✅ Mint by Tier (1–5) without needing the NFT address
    // ---------------------------------------------------------
    function mintSpecificByTier(uint256 tierId, uint256 quantity)
        external
        onlyOwner
    {
        require(quantity > 0, "Quantity must be > 0");

        BadSammyNFT nft;

        if (tierId == 1) {
            nft = nft1;
        } else if (tierId == 2) {
            nft = nft2;
        } else if (tierId == 3) {
            nft = nft3;
        } else if (tierId == 4) {
            nft = nft4;
        } else if (tierId == 5) {
            nft = nft5;
        } else {
            revert("Invalid tier");
        }

        nft.mintTo(CONTRACT_OWNER_MINT_TO, quantity);
    }


    function _batchMint(BadSammyNFT c, uint256 maxSupply, uint256 batch) internal {
        uint256 remaining = maxSupply - c.minted();
        while (remaining > 0) {
            uint256 m = remaining > batch ? batch : remaining;
            c.mintTo(CONTRACT_OWNER_MINT_TO, m);
            remaining -= m;
        }
    }

    // Configure store tiers (ETH + USDC) and enable them
    function configureStoreTiers() external onlyOwner {
        store.setTier(1, address(nft1), ETH1, USD1, true);
        store.setTier(2, address(nft2), ETH2, USD2, true);
        store.setTier(3, address(nft3), ETH3, USD3, true);
        store.setTier(4, address(nft4), ETH4, USD4, true);
        store.setTier(5, address(nft5), ETH5, USD5, true);
        emit TiersConfigured();
    }

    // Freeze all base URIs, but ONLY if not already frozen; emit events for Remix logs
    function freezeAllBaseURI() external onlyOwner {
        if (!nft1.uriFrozen()) { nft1.freezeBaseURI(); emit BaseURIFrozen(address(nft1)); }
        if (!nft2.uriFrozen()) { nft2.freezeBaseURI(); emit BaseURIFrozen(address(nft2)); }
        if (!nft3.uriFrozen()) { nft3.freezeBaseURI(); emit BaseURIFrozen(address(nft3)); }
        if (!nft4.uriFrozen()) { nft4.freezeBaseURI(); emit BaseURIFrozen(address(nft4)); }
        if (!nft5.uriFrozen()) { nft5.freezeBaseURI(); emit BaseURIFrozen(address(nft5)); }
        emit AllBaseURIsFrozen();
    }

    // Optional: hand off ownership of all contracts once setup is done
    function transferAllOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero addr");
        nft1.transferOwnership(newOwner);
        nft2.transferOwnership(newOwner);
        nft3.transferOwnership(newOwner);
        nft4.transferOwnership(newOwner);
        nft5.transferOwnership(newOwner);
        store.transferOwnership(newOwner);
    }

    // ---------------------------------------------------------
// ✅ Transfer ownership of all NFTs + Store to CONTRACT_OWNER_MINT_TO
// ---------------------------------------------------------
    function transferAllContractsToOwner() external onlyOwner {
    require(CONTRACT_OWNER_MINT_TO != address(0), "Invalid owner");

        // Transfer NFT ownerships
        nft1.transferOwnership(CONTRACT_OWNER_MINT_TO);
        emit OwnershipTransferred(address(nft1), CONTRACT_OWNER_MINT_TO);

        nft2.transferOwnership(CONTRACT_OWNER_MINT_TO);
        emit OwnershipTransferred(address(nft2), CONTRACT_OWNER_MINT_TO);

        nft3.transferOwnership(CONTRACT_OWNER_MINT_TO);
        emit OwnershipTransferred(address(nft3), CONTRACT_OWNER_MINT_TO);

        nft4.transferOwnership(CONTRACT_OWNER_MINT_TO);
        emit OwnershipTransferred(address(nft4), CONTRACT_OWNER_MINT_TO);

        nft5.transferOwnership(CONTRACT_OWNER_MINT_TO);
        emit OwnershipTransferred(address(nft5), CONTRACT_OWNER_MINT_TO);

        // Transfer Store ownership
        store.transferOwnership(CONTRACT_OWNER_MINT_TO);
        emit OwnershipTransferred(address(store), CONTRACT_OWNER_MINT_TO);

        emit OwnershipTransferredAll(CONTRACT_OWNER_MINT_TO);
    }

}
