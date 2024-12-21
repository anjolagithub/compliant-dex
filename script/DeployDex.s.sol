// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {KYCRegistry} from "../src/KYCRegistry.sol";
import {PriceOracle} from "../src/PriceOracle.sol";
import {LPToken} from "../src/LPToken.sol";
import {LiquidityPool} from "../src/LiquidityPool.sol";
import {CompliantDEX} from "../src/CompliantDEX.sol";

contract DeploymentManager {
    KYCRegistry public kycRegistry;
    PriceOracle public priceOracle;
    LPToken public lpToken;
    LiquidityPool public liquidityPool;
    CompliantDEX public compliantDEX;

    constructor(address initialOwner) {
        // Deploy necessary contracts
        kycRegistry = new KYCRegistry(initialOwner);
        priceOracle = new PriceOracle(initialOwner);
        lpToken = new LPToken(initialOwner);

        // Deploy LiquidityPool with dependencies
        liquidityPool = new LiquidityPool(address(priceOracle), address(lpToken), initialOwner);

        // Deploy CompliantDEX with KYC, LiquidityPool, and PriceOracle
        compliantDEX = new CompliantDEX(
            address(kycRegistry),
            address(liquidityPool),
            address(priceOracle),
            initialOwner
        );
    }
}
