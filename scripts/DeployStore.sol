// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//import "../contracts/BadSammyNFT.sol";
import "../contracts/BadSammyNFTStore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeployStore is Ownable {
    // ---- Addresses ----
    // TODO: put our contract/founder owner back in place after remix vm testing.
    address constant CONTRACT_OWNER_MINT_TO = 0x832F90cf5374DC89D7f8d2d2ECb94337f54Dd537; // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    // TODO: put our Treasury wallet address back in after remix vm testing.
    address payable public constant TREASURY = payable(0x643A87055213c3ce6d0BE9B1762A732e9E059536); // payable(0x6150518d33Cfa0e9B9afFd13795a1C2540c972d7);

    // TODO: make sure below is valid USDC address on Base.
    address public constant USDC = 0x36952592150f3AED54c1EC3C85213e1eD5CC1559; // 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // USDC on Base chain

    
    //TODO: set these to the various NFT addresses after they've been deployed
    // ---- Deployed contracts ----
    address constant nft1 = 0x00279436D53101CC7Bd78770F7ACb07cf7B6aBCA;
    address constant nft2 = 0x00279436D53101CC7Bd78770F7ACb07cf7B6aBCA;
    address constant nft3 = 0x00279436D53101CC7Bd78770F7ACb07cf7B6aBCA;
    address constant nft4 = 0x00279436D53101CC7Bd78770F7ACb07cf7B6aBCA;
    address constant nft5 = 0x00279436D53101CC7Bd78770F7ACb07cf7B6aBCA;

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

    //Step 3: Transfer ownership
    function transferContractToOwner() external onlyOwner {
        require(CONTRACT_OWNER_MINT_TO != address(0), "Invalid owner");

        store.transferOwnership(CONTRACT_OWNER_MINT_TO);

        emit OwnershipTransferred(CONTRACT_OWNER_MINT_TO);
    }
}
