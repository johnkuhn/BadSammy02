// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//import "../contracts/BadSammyNFT.sol";
import "../contracts/BadSammyNFTStore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeployStore is Ownable {
    // ---- Addresses ----
    // TODO: put our contract/founder owner back in place after remix vm testing.
    address constant CONTRACT_OWNER_MINT_TO = 0x3Cc463fd67146A6951062B85428b5f77828D5D09; // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    // TODO: put our Treasury wallet address back in after remix vm testing.
    address payable public constant TREASURY = payable(0xDa8291d1F21643c441d2637da5ae7F0990ab5678); // payable(0x6150518d33Cfa0e9B9afFd13795a1C2540c972d7);

    // TODO: make sure below is valid USDC address on Base.
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // USDC on Base chain

    
    //TODO: set these to the various NFT addresses after they've been deployed
    // ---- Deployed contracts ----
    address constant nft1 = 0xc74aE41BEBfB170f271Ec96600A16b566d6D64A6;
    address constant nft2 = 0x1B0FDa0F0F923fa849434e4B8BC065D1aB066894;
    address constant nft3 = 0xaBC906A76f46BC60f714F764e522d0e0f356FC2c;
    address constant nft4 = 0x96F98ad43e7118FaDcfe4D5B3B5D2a3A2ac47c64;
    address constant nft5 = 0x8c1052a761E584a9CA0456363BcA75ff720657c5;

    // ---- USDC Prices (ETH disabled) ----
    uint256 private constant USD1 = 100_000_000;    // $100
    uint256 private constant USD2 = 250_000_000;    // $250
    uint256 private constant USD3 = 500_000_000;    // $500
    uint256 private constant USD4 = 1_000_000_000;  // $1,000
    uint256 private constant USD5 = 2_500_000_000;  // $2,500
    

    BadSammyNFTStore public store;

    // ---- Events ----
    event StoreDeployed(address store);
    event TiersConfigured();
    event OwnershipTransferred(address newOwner);

    constructor() Ownable(msg.sender) {}



    // STEP 1: Deploy Store
    function deployStore() external onlyOwner returns (address) {
        require(address(store) == address(0), "Store already deployed");

        store = new BadSammyNFTStore(address(this), TREASURY, USDC); 

        emit StoreDeployed(address(store));
        return address(store);
    }

    

    //Step 2: Configure store tiers
    function configureStoreTiers() external onlyOwner {
        // ETH pricing removed — USDC only
        store.setTier(1, address(nft1), USD1, true);
        store.setTier(2, address(nft2), USD2, true);
        store.setTier(3, address(nft3), USD3, true);
        store.setTier(4, address(nft4), USD4, true);
        store.setTier(5, address(nft5), USD5, true);
        emit TiersConfigured();
    }

    function configureSpecificStoreTiers(uint256 tierId) external onlyOwner {
        // ETH pricing removed — USDC only
        if(tierId == 1)
            store.setTier(1, address(nft1), USD1, true);
        else if(tierId == 2)
            store.setTier(2, address(nft2), USD2, true);
        else if(tierId == 3)
            store.setTier(3, address(nft3), USD3, true);
        else if(tierId == 4)   
            store.setTier(4, address(nft4), USD4, true);
        else if(tierId == 5)
            store.setTier(5, address(nft5), USD5, true);
            
        emit TiersConfigured();
    }

    //Step 3: Transfer ownership
    function transferContractToOwner() external onlyOwner {
        require(CONTRACT_OWNER_MINT_TO != address(0), "Invalid owner");

        store.transferOwnership(CONTRACT_OWNER_MINT_TO);

        emit OwnershipTransferred(CONTRACT_OWNER_MINT_TO);
    }
}
