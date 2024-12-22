// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";

// KYCRegistry.sol
contract KYCRegistry is Ownable, Pausable, ReentrancyGuard {
    struct KYCData {
        bool isVerified;
        uint256 expiryTimestamp;
        uint256 kycLevel;
    }

    mapping(address => KYCData) public kycData;

    event KYCStatusUpdated(address indexed user, bool isVerified, uint256 expiryTimestamp, uint256 kycLevel);

    // Constructor initializes the Ownable contract with the specified owner
    constructor(address _owner) Ownable(_owner) {}

    function updateKYCStatus(
        address user,
        bool isVerified,
        uint256 expiryTimestamp,
        uint256 kycLevel
    ) external onlyOwner whenNotPaused nonReentrant {
        require(user != address(0), "Invalid address");
        require(expiryTimestamp > block.timestamp, "Invalid expiry");

        // Update the user's KYC data
        kycData[user] = KYCData(isVerified, expiryTimestamp, kycLevel);
        
        emit KYCStatusUpdated(user, isVerified, expiryTimestamp, kycLevel);
    }

    function isKYCValid(address user) public view returns (bool) {
        KYCData memory data = kycData[user];
        return data.isVerified && data.expiryTimestamp > block.timestamp;
    }
}


