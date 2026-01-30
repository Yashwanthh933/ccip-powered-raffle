//SPX-License-Identifier:MIT
pragma solidity^0.8.19;
import{Script} from "forge-std/Script.sol";
import{ERCToken} from "../src/ERCToken.sol";
import{ERCTokenPool} from "../src/ERCTokenPool.sol";
import{RegistryModuleOwnerCustom} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import{TokenAdminRegistry} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import{CCIPHelperConfig} from "script/CCIPHelperConfig.sol";
import{IBurnMintERC20} from "@ccip/contracts/src/v0.8/shared/token/ERC20/IBurnMintERC20.sol";

contract DeployTokenAndPool is Script
{
    function run() public returns(ERCToken,ERCTokenPool){

        CCIPHelperConfig.NetworkDetails memory networkDetails = CCIPHelperConfig.getNetworkDetails(block.chainid);

        vm.startBroadcast();

        ERCToken token = new ERCToken();
        ERCTokenPool tokenPool = new ERCTokenPool(address(token),new address[](0),networkDetails.rmnProxyAddress,networkDetails.routerAddress);
        RegistryModuleOwnerCustom(networkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(address(token));
        TokenAdminRegistry(networkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(token));
        TokenAdminRegistry(networkDetails.tokenAdminRegistryAddress).setPool(address(token),address(tokenPool));
        vm.stopBroadcast();
        return (token,tokenPool);
    }

}