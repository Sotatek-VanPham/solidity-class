// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract SotatekStandardToken is ERC20 {
    address owner;
    mapping(address => bool) private _blacklist;
    address public treasury;
    uint public constant TAX = 5000;

     constructor() ERC20("TNC Token", "TNC"){
        owner = msg.sender;
        _mint(msg.sender, 100000000000000000000000);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner address");
        _;
    }

    function transfer(address _to, uint _amount) public override returns (bool) {
        require(!_blacklist[msg.sender], "You are on the blacklist");
        require(!_blacklist[_to], "Recipient on the blacklist");
        uint taxAmount = (_amount * TAX) / 100000;
        uint256 remainAmount = _amount - taxAmount;
        _transfer(msg.sender, treasury, taxAmount);
        _transfer(msg.sender, _to, remainAmount);
        return true;
    }

    function mint(
        address _to,
        uint _amount
    ) external onlyOwner returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    function burn(uint _amount) external onlyOwner returns (bool) {
        _burn(msg.sender, _amount);
        return true;
    }

    function addToBlacklist(address _user) external onlyOwner returns (bool) {
        require(!_blacklist[_user], "The address already exists in the blacklist");
        _blacklist[_user] = true;
        return true;
    }

    function removeFromBlacklist(address _user) external onlyOwner returns (bool) {
        require(_blacklist[_user], "The address is not on the blacklist");
        _blacklist[_user] = false;
        return true;
    }

    function updateTreasury(address _treasury) external onlyOwner returns (bool) {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
        return true;
    }
}