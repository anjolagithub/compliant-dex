// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract PriceOracle is Ownable {
    mapping(address => uint256) public prices;
    
    event PriceUpdated(address token, uint256 price);
    
    constructor(address initialOwner) Ownable(initialOwner) {}
    
    function updatePrice(address token, uint256 price) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(price > 0, "Price must be greater than 0");
        prices[token] = price;
        emit PriceUpdated(token, price);
    }
    
    function getPrice(address token) external view returns (uint256) {
        require(prices[token] > 0, "Price not available");
        return prices[token];
    }
    
    function batchUpdatePrices(
        address[] calldata tokens,
        uint256[] calldata newPrices
    ) external onlyOwner {
        require(tokens.length == newPrices.length, "Length mismatch");
        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokens[i] != address(0), "Invalid token address");
            require(newPrices[i] > 0, "Price must be greater than 0");
            prices[tokens[i]] = newPrices[i];
            emit PriceUpdated(tokens[i], newPrices[i]);
        }
    }
}