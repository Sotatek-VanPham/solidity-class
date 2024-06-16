// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract ERC721Mock is ERC721URIStorage {
    uint256 private _tokenIds;

    constructor() ERC721("ERC721Mock", "E721M") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
