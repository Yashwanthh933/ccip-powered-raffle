//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
import{Script} from "forge-std/Script.sol";
import {TokenPool} from "@ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "@ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";

contract ConfigurePool is Script
{
    function run(
        address localPool,
        address remotePool,
        address remoteToken,
        uint64 remoteChainSelector,
        bool outboundRateIsEnabled,
        uint128 outboundRateCapacity,
        uint128 outboundrateLimiterRate,
        bool inboundRateIsEnabled,
        uint128 inboundRateCapacity,
        uint128 inboundrateLimiterRate) public{
            vm.startBroadcast();
            TokenPool.ChainUpdate[] memory chainUpdate = new TokenPool.ChainUpdate[](1);
            bytes[] memory poolAddresses = new bytes[](1);
            poolAddresses[0] = abi.encode(remotePool);
            chainUpdate[0] = TokenPool.ChainUpdate({
                remoteChainSelector:remoteChainSelector,
                remotePoolAddresses:poolAddresses,
                remoteTokenAddress:abi.encode(remoteToken),
                outboundRateLimiterConfig:RateLimiter.Config({
                isEnabled:outboundRateIsEnabled,
                capacity:outboundRateCapacity,
                rate:outboundrateLimiterRate
                }),
                inboundRateLimiterConfig:RateLimiter.Config({
                isEnabled:inboundRateIsEnabled,
                capacity:inboundRateCapacity,
                rate:inboundrateLimiterRate
                })
            });
            TokenPool(localPool).applyChainUpdates(new uint64[](0),chainUpdate);
            vm.stopBroadcast();
            }
}