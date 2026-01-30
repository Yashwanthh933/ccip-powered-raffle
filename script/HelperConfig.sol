//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
import{VRFCoordinatorV2_5Mock} from "@ccip/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import{LinkToken} from "../test/mocks/LinkToken.sol";
contract HelperConfig
{
    error UnSupportedChain();
    uint256 constant SEPOLIA_CHAINID =11155111 ;
    uint256 constant ARBITRUM_SEPOLIA_CHAINID = 421614;
    uint256 constant POLYGON_AMOY_CHAINID =80002;
    uint256 constant AVALANCHI_FUZI_CHAINID = 43113;
    uint256 constant ANVIL_CHAINID = 31337;

    //vrf mock values
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 MOCK_GAS_PRICE= 1e9;
    int256 MOCK_WEI_PER_UNIT_LINK = 4e15;

    struct NetworkConfig
    {
        bytes32 keyHash; // gas lane 
        uint32 callBackGasLimit; 
        uint256 entranceFee;
        uint256 interval;
        uint256 subscriptionId;
        address vrfCoordinator;
        address link;
    }

    mapping(uint256=> NetworkConfig) public activeNetworkConfig;
    constructor()
    {
        if(block.chainid ==SEPOLIA_CHAINID)
        {
            activeNetworkConfig[SEPOLIA_CHAINID] = getSepoliaConfig();

        }
        else if(block.chainid == ARBITRUM_SEPOLIA_CHAINID)
        {
            activeNetworkConfig[ARBITRUM_SEPOLIA_CHAINID] = getArbitrumConfig();

        }
        else if (block.chainid == POLYGON_AMOY_CHAINID)
        {
            activeNetworkConfig[POLYGON_AMOY_CHAINID] = getPolygonAmoyConfig();

        }
        else if(block.chainid == AVALANCHI_FUZI_CHAINID)
        {
            activeNetworkConfig[AVALANCHI_FUZI_CHAINID] = getAvalanchiConfig();

        }
        else if (block.chainid == ANVIL_CHAINID){
            activeNetworkConfig[ANVIL_CHAINID] = getOrCreateAnvilConfig();
        }
        else 
        {
            revert UnSupportedChain();
        }
    }

    function getSepoliaConfig() internal pure returns(NetworkConfig memory networkConfig)
    {
        networkConfig = NetworkConfig({
            keyHash:0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callBackGasLimit:500_000,
            entranceFee:0.1 ether,
            interval:7 days,
            subscriptionId:0,
            vrfCoordinator:0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            link:0x779877A7B0D9E8603169DdbD7836e478b4624789
        });

    }
    function getArbitrumConfig() internal pure returns(NetworkConfig memory networkConfig){
        networkConfig = NetworkConfig({
            keyHash:0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be,
            callBackGasLimit:500_000,
            entranceFee:0.1 ether,
            interval:7 days,
            subscriptionId:0,
            vrfCoordinator:0x5CE8D5A2BC84beb22a398CCA51996F7930313D61,
            link:0xb1D4538B4571d411F07960EF2838Ce337FE1E80E
        });
    }
    function getPolygonAmoyConfig() internal pure returns(NetworkConfig memory networkConfig)
    {
        networkConfig = NetworkConfig({
            keyHash:0x816bedba8a50b294e5cbd47842baf240c2385f2eaf719edbd4f250a137a8c899,
            callBackGasLimit:500_000,
            entranceFee:0.1 ether,
            interval:7 days,
            subscriptionId:0,
            vrfCoordinator:0x343300b5d84D444B2ADc9116FEF1bED02BE49Cf2,
            link:0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904
        });
    }
    function getAvalanchiConfig() internal pure returns(NetworkConfig memory networkConfig)
    {
        networkConfig = NetworkConfig({
            keyHash:0xc799bd1e3bd4d1a41cd4968997a4e03dfd2a3c7c04b695881138580163f42887,
            callBackGasLimit:500_000,
            entranceFee:0.1 ether,
            interval:7 days,
            subscriptionId:0,
            vrfCoordinator:0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE,
            link:0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846
        });

    }
    function getOrCreateAnvilConfig() internal returns(NetworkConfig memory networkConfig)
    {
        //mock coordinator
        VRFCoordinatorV2_5Mock mockCoordinator =  new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE,MOCK_GAS_PRICE,MOCK_WEI_PER_UNIT_LINK);
        //mock token
        LinkToken link = new LinkToken();
        networkConfig = NetworkConfig({
            keyHash:bytes32(0),
            callBackGasLimit:0,
            entranceFee:0.1 ether,
            interval:7 days,
            subscriptionId:0,
            vrfCoordinator:address(mockCoordinator),
            link:address(link)
        });
    }

    function getConfigByChainId(uint256 chainId) public view returns(NetworkConfig memory config)
    {
        config = activeNetworkConfig[chainId];
        return config;
    }
}