//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
import{BurnFromMintTokenPool} from "@ccip/contracts/src/v0.8/ccip/pools/BurnFromMintTokenPool.sol";
import{IBurnMintERC20} from "@ccip/contracts/src/v0.8/shared/token/ERC20/IBurnMintERC20.sol";
contract ERCTokenPool is BurnFromMintTokenPool
{
    constructor(address token,address[] memory allowList, address rmnProxy,address router) BurnFromMintTokenPool(IBurnMintERC20(token),18,allowList,rmnProxy,router)
    {

    }

}