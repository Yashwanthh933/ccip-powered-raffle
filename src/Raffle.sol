//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {IERCToken} from "src/interfaces/IERCToken.sol";

contract Raffle is ReentrancyGuard, VRFConsumerBaseV2Plus {
    //////////////////////////
    ///////  ERRORS   ///////
    //////////////////////////

    error Raffle_raffleNotOpened();
    error Raffle_EntranceFeeRequired(uint256 sent, uint256 required);
    error Raffle_TransactionFailed();
    error InSufficientBalance();
    error Raffle_NoRandomNumbersAvailable();
    error Raffle_UpkeepNotNeeded();
    error Raffle_RandomNumberNotReady();
    error Raffle_MaximumEntriesReached();

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /////////////////////////
    /// STATE VARIABLES  ////
    /////////////////////////

    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callBackGasLimit;
    uint16 private constant NUM_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 10;
    uint256 private constant MIN_RANDOM_RESERVE = 3; 

    uint256[] private s_randomNumberQueue;
    uint256 private s_queueIndex;
    
    // Random number for winner selection (separate from queue)
    uint256 private s_winnerRandomNumber;
    bool private s_winnerRandomReady;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;

    RaffleState private s_raffleState;
    mapping(uint256 => address) s_entryToPlayer;
    uint256 s_totalEntries;
    uint256 private s_maxPlayers = 100; //for now set to 100 later add controlled updation of maximum players
    mapping(address => uint256) s_numberOfTimesUserEntered;
    IERCToken private immutable i_ercToken;

    ////////////////////////
    /////// EVENTS /////////
    ////////////////////////

    event PlayerEntered(address indexed player, uint256 discount);
    event WinnerPicked(address indexed winner, uint256 timestamp);
    event TokensRedeemed(address indexed user, uint256 amount);
    event RandomNumbersRequested(uint256 requestId, bool forWinner);
    event RandomNumbersReceived(uint256 count);

    constructor(
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint256 _entranceFee,
        uint256 _interval,
        uint256 _subId,
        address _vrfCoordinator,
        address token
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_keyHash = _keyHash;
        i_callBackGasLimit = _callbackGasLimit;
        i_entranceFee = _entranceFee;
        i_interval = _interval;
        i_subscriptionId = _subId;
        i_ercToken = IERCToken(token);
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
        
        _requestRandomNumbersForDiscounts();
    }

    function enterRaffle() public payable nonReentrant {
        if (s_raffleState == RaffleState.CALCULATING)
            revert Raffle_raffleNotOpened();
        if (msg.value < i_entranceFee)
            revert Raffle_EntranceFeeRequired(msg.value, i_entranceFee);
        if(s_totalEntries >= s_maxPlayers) revert Raffle_MaximumEntriesReached();
        uint256 discountAmount =0;
        //  If user qualifies for discount, use pre-generated random number
        if (s_numberOfTimesUserEntered[msg.sender] >= 3) {
            
            uint256 discountRate = (s_randomNumberQueue[s_queueIndex] % 10) + 1;
            s_queueIndex++;
            discountAmount = (msg.value * discountRate) / 100;
            (bool success, ) = payable(msg.sender).call{value: discountAmount}("");
            if (!success) revert Raffle_TransactionFailed();
            if (s_randomNumberQueue.length - s_queueIndex < MIN_RANDOM_RESERVE) {
                _requestRandomNumbersForDiscounts();
            }
        }
        s_entryToPlayer[s_totalEntries] = msg.sender;
        s_totalEntries++;
        s_numberOfTimesUserEntered[msg.sender] += 1;
        emit PlayerEntered(msg.sender, discountAmount);
    }

    function checkUpkeep(
        bytes calldata /* */
    ) external view returns (bool upKeepNeeded, bytes memory/** */) {
        bool timePassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool hasPlayers = s_totalEntries > 0;
        bool isOpen = (s_raffleState == RaffleState.OPEN);
        bool hasBalance = address(this).balance > 0;

        upKeepNeeded = timePassed && hasPlayers && isOpen && hasBalance;
        return (upKeepNeeded,"");
    }

    function performUpKeep() external {
        // Verify conditions
        (bool upkeepNeeded, ) = this.checkUpkeep("");
        if (!upkeepNeeded) revert Raffle_UpkeepNotNeeded();

        s_raffleState = RaffleState.CALCULATING;
        s_winnerRandomReady = false;
        _requestRandomNumberForWinner();
    }

    function redeemTokens(uint256 amount) public nonReentrant {
        if (i_ercToken.balanceOf(msg.sender) < amount)
            revert InSufficientBalance();
        
        // Burn tokens first
        i_ercToken.burnFrom(msg.sender, amount);
        
        // Then send ETH
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert Raffle_TransactionFailed();
        
        emit TokensRedeemed(msg.sender, amount);
    }

    //Request random numbers for discount queue
    function _requestRandomNumbersForDiscounts() internal {
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: NUM_CONFIRMATIONS,
                callbackGasLimit: i_callBackGasLimit,
                numWords: NUM_WORDS, // Request 10 numbers
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RandomNumbersRequested(requestId, false);
    }

    // Request single random number for winner
    function _requestRandomNumberForWinner() internal {
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: NUM_CONFIRMATIONS,
                callbackGasLimit: i_callBackGasLimit,
                numWords: 1,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RandomNumbersRequested(requestId, true);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] calldata randomWords
    ) internal override {
        // Determine if this is for winner selection or discount queue
        if (s_raffleState == RaffleState.CALCULATING && !s_winnerRandomReady) {
            s_winnerRandomNumber = randomWords[0];
            s_winnerRandomReady = true;
            _selectWinner();
            emit RandomNumbersReceived(1);
        } else {
            for (uint256 i = 0; i < randomWords.length; i++) {
                s_randomNumberQueue.push(randomWords[i]);
            }
            emit RandomNumbersReceived(randomWords.length);
        }
    }

    //  Separate function to select winner (called after random number arrives)
    function _selectWinner() internal {
        if(s_winnerRandomReady) revert Raffle_RandomNumberNotReady();
        
        uint256 winnerIndex = s_winnerRandomNumber % s_totalEntries;
        address winner = s_entryToPlayer[winnerIndex];
        s_recentWinner = winner;
        
        uint256 winnerPrize = address(this).balance;
        
        // Reset state
        s_totalEntries = 0;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
        s_winnerRandomReady = false;
        emit WinnerPicked(winner, block.timestamp);
        // Mint tokens to winner (ETH stays in contract for redemption)
        i_ercToken.mint(winner, winnerPrize);
        
        
    }

    ////////////////////////
    /// GETTER FUNCTIONS ///
    ////////////////////////

    function getFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getInterval() external view returns (uint256) {
        return i_interval;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }
    
    function getAvailableRandomNumbers() external view returns (uint256) {
        return s_randomNumberQueue.length - s_queueIndex;
    }
    
    function getPlayerCount() external view returns (uint256) {
        return s_totalEntries;
    }
    
    function getUserEntryCount(address user) external view returns (uint256) {
        return s_numberOfTimesUserEntered[user];
    }
}
