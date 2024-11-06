//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {CreateSubscription} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {}

    function deployContractRaffle() public returns (Raffle, HelperConfig.NetworkConfig memory) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 keyHash,
            uint256 subscriptionId,
            uint32 callBackGasLimit
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinator);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(entranceFee, interval, vrfCoordinator, keyHash, subscriptionId, callBackGasLimit);
        vm.stopBroadcast();

        return (
            raffle,
            HelperConfig.NetworkConfig(entranceFee, interval, vrfCoordinator, keyHash, subscriptionId, callBackGasLimit)
        );
    }
}
