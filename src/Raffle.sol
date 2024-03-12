// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title     A sample Raffle contract
 * @author    Ikpong Joseph
 * @notice    This contract is for creating a sample raflle
 * @dev       Implements the Chainlink VRFv2
 */
import {VRFCoordinatorV2Interface} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2 {
    /**
     * Errors
     */
    error Raffle__NotEnoughETHSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numberOfPlayers, uint256 raffleState); // OR RaffleState raffleState -- enums are implicitly convertible to uint256.

    /**
     * Type Declarations
     */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /**
     * State Variables
     */
    uint16 private constant REQUEST_CONFIRMAION = 3; //This is the number of blocks we'd like to confirm our randomly generated number by. A constant bcos it's not chain dependent.
    uint32 private constant NUM_WORDS = 1; //Number of random numbers we want to genarate.

    uint256 private immutable i_entranceFee;
    // @dev    Duration of interval in seconds
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address payable private s_recentWinner;

    RaffleState private s_raffleState;

    /**
     * Events
     */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    /**
     * Constructor
     */
    /**
     * The VRFConsumerBaseV2(vrfCoordinator) passed in our constructor is because we inherited the contract VRFConsumerBaseV2.
     * That contract has a constructor which must be fulfilled in ours.
     */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    /**
     * Functions
     */
    function enterRafflle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        // Add players into s_players[]
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /**
    * @dev  This checks if it's time to call checkUpkeep()
    *       i.e if i_interval has reached.
    * The following must be true
    * 1. The interval time must have pased. 
    * 2. Raffle haaaas raffleHasETH
    * 3. Raffle haaaas players.
    * 4. Subscription account haas LINK.

    */

    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool raffleHasETH = address(this).balance > 0; // Shouldn't it be raffleHasLINK ?
        bool raffleHasPlayers = s_players.length > 0;
        bool raffleIsOpen = RaffleState.OPEN == s_raffleState;
        upkeepNeeded = (timeHasPassed && raffleHasETH && raffleHasPlayers && raffleIsOpen);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        // Formerly pickWinner()
        // Check if enough time has passed since creation of contract
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        
        // Set the state of the Raffle to avoid players from entering while a winner is being picked.
        s_raffleState = RaffleState.CALCULATING;

        // 1. Requesst Randomm number(numWords)
        // 2. Use that random number to pick a winner.
        // 1. Copied from code example @ https://docs.chain.link/vrf/v2/subscription/examples/get-a-random-number
        /**
         * i_vrfCoordinator replaccces COORDINATOR from original exampllle @ link.
         * i_gasLane replaces keyHash from link too.
         * i_callbackGasLimit is the max number of gas we want to spend when receiving the random words(/Numbers)
         */
         uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, i_subscriptionId, REQUEST_CONFIRMAION, i_callbackGasLimit, NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);


        // This only reeeeeqquests random number from chainlink VRF and refuses entry into the raffle until a winner is picked.
    }

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory _randomWords) internal override {
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        // The line above takes the first random number from the _randomWords[] and is moduloed by the length
        // i.e the total number of players that entered the raffld a singular number returnned.
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;

        // Set the state of the Raffle to allow players enter Raffle.
        s_raffleState = RaffleState.OPEN;

        // Reset s_players[] and time
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }

        emit PickedWinner(winner);

        // This   function is what picks winner from theeeeeee raffle.
    }

    /**
     * GETTER FUNCTIONS
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
    function getPlayers(uint256 indexOfPlayer) external view returns(address) {
        return s_players[indexOfPlayer];
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getRecentWinner() external view returns(address) {
        return s_recentWinner;
    }

    function getLengthOfPlayersArray() external view returns (uint256) {
        return s_players.length;
    }

    function getLastTimestamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}
