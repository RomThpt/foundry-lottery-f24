// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployRaffle is Script {
    Raffle public raffle;

    function run() public {}
    function deployContractRaffle() public returns (Raffle, HelperConfig) {}
}
