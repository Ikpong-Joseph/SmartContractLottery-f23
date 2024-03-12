// SPDX_License-Identifier: MIT

import {Test} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

pragma solidity ^0.8.19;

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address LINKToken;
    uint256 deployerKey;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 10 ether;

    /**
     * Events
     */
    event EnteredRaffle(address indexed player);

    modifier RaffleEnteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRafflle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        _;
    }

    modifier skipfork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            LINKToken,

        ) = helperConfig.activeNetwork();

        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function testRaffleStateIsInitialized() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /////////////////////////////
    /// Enter Raffle ///////////
    /////////////////////////////

    function testEnterRaffleRevertsWhenPlayerTriesToEnterWithoutEnoughETH()
        public
    {
        //Arrange //Act // Assert

        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughETHSent.selector);
        raffle.enterRafflle();
    }

    // Create getter function to return addreeess from palyerssssssssss[[[]]] basssssssssssssed on indexOfPlayer

    // testPlayersEnteringRaffleIsRecorded
    function testPlayersEnteringRaffleIsRecorded() public {
        vm.prank(PLAYER);
        raffle.enterRafflle{value: entranceFee}();
        address rafflePlayer = raffle.getPlayers(0);

        assert(PLAYER == rafflePlayer);
    }

    function testEventEmitsWhenPlayerEntersRaffle() public {
        vm.prank(PLAYER);

        /**
        *@dev   The following is used to test that an event emits as it should.
        *       vm.expectEmit(bool checkTopic1, bool checkTopic2,bool checkTopic3, bool checkData, address emitter)
        *       checkTopic1 are **indexed** params. true if present.
        *       address emitter is most likely the emitting contract address.
        *       When i tried vm.expectEmit(true, false, false, false, PLAYER), test failed.
        *       But passed as seen below.
        *       Like a vm.expectRevert, the total setting to simulate an emitting event is
                    1. vm.expectEmit(true, false, false, false, address(raffle)) --- if an emitting address is present
                    2. emit EnteredRaffle(PLAYER) --- emit the event as it would in the contract
                        In this case -- EnteredRaffle(address indexed player)
                    3. Then call the function that'll emit the event.
        */

        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRafflle{value: entranceFee}();
    }

    function testPlayerCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRafflle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRafflle{value: entranceFee}();
    }

    /////////////////////////////
    /// CheckUpkeep Tests ///////
    /////////////////////////////

    function testCheckUpkeepFailsWithoutBalance() public {
        //Arrange
        //Make sure enough time has passed
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act
        (bool UpKeepNeeded, ) = raffle.checkUpkeep("");

        // assertEq(UpKeepNeeded, false); //Same as below.
        assert(!UpKeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsNotOpen() public {
        vm.prank(PLAYER);
        raffle.enterRafflle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        (bool UpKeepNeeded, ) = raffle.checkUpkeep("");

        /**
         * UpKeepNeeded returns false for 2 reasons
         *   1. raffle.checkUpkeep is usually called before performUpkeep
         *   2. raffle.checkUpkeep requires 4 conditions to return true,
         *       one of which is RaffleState.OPEN.
         *       performUpkeep changes state from RaffleState.OPEN to RaffleState.CALCULATING.
         *       Thus UpKeepNeeded returns false.
         */

        assert(UpKeepNeeded == false);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasNotPassed() public {
        vm.prank(PLAYER);
        raffle.enterRafflle{value: entranceFee}();

        vm.roll(block.number + 1);

        (bool UpKeepNeeded, ) = raffle.checkUpkeep("");
        assert(UpKeepNeeded == false);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
        vm.prank(PLAYER);
        raffle.enterRafflle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool UpKeepNeeded, ) = raffle.checkUpkeep("");
        assert(UpKeepNeeded == true);
    }

    /////////////////////////////
    /// PerformUpkeep Tests /////
    /////////////////////////////

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRafflle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act/Assert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRafflle{value: entranceFee}();

        uint256 currentBalance = address(raffle).balance;
        uint256 numberOfPlayers = 1;
        uint256 raffleState = uint256(raffle.getRaffleState());

        // vm.warp(block.timestamp + interval + 1);
        // vm.roll(block.number + 1);

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numberOfPlayers,
                raffleState
            )
        );

        // In the logs (If `forge test --match-test testPerformUpkeepRevertsIfCheckUpkeepIsFalse -vvvvv` is run),
        // You'll notice a '0' when error emits.
        // This because enum is treated as an [], and OPEN is listed before CALCULATING
        // Hence 0. Enums are also explicitly convertible to uint256.

        //Act/Assert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        public
        RaffleEnteredAndTimePassed
    {
        vm.recordLogs(); // Records every emiting event
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs(); // All recorded logs are bytes32
        bytes32 requestId = entries[1].topics[1];
        // The event emitting in raffle.performUpkeep("") is the 2nd emitted event in that function
        // An event is emitted by the vrf contract called there in, and that takes entries[0]
        // Since we are interested in the emitted requestId from the event and not the whole event, topics[1]
        // If interested in whole event, topics[0]

        Raffle.RaffleState rState = raffle.getRaffleState();

        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1); // REMEMBER: raffle.performUpkeep("") changes Raffle state to CALCULATING, which is at index 1.
    }

    /////////////////////////////////////
    /// Fulfill Random Words Tests /////
    ///////////////////////////////////

    function testRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public RaffleEnteredAndTimePassed skipfork {
        address consumerAddress = address(raffle);
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            consumerAddress
        );
    }

    function testRandomWordsCalledAfterPerformUpkeepPasses()
        public
        RaffleEnteredAndTimePassed
        skipfork
    {
        address consumerAddress = address(raffle);
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            consumerAddress
        );
        /**
         * LOGIC
         *  We use the skipfork modifier here since we're using the vrf mock. And this wouldnt be the same thing if testing on a sepolia testnet fork.
         *   raffle.performUpkeep(""); trigers requestRandomWords which produces a requestId
         *   fulfillRandomWords, only callable by vrfCoordinator, satisfies the requestRandomWords using the outputed requestId.
         */

        //Check for additional comments in testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
        public
        RaffleEnteredAndTimePassed
        skipfork
    {
        uint256 additionalPlayers = 5;
        uint256 startingIndex = 1; // There's a player at 0 thanks to modifier RaffleEnteredAndTimePassed
        uint256 i = startingIndex;

        for (i; i < startingIndex + additionalPlayers; i++) {
            ////// Why not for (i; i < additionalPlayers; i++) ?
            address player = address(uint160(i)); // i is a uint256. address can only be created from uint160.
            hoax(player, STARTING_BALANCE); // hoax is combo deal of vm.deal and vm.prank in one.
            raffle.enterRafflle{value: entranceFee}();
        }

        uint256 previousTimestamp = raffle.getLastTimestamp();

        uint256 raffleBalanceBeforePickingWinner = address(raffle).balance;

        // Now request random words with performUpKeep
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState rStateWhilePickingWinner = raffle.getRaffleState();

        // Act as vrf to fulfill request and pick a winner
        address consumerAddress = address(raffle);
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            consumerAddress
        );

        Raffle.RaffleState rStateAfterPickingWinner = raffle.getRaffleState();

        uint256 raffleBalanceAfterPickingWinner = address(raffle).balance;
        uint256 rafflePrize = entranceFee * (additionalPlayers + 1);

        // console.log ("Raffle state currently ", rState);
        assert(uint256(rStateWhilePickingWinner) == 1);
        assert(uint256(rStateAfterPickingWinner) == 0); // Fulfilling random words picks a winner andd sets raffle state to open(0)
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getLengthOfPlayersArray() == 0);
        assert(raffleBalanceBeforePickingWinner == rafflePrize);
        assert(raffleBalanceAfterPickingWinner == 0);
        assert(previousTimestamp < raffle.getLastTimestamp());
        assert(
            raffle.getRecentWinner().balance ==
                (STARTING_BALANCE + rafflePrize - entranceFee)
        );
    }
}
