//SPDX-License-Identifier:MIT
pragma solidity^0.8.19;
import{Script,console} from "forge-std/Script.sol";
import{VRFCoordinatorV2_5Mock} from "@ccip/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import{LinkToken} from "../test/mocks/LinkToken.sol";
contract CreateSubscription is Script
{
    function createSubscription(address vrfCoordinator)public returns(uint256,address )
    {
        console.log("CREATING THE SUBSCRIPTION ON",block.chainid);
        console.log("VRF COORDINATOR",vrfCoordinator);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        console.log("SUBSCRIPTION ID:",subId);
        return (subId,vrfCoordinator);
    }

}

contract FundSubscription is Script{

    error InSufficientLinkBalance();
    uint256 private constant FUND_AMOUNT = 30 ether; // 30 link
    function fundSubscription(address vrfCoordinator,uint256 subscriptionId,address linkToken) public
    {
        console.log("FUNDING THE SUBSCRIPTION ID:",subscriptionId);
        console.log("ON CHAINID:",block.chainid);
        if(block.chainid ==31337)
        {
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId,FUND_AMOUNT);
            console.log("AMONT FUNDED TO THE MOCK");
        }
        else
        {
            uint256 balance = LinkToken(linkToken).balanceOf(msg.sender);
            if(balance < FUND_AMOUNT)
            {
                revert InSufficientLinkBalance();
            }
            LinkToken(linkToken).transferAndCall(vrfCoordinator,FUND_AMOUNT,abi.encode(subscriptionId));
        }
    }

}

contract AddConsumer is Script{
    function addConsumer(address mostRecentlyDeployed,address vrfCoordinator,uint256 subscriptionId) public{
        console.log("Adding consumer contract:",mostRecentlyDeployed);
        console.log("To VRFCoordinator:",vrfCoordinator);
        console.log("On ChainID:",block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subscriptionId,mostRecentlyDeployed);
        vm.stopBroadcast();
    }

}
