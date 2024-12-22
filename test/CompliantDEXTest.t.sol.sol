// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import "../src/CompliantDEX.sol";
import "../src/KYCRegistry.sol";
import "../src/LiquidityPool.sol";
import "../src/PriceOracle.sol";
import "../src/LPToken.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// Mock token for testing purposes
contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10**decimals());
    }
}

contract CompliantDEXTest is Test {
    CompliantDEX public dex;
    KYCRegistry public kycRegistry;
    LiquidityPool public liquidityPool;
    PriceOracle public priceOracle;
    LPToken public lpToken;
    MockToken public tokenA;
    MockToken public tokenB;

    address public deployer;
    address public user1;
    address public user2;

  function setUp() public {
    deployer = makeAddr("deployer");
    user1 = makeAddr("user1");
    user2 = makeAddr("user2");

    vm.deal(deployer, 100 ether);

    vm.startPrank(deployer); // Start acting as deployer

    tokenA = new MockToken("Token A", "TKNA");
    tokenB = new MockToken("Token B", "TKNB");

    // Deploy contracts
    kycRegistry = new KYCRegistry(deployer); // Pass deployer as initial owner
    priceOracle = new PriceOracle(deployer);
    lpToken = new LPToken(deployer);
    liquidityPool = new LiquidityPool(address(priceOracle), address(lpToken), deployer);

    // Set the LiquidityPool for the LPToken and authorize it
    lpToken.setLiquidityPool(address(liquidityPool)); // Set liquidity pool
    lpToken.setAuthorizedPool(address(liquidityPool)); // Set authorized pool

    // Deploy CompliantDEX with KYC, LiquidityPool, and PriceOracle
    dex = new CompliantDEX(
        address(kycRegistry),
        address(liquidityPool),
        address(priceOracle),
        deployer
    );

    // Set prices in price oracle
    priceOracle.updatePrice(address(tokenA), 1e18);
    priceOracle.updatePrice(address(tokenB), 1e18);

    // Transfer tokens to users
    tokenA.transfer(user1, 10000 * 10**18);
    tokenB.transfer(user1, 10000 * 10**18);
    tokenA.transfer(user2, 10000 * 10**18);
    tokenB.transfer(user2, 10000 * 10**18);

    vm.stopPrank(); // Stop acting as deployer
}


    

    function testKYCVerification() public {
        assertFalse(kycRegistry.isKYCValid(user1));

        vm.startPrank(deployer); // Start acting as deployer

        uint256 expiryTime = block.timestamp + 365 days;
        
        // Update KYC status for user1
        kycRegistry.updateKYCStatus(user1, true, expiryTime, 1);
        
        vm.stopPrank(); // Stop acting as deployer
        
        assertTrue(kycRegistry.isKYCValid(user1));
    }

    function testPoolCreation() public {
        vm.startPrank(user1); // Start acting as user1
        
        // Create a liquidity pool with tokenA and tokenB
        bytes32 poolId = liquidityPool.createPool(address(tokenA), address(tokenB));
        
        assertTrue(liquidityPool.poolExists(poolId));
        
        vm.stopPrank(); // Stop acting as user1
    }

    function testAddLiquidity() public {
        // Setup KYC for user1 before adding liquidity
        vm.startPrank(deployer);
        
        uint256 expiryTime = block.timestamp + 365 days;
        
        // Update KYC status for user1
        kycRegistry.updateKYCStatus(user1, true, expiryTime, 1);
        
        vm.stopPrank();

        vm.startPrank(user1); // Start acting as user1
        
        // Create a pool for adding liquidity
        bytes32 poolId = liquidityPool.createPool(address(tokenA), address(tokenB));
        
        // Approve tokens for liquidity addition
        tokenA.approve(address(liquidityPool), 1000 * 10**18);
        tokenB.approve(address(liquidityPool), 1000 * 10**18);
        
        // Add liquidity to the pool
        uint256 lpTokens = liquidityPool.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000 * 10**18,
            1000 * 10**18,
            0 // minLPTokens
        );
        
        assertTrue(lpTokens > 0); // Ensure LP tokens were received
        
        vm.stopPrank(); // Stop acting as user1
    }
}
