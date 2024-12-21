// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { Pausable } from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import "../src/KYCRegistry.sol";
import "../src/LiquidityPool.sol";

contract CompliantDEX is ReentrancyGuard, Pausable, Ownable {
    KYCRegistry public kycRegistry;
    LiquidityPool public liquidityPool;
    PriceOracle public priceOracle;

    uint256 public constant TRADE_FEE = 30; // 0.3%
    uint256 public constant FEE_DENOMINATOR = 10000;

    event Swap(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(
        address _kycRegistry,
        address _liquidityPool,
        address _priceOracle,
        address initialOwner
    ) Ownable(initialOwner) {  // Correctly call Ownable constructor with initialOwner
        kycRegistry = KYCRegistry(_kycRegistry);
        liquidityPool = LiquidityPool(_liquidityPool);
        priceOracle = PriceOracle(_priceOracle);
    }

    modifier onlyKYCVerified() {
        require(kycRegistry.isKYCValid(msg.sender), "KYC verification required");
        _;
    }

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) external nonReentrant onlyKYCVerified whenNotPaused returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid amount");
        require(tokenIn != tokenOut, "Same tokens");

        bytes32 poolId = keccak256(abi.encodePacked(tokenIn, tokenOut));
        require(liquidityPool.poolExists(poolId), "Pool not found");

        // Get pool data using the new getter function
        LiquidityPool.Pool memory pool = liquidityPool.getPool(poolId);
        
        amountOut = calculateAmountOut(amountIn, pool.tokenAReserve, pool.tokenBReserve);
        require(amountOut >= minAmountOut, "Insufficient output amount");

        // Execute swap
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
        return amountOut;
    }

    function calculateAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256) {
        require(amountIn > 0, "Invalid amount");
        require(reserveIn > 0 && reserveOut > 0, "Invalid reserves");

        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - TRADE_FEE);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * FEE_DENOMINATOR) + amountInWithFee;
        return numerator / denominator;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
