// SPDX_License-Identifier: MIT

import {Script, console} from "lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Raffle} from "src/Raffle.sol";



pragma solidity ^0.8.19;

contract CreateSubscription is Script {
    function CreateSubscriptionUsingConfig() public returns(uint64) {
        HelperConfig helperConfig = new HelperConfig();
        ( , , address vrfCoordinator, , , , , uint256 deployerKey) = helperConfig.activeNetwork();
        return createSubscription(vrfCoordinator, deployerKey);
    }

    function createSubscription(address vrfCoordinator, uint256 deployerKey) public returns(uint64) {
        console.log("Creating subscription on ", block.chainid);
        vm.startBroadcast(deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subID is: ", subId);
        console.log("Please update subscriptionId in HelperConfig.s.sol");
        return subId;
    }
    function run() external returns (uint64) {
        return CreateSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function FundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint64 subscriptionId,
            ,
            address LINKToken,
            uint256 deployerKey
        ) = helperConfig.activeNetwork();
        fundSubscription(vrfCoordinator, subscriptionId, LINKToken, deployerKey);
    }

    function fundSubscription(address vrfCoordinator, uint64 subscriptionId, address LINKToken, uint256 deployerKey) public {
        console.log("Funding Subscription: ", subscriptionId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On Chain ID: ", block.chainid);
        if (block.chainid == 31337) {  // That is, if we're on a local chain.
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerKey);
            LinkToken(LINKToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();

        }

    }

    function run() external {
        FundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {

    function addConsumer(address raffle, address vrfCoordinator, uint64 subscriptionId, uint256 deployerKey) public {
        console.log("Adding consumer contract: ", raffle);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On Chain ID: ", block.chainid);
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subscriptionId, raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        ( , , address vrfCoordinator, , uint64 subscriptionId, , , uint256 deployerKey) = helperConfig.activeNetwork();
        addConsumer(raffle, vrfCoordinator, subscriptionId, deployerKey);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffle);
    }
}




