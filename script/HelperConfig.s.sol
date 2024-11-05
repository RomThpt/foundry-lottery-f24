//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    uint256 public constant ENTRANCE_FEE = 0.01 ether;
    uint256 public constant INTERVAL = 30;
    bytes32 public constant KEY_HASH = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint256 public constant SUBSCRIPTION_ID = 8119;
    uint32 public constant CALLBACK_GAS_LIMIT = 200000;
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    /**
     * VRF Mock Values
     */
    uint96 public constant BASE_FEE = 0.25 ether;
    uint96 public constant GAS_PRICE = 1e9;
    int256 public constant WEI_PER_UNIT_LINK = 4e15;
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__ChainIdNotSupported(uint256 chainId);

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 subscriptionId;
        uint32 callBackGasLimit;
    }

    NetworkConfig public activeNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory config) {
        config = NetworkConfig({
            entranceFee: ENTRANCE_FEE,
            interval: INTERVAL,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B, //vrf coordinator address
            keyHash: KEY_HASH,
            subscriptionId: SUBSCRIPTION_ID,
            callBackGasLimit: CALLBACK_GAS_LIMIT
        });
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory config) {
        config = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, //30 seconds
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B, //vrf coordinator address
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 8119,
            callBackGasLimit: 200000
        });
    }

    function getAnvilConfig() public returns (NetworkConfig memory config) {
        if (networkConfigs[LOCAL_CHAIN_ID].vrfCoordinator != address(0)) {
            return networkConfigs[LOCAL_CHAIN_ID];
        }
        // Deploy mocks
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(BASE_FEE, GAS_PRICE, WEI_PER_UNIT_LINK);
        config = NetworkConfig({
            entranceFee: ENTRANCE_FEE,
            interval: INTERVAL,
            vrfCoordinator: address(vrfCoordinatorMock),
            keyHash: KEY_HASH, //doesnt matter
            subscriptionId: SUBSCRIPTION_ID,
            callBackGasLimit: CALLBACK_GAS_LIMIT //doenst matter
        });
        vm.stopBroadcast();
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getAnvilConfig();
        } else {
            revert HelperConfig__ChainIdNotSupported(chainId);
        }
    }
}
