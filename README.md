# Compliant DEX - Decentralized Exchange with Liquidity Pools

## Overview

The **Compliant DEX** is a decentralized exchange (DEX) that allows users to trade assets securely with the integration of liquidity pools, price oracles, and a robust token management system. The platform is designed with compliance features, ensuring transparency, fairness, and security for all participants.

This project includes the implementation of smart contracts for the liquidity pool, price oracle, and LP token, providing a foundation for building a fully decentralized financial ecosystem.

### Features
- **Liquidity Pools:** Smart contracts that manage liquidity and facilitate token swaps.
- **LP Tokens:** Tokens representing a user’s share of liquidity in the pool.
- **Price Oracle:** A contract that manages token prices, allowing for accurate price feeds.
- **Ownable Contracts:** The `Ownable` contract ensures secure management of system settings and administration.

## Smart Contracts

The following key smart contracts are implemented:

1. **LPToken:** ERC20 token representing liquidity pool shares.
2. **PriceOracle:** Manages the price feed for tokens traded on the exchange.
3. **LiquidityPool:** Manages liquidity, token swaps, and the minting and burning of LP tokens.
4. **CompliantDEX:** The main contract that integrates KYC, liquidity pools, price oracles, and user interactions.

### Contract Details

#### LPToken Contract
The `LPToken` contract is an ERC20 token that represents the user's liquidity pool shares. It is mintable and burnable by the liquidity pool contract and can only be managed by the owner of the contract.

- **Functions:**
  - `mint()`: Allows the liquidity pool to mint new LP tokens.
  - `burn()`: Allows the liquidity pool to burn LP tokens.
  - `setLiquidityPool()`: Sets the address of the liquidity pool.
  - `setAuthorizedPool()`: Allows the contract owner to set the authorized pool.

#### PriceOracle Contract
The `PriceOracle` contract is responsible for managing token price updates. It allows the owner to update prices for any token and provides a `getPrice()` function to retrieve the price of a token.

- **Functions:**
  - `updatePrice()`: Allows the owner to update the price for a specific token.
  - `getPrice()`: Fetches the current price of a specific token.
  - `batchUpdatePrices()`: Updates the prices for multiple tokens in one call.

#### LiquidityPool Contract
The `LiquidityPool` contract manages liquidity for token swaps and allows users to add liquidity. It interacts with the `LPToken` contract to mint and burn LP tokens as users add and remove liquidity.

- **Functions:**
  - `addLiquidity()`: Allows users to add liquidity to the pool.
  - `removeLiquidity()`: Allows users to remove liquidity from the pool.
  - `swapTokens()`: Facilitates token swapping between different tokens.
  - `registerPool()`: Registers a pool within the liquidity pool.

#### CompliantDEX Contract
The `CompliantDEX` contract is the main interface that integrates the KYC, liquidity pool, and price oracle contracts. It facilitates the swapping of tokens and ensures that the liquidity pools and price oracles are used properly.

- **Functions:**
  - `swapTokens()`: Facilitates token swaps on the DEX.
  - `getPoolInfo()`: Retrieves information about a specific liquidity pool.
  - `getTokenPrice()`: Gets the current price of a token from the price oracle.

## Requirements

Before deploying or interacting with the contracts, ensure you have the following installed:

- [Foundry](https://github.com/foundry-rs/foundry) (v0.3.0 or higher)
- [Solidity](https://soliditylang.org/) (v0.8.19 or higher)
- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) (v5.1.0 or higher)

## Installation

1. **Clone the Repository:**
   ```bash
   git clone <repository-url>
   cd <project-directory>
   ```

2. **Install Foundry:**
   If you don’t have Foundry installed, follow these instructions:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

3. **Install Dependencies:**
   Foundry comes with `forge` and `cast` tools, which you can use to compile, test, and deploy your contracts. Install the necessary dependencies by running:
   ```bash
   forge install
   ```

4. **Compile the Contracts:**
   Use Foundry to compile the smart contracts:
   ```bash
   forge build
   ```

5. **Deploy the Contracts:**
   Deploy the contracts to a test network using Foundry’s deployment functionality. Update the script to deploy to the desired network:
   ```bash
   forge script <deployment-script> --rpc-url <rpc-url> --private-key <private-key>
   ```

## Testing

The smart contracts are tested using Foundry. To run the tests, execute the following command:

```bash
forge test
```

Ensure you have updated the tests in the `test/CompliantDEXTest.t.sol` file to match your contract logic.

## How to Interact with the Contracts

After deploying the contracts, you can interact with them via Foundry’s console or through any frontend integration. Here’s an example of interacting with the `PriceOracle` contract:

1. **Get Token Price:**
   ```solidity
   address priceOracleAddress = <deployed_contract_address>;
   PriceOracle priceOracle = PriceOracle(priceOracleAddress);
   uint256 price = priceOracle.getPrice(tokenAddress);
   ```

2. **Update Token Price:**
   ```solidity
   priceOracle.updatePrice(tokenAddress, newPrice);
   ```

3. **Add Liquidity:**
   ```solidity
   address liquidityPoolAddress = <deployed_contract_address>;
   LiquidityPool liquidityPool = LiquidityPool(liquidityPoolAddress);
   liquidityPool.addLiquidity(tokenA, tokenB, amountA, amountB);
   ```

## Conclusion

This project serves as a foundational decentralized exchange (DEX) platform with liquidity pools, LP token management, and price oracles. By leveraging OpenZeppelin's secure contract standards, the platform aims to offer a compliant, decentralized trading solution.

