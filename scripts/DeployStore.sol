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
    address constant nft1 = Update_ME;
    address constant nft2 = 0x4712603746Fa727eDDe59bdC930AF12D07317901;
    address constant nft3 = 0x90A855045e7baffF24dcE6D8145c45a1F0c91368;
    address constant nft4 = 0x099FfDbE7b590141057B962D401279de3c4f65D4;
    address constant nft5 = 0x23178197a7880393b2DA8c83f3134867b04e2319;

    // ---- USDC Prices (ETH disabled) ----
    uint256 private constant USD1 = 10_000_000;    // $10
    uint256 private constant USD2 = 20_000_000;    // $20
    uint256 private constant USD3 = 50_000_000;    // $50
    uint256 private constant USD4 = 100_000_000;  // $100
    uint256 private constant USD5 = 200_000_000;  // $200
    

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
