// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GraceToken is ERC20, Ownable {
    address public donationContract;

    constructor(address initialOwner) 
        ERC20("Project Grace Token", "GRACE") 
        Ownable(initialOwner)
    {
        // Mint initial supply (1M tokens) to owner
        _mint(initialOwner, 1_000_000 * 10 ** decimals());
    }

    function setDonationContract(address _donationContract) external onlyOwner {
        require(_donationContract != address(0), "Invalid address");
        donationContract = _donationContract;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == donationContract, "Unauthorized");
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}