// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGraceToken {
    function mint(address to, uint256 amount) external;
}

contract GraceDonation is Ownable {
    using SafeERC20 for IERC20;

    address payable public treasuryWallet;
    IGraceToken public graceToken;
    IERC20 public usdtToken;
    uint256 public constant EXCHANGE_RATE = 0.1 ether; // 0.1 GRACE per 1 USDT/POL
    uint256 public totalDonated;
    
    // Milestone levels (in USDT/POL, assuming 18 decimals for POL, 6 for USDT)
    uint256[] public milestones = [
        1000 * 10**6,    // 1,000 USDT/POL
        5000 * 10**6,    // 5,000
        10000 * 10**6,   // 10,000
        50000 * 10**6    // 50,000
    ];
    uint256 public currentMilestone;

    event DonatedPOL(address indexed donor, uint256 amount, uint256 graceMinted, uint256 newTotal);
    event DonatedUSDT(address indexed donor, uint256 amount, uint256 graceMinted, uint256 newTotal);
    event MilestoneReached(uint256 milestoneAmount, uint256 milestoneIndex);

    constructor(
        address payable _treasuryWallet,
        address _graceToken,
        address _usdtToken,
        address initialOwner
    ) Ownable(initialOwner) {
        require(_treasuryWallet != address(0), "Invalid treasury wallet");
        require(_graceToken != address(0), "Invalid token address");
        require(_usdtToken != address(0), "Invalid USDT address");
        
        treasuryWallet = _treasuryWallet;
        graceToken = IGraceToken(_graceToken);
        usdtToken = IERC20(_usdtToken);
    }

    function donatePOL() external payable {
        require(msg.value > 0, "Zero donation not allowed");

        // Forward POL to treasury
        (bool sent, ) = treasuryWallet.call{value: msg.value}("");
        require(sent, "POL transfer failed");

        // Mint GRACE (0.1 GRACE per POL)
        uint256 graceAmount = (msg.value * EXCHANGE_RATE) / 1 ether;
        graceToken.mint(msg.sender, graceAmount);

        // Update total donated (convert POL to 6 decimals for consistency)
        totalDonated += msg.value / 10**12; // POL (18 decimals) to USDT equivalent (6 decimals)
        _checkMilestone();

        emit DonatedPOL(msg.sender, msg.value, graceAmount, totalDonated);
    }

    function donateUSDT(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // Transfer USDT directly to treasury
        usdtToken.safeTransferFrom(msg.sender, treasuryWallet, amount);

        // Mint GRACE (0.1 GRACE per USDT)
          uint256 graceAmount = (amount * EXCHANGE_RATE) / (10**IERC20Metadata(address(usdtToken)).decimals());
        graceToken.mint(msg.sender, graceAmount);

        // Update total donated
        totalDonated += amount;
        _checkMilestone();

        emit DonatedUSDT(msg.sender, amount, graceAmount, totalDonated);
    }

    function updateTreasuryWallet(address payable newWallet) external onlyOwner {
        require(newWallet != address(0), "Invalid address");
        treasuryWallet = newWallet;
    }

    function _checkMilestone() internal {
        for (uint256 i = currentMilestone; i < milestones.length; i++) {
            if (totalDonated >= milestones[i]) {
                currentMilestone = i + 1;
                emit MilestoneReached(milestones[i], i);
            } else {
                break;
            }
        }
    }

    // View function to get donor's total donations
    //function getDonorTotal(address donor) external view returns (uint256) {
        // Note: Requires off-chain tracking or additional storage
      //  return 0; // Placeholder (implement if needed)
}
