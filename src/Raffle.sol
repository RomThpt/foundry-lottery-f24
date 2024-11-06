// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
/**
 * @title Raffle
 * @author RomThpt
 * @notice This contract is a raffle contract
 * @dev Implements chainlink VRFv2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {
    // Errors
    error Raffle__NotEnoughFundsSendedToEnterRaffle();
    error Raffle__NotEnoughTimePassed();
    error Raffle__TransferFailed();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 state, uint256 playersLength);

    //Type declarations
    enum RaffleState {
        OPEN, //0
        CALCULATING //1

    }

    // Constants
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callBackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Events
    event PlayerEntered(address indexed player, uint256 indexed amount, uint256 totalPlayedAmount);
    event WinnerPicked(address indexed winner);

    // State variables
    address[] private s_players;
    uint256 private s_totalPlayedAmount;
    uint256 private s_lastTimestamp;
    address[] private s_winners;
    RaffleState private s_raffleState;

    // Constructor
    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint256 _subscriptionId,
        uint32 _callBackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entranceFee = _entranceFee;
        i_interval = _interval;
        s_lastTimestamp = block.timestamp;
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_callBackGasLimit = _callBackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    // Functions

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughFundsSendedToEnterRaffle();
        }
        if (s_raffleState == RaffleState.CALCULATING) {
            revert Raffle__NotEnoughTimePassed();
        }
        s_players.push(msg.sender);
        s_totalPlayedAmount += msg.value;
        emit PlayerEntered(msg.sender, msg.value, s_totalPlayedAmount);
    }

    function checkUpkeep(bytes memory /* checkData */ ) public view returns (bool upkeepNeeded, bytes memory) {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = (block.timestamp - s_lastTimestamp) > i_interval;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0"); // can we comment this out?
    }

    function performUpkeep(bytes calldata /*calldata*/ ) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, uint256(s_raffleState), s_players.length);
        }
        s_raffleState = RaffleState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory req = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash, //gas price
            subId: i_subscriptionId, //subscription chainlink
            requestConfirmations: REQUEST_CONFIRMATIONS, //numbers of confirmations
            callbackGasLimit: i_callBackGasLimit, // gas limit
            numWords: NUM_WORDS, // numbers of random numbers
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(req);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 indexWinder = randomWords[0] % s_players.length;
        address recentWinner = s_players[indexWinder];
        s_winners.push(recentWinner);

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;

        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /* Getters */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getKeyHash() public view returns (bytes32) {
        return i_keyHash;
    }

    function getSubscriptionId() public view returns (uint256) {
        return i_subscriptionId;
    }

    function getCallBackGasLimit() public view returns (uint32) {
        return i_callBackGasLimit;
    }

    function getPlayers() public view returns (address[] memory) {
        return s_players;
    }

    function getTotalPlayedAmount() public view returns (uint256) {
        return s_totalPlayedAmount;
    }

    function getLastTimestamp() public view returns (uint256) {
        return s_lastTimestamp;
    }

    function getWinners() public view returns (address[] memory) {
        return s_winners;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }
}
