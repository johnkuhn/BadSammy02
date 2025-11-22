// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/BadSammyNFT.sol";
import "../contracts/BadSammyNFTStore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeployContractsOnly is Ownable {
    address constant CONTRACT_OWNER_MINT_TO =
        0x832F90cf5374DC89D7f8d2d2ECb94337f54Dd537;

    address payable public constant TREASURY =
        payable(0x643A87055213c3ce6d0BE9B1762A732e9E059536);

    address public constant USDC =
        0x36952592150f3AED54c1EC3C85213e1eD5CC1559;

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

    BadSammyNFT public nft1;
    BadSammyNFT public nft2;
    BadSammyNFT public nft3;
    BadSammyNFT public nft4;
    BadSammyNFT public nft5;
    BadSammyNFTStore public store;

    // ---- Events ----
    event NFTsDeployed(address nft1, address nft2, address nft3, address nft4, address nft5);
    event StoreDeployed(address store);

    constructor() Ownable(msg.sender) {}

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

    function deployStore() external onlyOwner returns (address) {
        require(address(nft1) != address(0), "NFTs not deployed");
        require(address(store) == address(0), "Store already deployed");

        store = new BadSammyNFTStore(address(this), TREASURY, USDC);

        emit StoreDeployed(address(store));
        return address(store);
    }
}
