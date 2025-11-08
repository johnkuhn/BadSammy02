// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * BadSammyNFTStore (OZ v5)
 * To be used by Base Mini App. OpenSea will not use this but will go directly to Inventory Wallet.
 * - Primary sales for multiple ERC721Enumerable collections (tiers)
 * - Accepts ETH and/or USDC per tier
 * - Store holds inventory so it can transfer immediately
 * - Auto-picks the next token owned by the store
 */
contract BadSammyNFTStore is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct Tier {
        address nft;          // ERC721Enumerable collection
        uint256 priceEth;     // 0 if disabled
        uint256 priceUsdc;    // 0 if disabled
        bool enabled;
    }

    // tierId => configuration
    mapping(uint256 => Tier) public tiers;

    address payable public treasury; // receives ETH
    IERC20 public immutable USDC;    // stablecoin contract

    error InvalidTier();
    error TierDisabled();
    error SoldOut();
    error PaymentIncorrect();
    error ZeroAddress();

    constructor(address initialOwner, address payable _treasury, address usdc)
        Ownable(initialOwner)
    {
        if (_treasury == address(0) || usdc == address(0)) revert ZeroAddress();
        treasury = _treasury;
        USDC = IERC20(usdc);
    }

    // ------- Admin -------
    function setTreasury(address payable _treasury) external onlyOwner {
        if (_treasury == address(0)) revert ZeroAddress();
        treasury = _treasury;
    }

    function setTier(
        uint256 tierId,
        address nftAddress,
        uint256 priceEthWei,
        uint256 priceUsdcUnits, // e.g., 6 decimals on Base USDC
        bool enabled
    ) external onlyOwner {
        tiers[tierId] = Tier(nftAddress, priceEthWei, priceUsdcUnits, enabled);
    }

    // ------- Internals -------
    function _nextToken(address nft) internal view returns (uint256) {
        IERC721Enumerable en = IERC721Enumerable(nft);
        uint256 bal = en.balanceOf(address(this));
        if (bal == 0) revert SoldOut();
        return en.tokenOfOwnerByIndex(address(this), 0);
    }

    // ------- Buys -------
    function buyWithETH(uint256 tierId) external payable nonReentrant {
        Tier memory t = tiers[tierId];
        if (t.nft == address(0)) revert InvalidTier();
        if (!t.enabled || t.priceEth == 0) revert TierDisabled();
        if (msg.value != t.priceEth) revert PaymentIncorrect();

        uint256 tokenId = _nextToken(t.nft);

        // Pay treasury
        (bool ok, ) = treasury.call{value: msg.value}("");
        require(ok, "ETH transfer failed");

        // Deliver NFT
        IERC721(t.nft).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    // If buyer already did USDC.approve(store, price)
    function buyWithUSDC(uint256 tierId) public nonReentrant {
        Tier memory t = tiers[tierId];
        if (t.nft == address(0)) revert InvalidTier();
        if (!t.enabled || t.priceUsdc == 0) revert TierDisabled();

        uint256 tokenId = _nextToken(t.nft);

        // Pull USDC from buyer
        USDC.safeTransferFrom(msg.sender, address(this), t.priceUsdc);
        // Forward to treasury
        USDC.safeTransfer(treasury, t.priceUsdc);

        // Deliver NFT
        IERC721(t.nft).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    // Optional permit-style buy to skip separate approve (if USDC supports EIP-2612; many do not)
    function buyWithUSDCPermit(
        uint256 tierId,
        uint256 value,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external nonReentrant {
        Tier memory t = tiers[tierId];
        if (t.nft == address(0)) revert InvalidTier();
        if (!t.enabled || t.priceUsdc == 0) revert TierDisabled();
        require(value == t.priceUsdc, "permit value mismatch");

        // Permit (if token supports it)
        IERC20Permit(address(USDC)).permit(msg.sender, address(this), value, deadline, v, r, s);

        // Regular buy
        buyWithUSDC(tierId);
    }

    // Safety: recover accidentally sent ERC20
    function sweepERC20(address token, address to) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to, bal);
    }

    // Optionally withdraw stranded NFTs (admin)
    function withdrawNFT(uint256 tierId, uint256 tokenId, address to) external onlyOwner {
        Tier memory t = tiers[tierId];
        if (t.nft == address(0)) revert InvalidTier();

        IERC721(t.nft).safeTransferFrom(address(this), to, tokenId);
    }

    //Withdraw x amount of tokens per tier. Withdraw the first N NFTs the store owns
    function withdrawN(uint256 tierId, uint256 quantity, address to) external onlyOwner {
        Tier memory t = tiers[tierId];
        if (t.nft == address(0)) revert InvalidTier();

        IERC721Enumerable nft = IERC721Enumerable(t.nft);
        uint256 bal = nft.balanceOf(address(this));

        if (quantity > bal) {
            quantity = bal; // cap to available inventory
        }

        for (uint256 i = 0; i < quantity; i++) {
            // Always pull the first token the store owns
            uint256 tokenId = nft.tokenOfOwnerByIndex(address(this), 0);
            IERC721(t.nft).safeTransferFrom(address(this), to, tokenId);
        }
    }

    //Withdraw everything in one tier. Clears the store’s inventory for a given NFT collection.
    function withdrawAll(uint256 tierId, address to) external onlyOwner {
        Tier memory t = tiers[tierId];
        if (t.nft == address(0)) revert InvalidTier();

        IERC721Enumerable nft = IERC721Enumerable(t.nft);
        uint256 bal = nft.balanceOf(address(this));

        for (uint256 i = 0; i < bal; i++) {
            uint256 tokenId = nft.tokenOfOwnerByIndex(address(this), 0);
            IERC721(t.nft).safeTransferFrom(address(this), to, tokenId);
        }
    }

    //if you want selective range withdrawals. Possibly withdrawing specific blocks.
    function withdrawRange(
        uint256 tierId,
        uint256 startTokenId,
        uint256 endTokenId,
        address to) external onlyOwner {
        Tier memory t = tiers[tierId];
        if (t.nft == address(0)) revert InvalidTier();

        IERC721 nft = IERC721(t.nft);

        for (uint256 tokenId = startTokenId; tokenId <= endTokenId; tokenId++) {
            // Only withdraw if this contract currently owns it
            if (nft.ownerOf(tokenId) == address(this)) {
                nft.safeTransferFrom(address(this), to, tokenId);
            }
        }
    }


    // Safety: receive ETH
    receive() external payable {}
}