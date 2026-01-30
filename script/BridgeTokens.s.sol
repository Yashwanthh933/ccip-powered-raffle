//SPDX-License-Identifier:MIT
pragma solidity^0.8.19;
import{Script} from "forge-std/Script.sol";
import {IRouterClient} from "@ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import{IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/interfaces/IERC20.sol";
contract BridgeTokens is Script
{
    function run(uint256 amountToBridge,address localToken,address router,uint64 chainSelector,address receiver,address feeTokenAddress) public{
        Client.EVMTokenAmount[] memory tokenAmount = new Client.EVMTokenAmount[](1);
        tokenAmount[0] = Client.EVMTokenAmount({
            token:localToken,
            amount:amountToBridge
        });
        Client.EVMExtraArgsV2 memory extraArgs = Client.EVMExtraArgsV2({
            gasLimit:200_000,
            allowOutOfOrderExecution:false
        });
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver:abi.encode(receiver),
            data:"",
            tokenAmounts:tokenAmount,
            feeToken:feeTokenAddress,
            extraArgs:Client._argsToBytes(extraArgs)
        });
        uint256 fee = IRouterClient(router).getFee(chainSelector, message);
        IERC20(localToken).approve(router, amountToBridge);
        IERC20(feeTokenAddress).approve(router, fee);
        IRouterClient(router).ccipSend(chainSelector,message);
    }
}