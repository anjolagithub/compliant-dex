// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import "../src/PriceOracle.sol";
import "../src/LPToken.sol";

contract LiquidityPool is Ownable, ReentrancyGuard, Pausable {
    struct Pool {
        uint256 tokenAReserve;
        uint256 tokenBReserve;
        uint256 kFactor;
    }

    PriceOracle public priceOracle;
    LPToken public lpToken;
    
    mapping(bytes32 => Pool) public pools;
    mapping(bytes32 => bool) public poolExists;

    event PoolCreated(address indexed tokenA, address indexed tokenB);
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);
    event FlashLoan(address indexed token, uint256 amount, uint256 fee);

    constructor(
    address _priceOracle,
    address _lpToken,
    address initialOwner
) Ownable(initialOwner) {
    priceOracle = PriceOracle(_priceOracle);
    lpToken = LPToken(_lpToken);

    // Ensure LPToken has setAuthorizedPool function and call it directly
    lpToken.setAuthorizedPool(address(this));
}


    function createPool(address tokenA, address tokenB) external returns (bytes32) {
        require(tokenA != tokenB, "Same tokens");
        bytes32 poolId = keccak256(abi.encodePacked(tokenA, tokenB));
        require(!poolExists[poolId], "Pool exists");

        pools[poolId] = Pool(0, 0, 0);
        poolExists[poolId] = true;
        lpToken.registerPool(poolId);

        emit PoolCreated(tokenA, tokenB);
        return poolId;
    }

    function getPool(bytes32 poolId) external view returns (Pool memory) {
        require(poolExists[poolId], "Pool not found");
        return pools[poolId];
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 minLPTokens
    ) external nonReentrant returns (uint256) {
        bytes32 poolId = keccak256(abi.encodePacked(tokenA, tokenB));
        require(poolExists[poolId], "Pool not found");

        Pool storage pool = pools[poolId];
        
        // Transfer tokens
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        // Calculate LP tokens to mint
        uint256 lpTokensToMint;
        if (pool.kFactor == 0) {
            // For first liquidity provision, use geometric mean
            lpTokensToMint = Math.sqrt(amountA * amountB);
        } else {
            // For subsequent deposits, maintain proportions
            uint256 totalSupply = lpToken.totalSupply();
            uint256 tokenAShare = (amountA * totalSupply) / pool.tokenAReserve;
            uint256 tokenBShare = (amountB * totalSupply) / pool.tokenBReserve;
            lpTokensToMint = Math.min(tokenAShare, tokenBShare);
        }
        
        require(lpTokensToMint >= minLPTokens, "Insufficient LP tokens");

        pool.tokenAReserve += amountA;
        pool.tokenBReserve += amountB;
        pool.kFactor = pool.tokenAReserve * pool.tokenBReserve;

        // Mint LP tokens
        lpToken.mint(msg.sender, lpTokensToMint);

        emit LiquidityAdded(msg.sender, amountA, amountB);
        return lpTokensToMint;
    }

    function flashLoan(
        address token,
        uint256 amount,
        bytes calldata data
    ) external nonReentrant {
        require(amount > 0, "Invalid amount");
        uint256 fee = (amount * 10) / 10000; // 0.1% fee
        
        IERC20(token).transfer(msg.sender, amount);
        
        // Execute callback
        require(
            IERC20(token).balanceOf(address(this)) >= amount + fee,
            "Flash loan not repaid"
        );
        
        emit FlashLoan(token, amount, fee);
    }
}