// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERCToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("DKToken", "DKE") {
        _mint(msg.sender, initialSupply);
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }
}
