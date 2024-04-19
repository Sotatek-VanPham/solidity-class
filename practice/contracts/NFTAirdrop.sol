// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFTAirdrop is ERC721 {
    address owner;
    bytes32 public merkleRoot;
    mapping(address => bool) public isWhitelisted;
    mapping(bytes32 => bool) public claimed;

    event WhitelistUpdated(address indexed account, bool isWhitelisted);

    constructor(bytes32 _merkleRoot) ERC721("NFTAirdrop", "NFTAD") {
        owner = msg.sender;
        merkleRoot = _merkleRoot;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner address");
        _;
    }

    function setWhitelistStatus(address[] calldata accounts, bool status) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isWhitelisted[accounts[i]] = status;
            emit WhitelistUpdated(accounts[i], status);
        }
    }

    function claim(bytes32[] memory proof, uint256 quantity) external {
        require(isWhitelisted[msg.sender], "Address not whitelisted");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, quantity));
        require(!claimed[leaf], "NFT already claimed");
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

        _mint(msg.sender, quantity);
        claimed[leaf] = true;
    }

    function removeWhitelist(address account) external onlyOwner {
        isWhitelisted[account] = false;
        emit WhitelistUpdated(account, false);
    }
}
