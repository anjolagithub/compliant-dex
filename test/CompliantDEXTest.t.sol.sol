// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/CompliantDEX.sol";
import "../src/KYCRegistry.sol";
import "../src/LiquidityPool.sol";
import "../src/PriceOracle.sol";
import "../src/LPToken.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10**decimals());
    }
}

contract MockFlashLoanReceiver {
    function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata
    ) external returns (bool) {
        IERC20(token).transfer(msg.sender, amount + fee);
        return true;
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
    
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        // Setup owner and users
        owner = address(this);  // Use the default address (this contract's address)
        user1 = address(0x1);
        user2 = address(0x2);

        vm.label(user1, "User1");
        vm.label(user2, "User2");

        // Deploy mock tokens
        tokenA = new MockToken("Token A", "TKNA");
        tokenB = new MockToken("Token B", "TKNB");

        // Deploy core contracts
        priceOracle = new PriceOracle(owner);
        lpToken = new LPToken(owner);
        kycRegistry = new KYCRegistry(owner);
        liquidityPool = new LiquidityPool(
            address(priceOracle),
            address(lpToken),
            owner
        );
        dex = new CompliantDEX(
            address(kycRegistry),
            address(liquidityPool),
            address(priceOracle),
            owner  // Use the owner here, which is this contract's address
        );

        // Authorize the pool in LPToken (must be done by the owner)
        vm.startPrank(owner);
        lpToken.setAuthorizedPool(address(liquidityPool));
        vm.stopPrank();

        // Setup initial token prices
        priceOracle.updatePrice(address(tokenA), 1e18); // 1 USD
        priceOracle.updatePrice(address(tokenB), 1e18); // 1 USD

        // Fund test users
        tokenA.transfer(user1, 10000 * 10**18);
        tokenB.transfer(user1, 10000 * 10**18);
        tokenA.transfer(user2, 10000 * 10**18);
        tokenB.transfer(user2, 10000 * 10**18);
    }

    function testKYCVerification() public {
        assertFalse(kycRegistry.isKYCValid(user1));
        
        uint256 expiryTime = block.timestamp + 365 days;
        kycRegistry.updateKYCStatus(user1, true, expiryTime, 1);
        
        assertTrue(kycRegistry.isKYCValid(user1));
    }

    function testPoolCreation() public {
        vm.startPrank(user1);
        
        bytes32 poolId = liquidityPool.createPool(address(tokenA), address(tokenB));
        assertTrue(liquidityPool.poolExists(poolId));
        
        vm.stopPrank();
    }

    function testAddLiquidity() public {
        vm.startPrank(user1);
        
        // Create pool
        bytes32 poolId = liquidityPool.createPool(address(tokenA), address(tokenB));
        assertTrue(liquidityPool.poolExists(poolId));
        
        // Approve tokens
        tokenA.approve(address(liquidityPool), 1000 * 10**18);
        tokenB.approve(address(liquidityPool), 1000 * 10**18);
        
        // Add liquidity
        uint256 lpTokens = liquidityPool.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000 * 10**18,
            1000 * 10**18,
            0
        );
        
        assertTrue(lpTokens > 0);
        vm.stopPrank();
    }

    function testSwap() public {
        // Setup KYC for user1
        uint256 expiryTime = block.timestamp + 365 days;
        kycRegistry.updateKYCStatus(user1, true, expiryTime, 1);
        
        // Setup pool with initial liquidity
        vm.startPrank(user1);
        bytes32 poolId = liquidityPool.createPool(address(tokenA), address(tokenB));
        
        tokenA.approve(address(liquidityPool), 1000 * 10**18);
        tokenB.approve(address(liquidityPool), 1000 * 10**18);
        liquidityPool.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000 * 10**18,
            1000 * 10**18,
            0
        );
        
        // Perform swap
        tokenA.approve(address(dex), 100 * 10**18);
        uint256 amountOut = dex.swap(
            address(tokenA),
            address(tokenB),
            100 * 10**18,
            90 * 10**18
        );
        
        assertTrue(amountOut >= 90 * 10**18);
        vm.stopPrank();
    }

    function testFailSwapWithoutKYC() public {
        vm.startPrank(user1);
        
        tokenA.approve(address(dex), 100 * 10**18);
        vm.expectRevert();
        dex.swap(
            address(tokenA),
            address(tokenB),
            100 * 10**18,
            90 * 10**18
        );
        
        vm.stopPrank();
    }

    function testFlashLoan() public {
        // Setup pool with initial liquidity
        vm.startPrank(user1);
        bytes32 poolId = liquidityPool.createPool(address(tokenA), address(tokenB));
        
        tokenA.approve(address(liquidityPool), 1000 * 10**18);
        tokenB.approve(address(liquidityPool), 1000 * 10**18);
        liquidityPool.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000 * 10**18,
            1000 * 10**18,
            0
        );
        
        // Deploy flash loan receiver
        MockFlashLoanReceiver receiver = new MockFlashLoanReceiver();
        
        // Perform flash loan
        bytes memory data = "";
        liquidityPool.flashLoan(
            address(tokenA),
            100 * 10**18,
            data
        );
        
        vm.stopPrank();
    }
}
