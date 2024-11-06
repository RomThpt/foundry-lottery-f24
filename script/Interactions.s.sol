// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract CreateSubscription is Script {
    HelperConfig public helperConfig;

    function createSubscriptionUsingConfig() public returns (uint64) {
        helperConfig = new HelperConfig();
        (,, address vrfCoordinator,,,) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(address _vrfCoordinator) public returns (uint64) {
        console.log("Creating subscription on chain id", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(_vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your sub Id :", subId);
        console.log("Please update subscription in HelperConfig !");
        return subId;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}
