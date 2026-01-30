//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
import {Test} from "forge-std/Test.sol";
import{Raffle} from "../src/Raffle.sol";
import{HelperConfig} from "../script/HelperConfig.sol";
import{DeployRaffle} from "../script/DeployRaffle.s.sol";
import{ERCToken} from "../src/ERCToken.sol";
import{ERCTokenPool} from "../src/ERCTokenPool.sol";
import{CCIPLocalSimulatorFork} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import{Register} from "@chainlink/local/src/ccip/Register.sol";
import{ConfigurePool} from "../script/ConfigurePool.s.sol";
import {IRouterClient} from "@ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import{RegistryModuleOwnerCustom} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import{TokenAdminRegistry} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import{IERCToken} from "../src/interfaces/IERCToken.sol";
import {TokenPool} from "@ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "@ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
import {Client} from "@ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import{IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/interfaces/IERC20.sol";

contract testRaffle is Test{

    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    DeployRaffle private deployer;
    
    ERCToken private sepoliaToken;
    ERCToken private arbitrumToken;

    ERCTokenPool private sepoliaTokenPool;
    ERCTokenPool private arbitrumTokenPool;

    Raffle private raffle;

    CCIPLocalSimulatorFork private ccipLocalSimulator;

    Register.NetworkDetails sepoliaNetworkDetails;
    Register.NetworkDetails arbitrumNetworkDetails;

    uint256 private sepoliaFork;
    uint256  private arbitrumFork;

    string private SEPOLIA_RPC_URL =vm.envString("SEPOLIA_RPC_URL");
    string  private ARBITRUM_RPC_URL = vm.envString("ARBITRUM_SEPOLIA_RPC_URL");

    function setUp() public{
        sepoliaFork = vm.createFork(SEPOLIA_RPC_URL);
        arbitrumFork = vm.createFork(ARBITRUM_RPC_URL);
        vm.startPrank(owner);
        vm.selectFork(sepoliaFork);
        ccipLocalSimulator = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulator));
        sepoliaNetworkDetails = ccipLocalSimulator.getNetworkDetails(block.chainid);
        sepoliaToken = new ERCToken();
        sepoliaTokenPool = new ERCTokenPool(address(sepoliaToken),new address[](0),sepoliaNetworkDetails.rmnProxyAddress,sepoliaNetworkDetails.routerAddress);
        IERCToken(address(sepoliaToken)).grantMintAndBurnRole(address(sepoliaTokenPool));
        RegistryModuleOwnerCustom(sepoliaNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(address(sepoliaToken));
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(sepoliaToken));
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).setPool(address(sepoliaToken),address(sepoliaTokenPool));
        //raffle deployment
        deployer = new DeployRaffle();
        raffle = deployer.run(address(sepoliaToken));
        IERCToken(address(sepoliaToken)).grantMintAndBurnRole(address(raffle));

        // now deploy the token and tokenPool on destination chain

        vm.selectFork(arbitrumFork);
        arbitrumNetworkDetails = ccipLocalSimulator.getNetworkDetails(block.chainid);
        arbitrumToken = new ERCToken();
        arbitrumTokenPool = new ERCTokenPool(address(arbitrumToken),new address[](0),arbitrumNetworkDetails.rmnProxyAddress,arbitrumNetworkDetails.routerAddress);

        RegistryModuleOwnerCustom(arbitrumNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(address(arbitrumToken));
        TokenAdminRegistry(arbitrumNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(arbitrumToken));
        TokenAdminRegistry(arbitrumNetworkDetails.tokenAdminRegistryAddress).setPool(address(arbitrumToken),address(arbitrumTokenPool));
        vm.stopPrank();
        // now configure token pools on both chains (sepolia and arbitrum)
        configurePool(sepoliaFork,address(sepoliaTokenPool),address(arbitrumTokenPool),arbitrumNetworkDetails.chainSelector,address(arbitrumToken));
        vm.selectFork(arbitrumFork);
        configurePool(arbitrumFork,address(arbitrumTokenPool),address(sepoliaTokenPool),sepoliaNetworkDetails.chainSelector,address(sepoliaToken));

    }
    function configurePool(uint256 fork,address localPool,address remotePool,uint64 remoteChainSelector,address remoteToken) internal 
    {
        bytes[] memory remotePoolAddresses = new bytes[](1);
        remotePoolAddresses[0] = abi.encode(remotePool);
        TokenPool.ChainUpdate[] memory chainUpdates = new TokenPool.ChainUpdate[](1);
        chainUpdates[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteChainSelector,
            remotePoolAddresses: remotePoolAddresses,
            remoteTokenAddress: abi.encode(remoteToken),
            outboundRateLimiterConfig:RateLimiter.Config({
                isEnabled:false,
                capacity:0,
                rate:0
            }),
            inboundRateLimiterConfig:RateLimiter.Config({
                isEnabled:false,
                capacity:0,
                rate:0
            }) 
        });
        vm.selectFork(fork);
        vm.prank(owner);
        TokenPool(localPool).applyChainUpdates(new uint64[](0), chainUpdates);
    }
    function bridgeTokens(
        uint256 amountToBridge,
        uint256 localFork,
        uint256 remoteFork,
        address localToken,
        address remoteToken,
        Register.NetworkDetails memory localNetworkDetails,
        Register.NetworkDetails memory remoteNetworkDetails
    ) public
    {
        vm.selectFork(localFork);
        Client.EVMTokenAmount[] memory evmTokenAmount = new Client.EVMTokenAmount[](1);
        evmTokenAmount[0] = Client.EVMTokenAmount({
            token:address(localToken),
            amount:amountToBridge
        });
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver:abi.encode(user1),
            data:"",
            tokenAmounts:evmTokenAmount,
            feeToken:localNetworkDetails.linkAddress,
            extraArgs:Client._argsToBytes(Client.EVMExtraArgsV2({gasLimit:500_000,allowOutOfOrderExecution:false}))
        });
        uint256 fee = IRouterClient(localNetworkDetails.routerAddress).getFee(remoteNetworkDetails.chainSelector,message);
        ccipLocalSimulator.requestLinkFromFaucet(user1, fee);
        vm.prank(user1);
        IERC20(localNetworkDetails.linkAddress).approve(localNetworkDetails.routerAddress,fee);
        vm.prank(user1);
        IERC20(address(localToken)).approve(localNetworkDetails.routerAddress,amountToBridge);
        uint256 localBalanceBefore = IERCToken(localToken).balanceOf(user1);
        vm.prank(user1);
        IRouterClient(localNetworkDetails.routerAddress).ccipSend(remoteNetworkDetails.chainSelector,message);
        uint256 localBalanceAfter = IERCToken(localToken).balanceOf(user1);
        vm.assertEq(localBalanceAfter,localBalanceBefore - amountToBridge);
        vm.selectFork(remoteFork);
        vm.warp(block.timestamp + 20 minutes);
        uint256 remoteBalanceBefore = IERCToken(remoteToken).balanceOf(user1);
        vm.selectFork(localFork);
        ccipLocalSimulator.switchChainAndRouteMessage(remoteFork);
        vm.assertEq(IERCToken(remoteToken).balanceOf(user1),remoteBalanceBefore+amountToBridge);
    }

    function testRaffleIsOpen() public
    {
        vm.assertEq(uint(raffle.getRaffleState()),uint(Raffle.RaffleState.OPEN));
    }
}