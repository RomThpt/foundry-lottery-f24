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

    // Constants
    uint256 private immutable i_entranceFee = 1 ether;
    uint256 private immutable i_interval = 1 days;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId = 0.1 ether;
    uint32 private immutable i_callBackGasLimit = 20000;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Events
    event Raffle__PlayerEntered(address indexed player, uint256 indexed amount, uint256 totalPlayedAmount);

    // State variables
    mapping(address players => uint256 amountPlayed) private s_playersToAmountPlayed;
    uint256 private s_playersCount;
    uint256 private s_totalPlayedAmount;
    uint256 private s_lastTimestamp;

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
    }
    // Functions

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughFundsSendedToEnterRaffle();
        }
        s_playersToAmountPlayed[msg.sender] += msg.value;
        s_playersCount++;
        s_totalPlayedAmount += msg.value;
        emit Raffle__PlayerEntered(msg.sender, msg.value, s_totalPlayedAmount);
    }

    function pickWinner() public {
        if ((block.timestamp - s_lastTimestamp) < i_interval) {
            revert Raffle__NotEnoughTimePassed();
        }
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
        // uint256 winnerIndex = randomWords[0] % s_playersCount;
        // address winner = s_playersToAmountPlayed.keys[winnerIndex];
        // payable(winner).transfer(s_totalPlayedAmount);
    }

    /* Getters */
    function getEntranceFee() public pure returns (uint256) {
        return i_entranceFee;
    }
}
