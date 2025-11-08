// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * SingleTierERC721Enumerable (OZ v5)
 * - Enumerable for "inventory wallet" UX + store auto-pick
 * - Start token IDs at 1
 * - Optional ERC-2981 royalties (unset by default)
 * - IPFS baseURI per contract, with one-way freeze
 * - Owner-only airdrop minting (you mint upfront to an inventory wallet)
 */
contract SingleTierERC721Enumerable is ERC721Enumerable, Ownable, ERC2981 {
    using Strings for uint256;

    uint256 public immutable MAX_SUPPLY;
    uint256 public minted;
    uint256 public nextTokenId = 1;

    string private _baseUri;
    bool public uriFrozen;

    error SoldOut();
    error UriFrozen();
    error NonexistentToken();

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        address initialOwner
    )
        ERC721(name_, symbol_)
        Ownable(initialOwner) // OZ v5 pattern
    {
        MAX_SUPPLY = maxSupply_;
        // No royalties set by default; you may set later with setRoyalty()
    }

    // ---------- Mint (owner airdrop) ----------
    function mintTo(address to, uint256 quantity) external onlyOwner {
        if (minted + quantity > MAX_SUPPLY) revert SoldOut();

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = nextTokenId++;
            minted += 1;
            _safeMint(to, tokenId);
        }
    }

    // ---------- Metadata ----------
    function setBaseURI(string calldata newBase) external onlyOwner {
        if (uriFrozen) revert UriFrozen();
        // Expect "ipfs://<CID>/"
        _baseUri = newBase;
    }

    function freezeBaseURI() external onlyOwner {
        uriFrozen = true; // one-way
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // OZ v5: prefer _requireOwned
        _requireOwned(tokenId);
        string memory base = _baseURI();
        return bytes(base).length == 0
            ? ""
            : string(abi.encodePacked(base, tokenId.toString(), ".json"));
    }

    // ---------- Helpers ----------
    function remainingSupply() external view returns (uint256) {
        return MAX_SUPPLY - minted;
    }

    // Convenience for UIs; O(N). Use offchain indexing for large wallets.
    function tokensOfOwner(address owner) external view returns (uint256[] memory ids) {
        uint256 n = balanceOf(owner);
        ids = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
    }

    // ---------- Optional royalties ----------
    // feeBps: 500 = 5.00%
    function setRoyalty(address receiver, uint96 feeBps) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBps);
    }

    function clearRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    // ---------- Interfaces ----------
    function supportsInterface(bytes4 iid)
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(iid);
    }
}
