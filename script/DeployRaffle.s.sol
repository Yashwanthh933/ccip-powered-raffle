//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import{IERCToken} from "../src/interfaces/IERCToken.sol";
import{Raffle} from "../src/Raffle.sol";
import{HelperConfig} from "script/HelperConfig.sol";
import{CreateSubscription,FundSubscription,AddConsumer} from "script/Interactions.s.sol";

contract DeployRaffle is Script
{
    function run( address tokenAddress) public returns(Raffle raffle)
    {
        // get all the reqired details from the helperConfig
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfigByChainId(block.chainid);

        // initially subscription id is 0 we have to create the subscription 
        // better to check whether subscriptionId is 0 r not 
        if(networkConfig.subscriptionId == 0)
        {
            CreateSubscription createSubscription = new CreateSubscription();
            (uint256 subscriptionId,) = createSubscription.createSubscription(networkConfig.vrfCoordinator);
            networkConfig.subscriptionId = subscriptionId;
        }

        // now we have fund the subscription
        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(networkConfig.vrfCoordinator,networkConfig.subscriptionId,networkConfig.link);



        // now deploy the raffle contract
        vm.startBroadcast();
        raffle = new Raffle(networkConfig.keyHash,
        networkConfig.callBackGasLimit,
        networkConfig.entranceFee,
        networkConfig.interval,
        networkConfig.subscriptionId,
        networkConfig.vrfCoordinator,
        tokenAddress
        );
        IERCToken(tokenAddress).grantMintAndBurnRole(address(raffle));
        vm.stopBroadcast();

        // now add the consumer
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle),networkConfig.vrfCoordinator,networkConfig.subscriptionId);

    }
}