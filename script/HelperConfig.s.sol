// SPDX_License-Identifier: MIT

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

pragma solidity ^0.8.19;

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address LINKToken;
        uint256 deployerKey;
    }

    NetworkConfig public activeNetwork;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetwork = getSepoilaEthConfig();
        } else {
            activeNetwork = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoilaEthConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30, // Seconds
                vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625, // For Sepoila Testnet @ https://docs.chain.link/vrf/v2/subscription/supported-networks
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // AKA Key Hash
                subscriptionId: 10043, // Gotten @ https://vrf.chain.link/ after I created a Subscription @ https://docs.chain.link/vrf/v2/subscription/examples/get-a-random-number
                callbackGasLimit: 500000, // 500,000 gas.
                LINKToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789, // For Sepoila Testnet @ https://docs.chain.link/resources/link-token-contracts#ethereum-mainnet
                deployerKey: vm.envUint("SEPOLIA_PRIVATE_KEY")
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetwork.vrfCoordinator != address(0)) {
            return activeNetwork;
        }

        uint96 baseFee = 0.25 ether; // 0.25 LINK
        uint96 gasPriceLink = 1e9; // 1 ggwei LINK

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );

        // Creating a new instance of the mock LinkToken contract
        //so we can have a LinkToken address for our Anvil chain.

        LinkToken link = new LinkToken();

        vm.stopBroadcast();

        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30, // Seconds
                vrfCoordinator: address(vrfCoordinatorMock), // For Anvil Chain
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // AKA Key Hash
                subscriptionId: 0, // Will reset to mine
                callbackGasLimit: 500000, // 500,000 gas.
                LINKToken: address(link),
                deployerKey: vm.envUint("ANVIL_PRIVATE_KEY")
            });
    }
}
