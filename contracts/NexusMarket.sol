// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// OpenZeppelin
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NexusMarket is 
    ERC721URIStorage,
    ERC2981,
    EIP712,
    ReentrancyGuard,
    Ownable
{
    using ECDSA for bytes32;

    uint256 private _tokenIds;

    uint96 public platformFee; // basis points (200 = 2%)
    address public feeRecipient;

    struct Listing {
        uint128 price;
        uint64 expiry;
        address seller;
    }

    mapping(uint256 => Listing) public listings;
    mapping(address => uint256) public pendingWithdrawals;
    mapping(bytes32 => bool) public committedOrders;
    mapping(address => uint256) public nonces;

    bytes32 private constant ORDER_TYPEHASH =
        keccak256("Order(uint256 tokenId,uint256 price,uint256 nonce,uint256 expiry)");

    constructor()
        ERC721("NexusMarket", "NEX")
        EIP712("NexusMarket", "1")
    {
        platformFee = 200;
        feeRecipient = msg.sender;
    }

    // =========================
    // MINT
    // =========================

    function mint(
        address to,
        string memory uri,
        uint96 royaltyFee
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
    // LIST
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
    // BUY WITH SIGNATURE
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

        // Commit-reveal check
        bytes32 commitment = keccak256(
            abi.encode(msg.sender, tokenId, price, nonce)
        );
        require(committedOrders[commitment], "Order not committed");
        delete committedOrders[commitment];

        // EIP712 verification
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

        // Ownership re-check
        require(ownerOf(tokenId) == seller, "Seller no longer owner");

        _executeSale(tokenId, seller, msg.sender, price);

        // Refund extra ETH
        if (msg.value > price) {
            (bool ok, ) = msg.sender.call{value: msg.value - price}("");
            require(ok, "Refund failed");
        }
    }

    // =========================
    // DIRECT BUY
    // =========================

    function buy(uint256 tokenId) external payable nonReentrant {
        Listing memory l = listings[tokenId];

        require(l.price > 0, "Not listed");
        require(block.timestamp <= l.expiry, "Expired");
        require(msg.value >= l.price, "Low ETH");
        require(ownerOf(tokenId) == l.seller, "Invalid seller");

        _executeSale(tokenId, l.seller, msg.sender, l.price);

        delete listings[tokenId];

        // Refund extra ETH
        if (msg.value > l.price) {
            (bool ok, ) = msg.sender.call{value: msg.value - l.price}("");
            require(ok, "Refund failed");
        }
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

        uint256 platformCut = (amount * platformFee) / 10000;

        (address royaltyReceiver, uint256 royaltyAmount) =
            royaltyInfo(tokenId, amount);

        uint256 sellerAmount = amount - platformCut - royaltyAmount;

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
        require(fee <= 1000, "Too high");
        platformFee = fee;
    }

    function setFeeRecipient(address to) external onlyOwner {
        feeRecipient = to;
    }

    // =========================
    // INTERFACE SUPPORT
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
