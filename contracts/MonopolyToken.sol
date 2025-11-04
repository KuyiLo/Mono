// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract MonopolyToken is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18; // 初始发行 100 万代币

    constructor() ERC20("Monopoly Token", "MPT") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    // 允许合约所有者增发代币
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // 允许合约所有者销毁代币
    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }
}


