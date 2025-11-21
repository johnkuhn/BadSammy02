// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// ETH_DISABLED: Remove Chainlink import since we are not using ETH pricing
// import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * BadSammyNFTStore (USDC-ONLY MODE)
 * ETH purchasing & price conversion have been commented out.
 * This is a simplified version for launch using ONLY USDC.
 */
contract BadSammyNFTStore is ReentrancyGuard, Ownable, IERC721Receiver {

    using SafeERC20 for IERC20;

    struct Tier {
        address nft;          // ERC721Enumerable collection
        uint256 priceUsdc;    // USDC price (6 decimals)
        bool enabled;
    }

    // tierId => configuration
    mapping(uint256 => Tier) public tiers;

    address payable public treasury;  // Receives USDC payments
    IERC20 public immutable USDC;     // Payment token (USDC)

    // ================================
    // ETH_DISABLED. ETH pricing temporarily disabled
    // ================================
    // AggregatorV3Interface public ethUsdPriceFeed;

    error InvalidTier();
    error TierDisabled();
    error SoldOut();
    error PaymentIncorrect();
    error ZeroAddress();

    constructor(
        address initialOwner,
        address payable _treasury,
        address usdc
        // ETH_DISABLED: remove price feed from constructor
        // address _ethUsdPriceFeed
    ) Ownable(initialOwner) 
    {
        if (_treasury == address(0) || usdc == address(0)) {
            revert ZeroAddress();
        }

        treasury = _treasury;
        USDC = IERC20(usdc);

        // ETH_DISABLED: commenting out oracle feed
        // ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
    }

    // ================================
    // Tier Management
    // ================================
    function setTreasury(address payable _treasury) external onlyOwner {
        if (_treasury == address(0)) revert ZeroAddress();
        treasury = _treasury;
    }

    function setTier(
        uint256 tierId,
        address nftAddress,
        uint256 priceUsdcUnits,
        bool enabled
    ) external onlyOwner {
        tiers[tierId] = Tier({
            nft: nftAddress,
            priceUsdc: priceUsdcUnits,
            enabled: enabled
        });
    }

    function _nextToken(address nft) internal view returns (uint256) {
        IERC721Enumerable en = IERC721Enumerable(nft);
        uint256 bal = en.balanceOf(address(this));
        if (bal == 0) revert SoldOut();
        return en.tokenOfOwnerByIndex(address(this), 0);
    }

    // ================================
    // ETH_DISABLED. ETH purchasing DISABLED
    // ================================
    /*
    function buyWithETH(uint256 tierId) external payable nonReentrant {
        revert("ETH purchasing temporarily disabled");
    }

    function getEthPriceForTier(uint256 tierId) external view returns (uint256) {
        revert("ETH price lookup disabled");
    }
    */

    // ================================
    // USDC Purchasing
    // ================================
    function buyWithUSDC(uint256 tierId) public nonReentrant {
        Tier memory t = tiers[tierId];
        if (t.nft == address(0)) revert InvalidTier();
        if (!t.enabled || t.priceUsdc == 0) revert TierDisabled();

        uint256 tokenId = _nextToken(t.nft);

        USDC.safeTransferFrom(msg.sender, address(this), t.priceUsdc);
        USDC.safeTransfer(treasury, t.priceUsdc);

        IERC721(t.nft).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function buyWithUSDCPermit(
        uint256 tierId,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        Tier memory t = tiers[tierId];
        if (t.nft == address(0)) revert InvalidTier();
        if (!t.enabled || t.priceUsdc == 0) revert TierDisabled();
        require(value == t.priceUsdc, "permit value mismatch");

        IERC20Permit(address(USDC)).permit(
            msg.sender, address(this), value, deadline, v, r, s
        );

        buyWithUSDC(tierId);
    }

    // ================================
    // Admin – Withdrawals & Rescue
    // ================================
    function sweepERC20(address token, address to) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to, bal);
    }

    function withdrawNFT(uint256 tierId, uint256 tokenId, address to) external onlyOwner {
        Tier memory t = tiers[tierId];
        if (t.nft == address(0)) revert InvalidTier();

        IERC721(t.nft).safeTransferFrom(address(this), to, tokenId);
    }

    function withdrawN(uint256 tierId, uint256 quantity, address to) external onlyOwner {
        Tier memory t = tiers[tierId];
        if (t.nft == address(0)) revert InvalidTier();

        IERC721Enumerable nft = IERC721Enumerable(t.nft);
        uint256 bal = nft.balanceOf(address(this));
        if (quantity > bal) quantity = bal;

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = nft.tokenOfOwnerByIndex(address(this), 0);
            IERC721(t.nft).safeTransferFrom(address(this), to, tokenId);
        }
    }

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

    // Safety: receive NFTs
    function onERC721Received(address, address, uint256, bytes calldata) 
        external pure override returns (bytes4) 
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    // Safety: receive ETH (unused now)
    receive() external payable {}
}
