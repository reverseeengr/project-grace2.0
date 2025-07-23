// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockUSDT is ERC20, Ownable {
    constructor(address initialOwner) ERC20("Mock USDT", "USDT") Ownable(initialOwner) {
        // Optionally mint initial supply to the owner
        _mint(initialOwner, 1_000_000 * 10 ** decimals()); // 1 million USDT (6 decimals)
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
