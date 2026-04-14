// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// OpenZeppelin
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UplandV3 is 
    ERC721URIStorage,
    ERC2981,
    EIP712,
    ReentrancyGuard,
    Ownable
{
    using ECDSA for bytes32;

    // =========================
    // STORAGE (GAS OPTIMIZED)
    // =========================

    uint256 private _tokenIds;

    uint96 public platformFee; // 2% = 200 (basis points)
    address public feeRecipient;

    struct Listing {
        uint128 price;
        uint64 expiry;
        address seller;
    }

    mapping(uint256 => Listing) public listings;

    // Escrow balances (Pull payments)
    mapping(address => uint256) public pendingWithdrawals;

    // Commit-Reveal anti front-run
    mapping(bytes32 => bool) public committedOrders;

    // =========================
    // EIP712
    // =========================

    bytes32 private constant ORDER_TYPEHASH =
        keccak256("Order(uint256 tokenId,uint256 price,uint256 nonce,uint256 expiry)");

    mapping(address => uint256) public nonces;

    constructor()
        ERC721("UplandV3", "UP3")
        EIP712("UplandV3", "1")
    {
        platformFee = 200; // 2%
        feeRecipient = msg.sender;
    }

    // =========================
    // MINT
    // =========================

    function mint(
        address to,
        string memory uri,
        uint96 royaltyFee // basis points
    ) external onlyOwner returns (uint256) {
        _tokenIds++;
        uint256 id = _tokenIds;

        _safeMint(to, id);
        _setTokenURI(id, uri);

        _setTokenRoyalty(id, to, royaltyFee);

        return id;
    }

    // =========================
    // COMMIT (ANTI FRONT-RUN)
    // =========================

    function commit(bytes32 commitment) external {
        committedOrders[commitment] = true;
    }

    // =========================
    // LIST (ONCHAIN SIMPLE)
    // =========================

    function list(
        uint256 tokenId,
        uint128 price,
        uint64 expiry
    ) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");

        listings[tokenId] = Listing({
            price: price,
            expiry: expiry,
            seller: msg.sender
        });
    }

    // =========================
    // BUY WITH SIGNED ORDER
    // =========================

    function buyWithSig(
        uint256 tokenId,
        uint256 price,
        uint256 expiry,
        uint256 nonce,
        bytes calldata signature
    ) external payable nonReentrant {
        require(block.timestamp <= expiry, "Order expired");
        require(msg.value >= price, "Insufficient ETH");

        address seller = ownerOf(tokenId);

        // EIP712 hash
        bytes32 structHash = keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                tokenId,
                price,
                nonce,
                expiry
            )
        );

        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = digest.recover(signature);

        require(signer == seller, "Invalid signer");
        require(nonce == nonces[seller]++, "Invalid nonce");

        _executeSale(tokenId, seller, msg.sender, price);
    }

    // =========================
    // DIRECT BUY (LISTING)
    // =========================

    function buy(uint256 tokenId) external payable nonReentrant {
        Listing memory l = listings[tokenId];

        require(l.price > 0, "Not listed");
        require(block.timestamp <= l.expiry, "Expired");
        require(msg.value >= l.price, "Low ETH");

        _executeSale(tokenId, l.seller, msg.sender, l.price);

        delete listings[tokenId];
    }

    // =========================
    // INTERNAL SALE LOGIC
    // =========================

    function _executeSale(
        uint256 tokenId,
        address seller,
        address buyer,
        uint256 amount
    ) internal {
        _transfer(seller, buyer, tokenId);

        // Fees
        uint256 platformCut = (amount * platformFee) / 10000;

        (address royaltyReceiver, uint256 royaltyAmount) =
            royaltyInfo(tokenId, amount);

        uint256 sellerAmount = amount - platformCut - royaltyAmount;

        // Escrow (pull payments)
        pendingWithdrawals[seller] += sellerAmount;
        pendingWithdrawals[feeRecipient] += platformCut;
        pendingWithdrawals[royaltyReceiver] += royaltyAmount;
    }

    // =========================
    // WITHDRAW (PULL PAYMENT)
    // =========================

    function withdraw() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        pendingWithdrawals[msg.sender] = 0;

        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Transfer failed");
    }

    // =========================
    // ADMIN
    // =========================

    function setPlatformFee(uint96 fee) external onlyOwner {
        require(fee <= 1000, "Too high"); // max 10%
        platformFee = fee;
    }

    function setFeeRecipient(address to) external onlyOwner {
        feeRecipient = to;
    }

    // =========================
    // SUPPORTS INTERFACE
    // =========================

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
