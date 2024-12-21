// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract LPToken is ERC20, Ownable {
    // Mapping from pool ID to whether this token is used for that pool
    mapping(bytes32 => bool) public poolTokens;
    
    // Only the liquidity pool contract should be able to mint/burn
    address public liquidityPool;
    
    event LiquidityPoolSet(address indexed liquidityPool);
    
    constructor(address initialOwner) 
        ERC20("DEX LP Token", "LP-DEX") 
        Ownable(initialOwner) 
    {}
address public authorizedPool;

function setAuthorizedPool(address pool) external onlyOwner {
    authorizedPool = pool;
}


    
    function setLiquidityPool(address _liquidityPool) external onlyOwner {
        require(_liquidityPool != address(0), "Invalid address");
        require(liquidityPool == address(0), "LP already set");
        liquidityPool = _liquidityPool;
        emit LiquidityPoolSet(_liquidityPool);
    }
    
    function mint(address account, uint256 amount) external {
        require(msg.sender == liquidityPool, "Only liquidity pool can mint");
        _mint(account, amount);
    }
    
    function burn(address account, uint256 amount) external {
        require(msg.sender == liquidityPool, "Only liquidity pool can burn");
        _burn(account, amount);
    }
    
    function registerPool(bytes32 poolId) external {
        require(msg.sender == liquidityPool, "Only liquidity pool can register");
        require(!poolTokens[poolId], "Pool already registered");
        poolTokens[poolId] = true;
    }
}