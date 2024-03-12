# Foundry Smart Contract Lottery

This project is based on Lesson 9 of the Patrick Collin Cyfrin Updraft's Foundry Full Course.


## Lessons

### In this lesson I learnt how to:

- utilize Libraries.
- layout a smart contract and function.
- create a Logic-based Chainlink Automation.
- integrate mocks into the development environment.
- write a comprehensive Makefile for development commands automation.
- write and debug full-bodied unit tests on local (Anvil) and forked (Sepolia) networks.
- set up, create, and fund the Chainlink VRF (Verifiable Random Function) both programmatically and on the UI. As well as adding a consumer.
- utilize robust Network configurations and Interaction scripts that run seamlessly on local and forked networks, via a single deploy script.
  

## How it works:

1. Players enter the raffle with an `entranceFee` and only when Raffle state is Open.
2. Chainlink Automation performs routine checks on the program's logic. And if all criteria are satisfied, it will signal Chainlink VRF to provide a Random number.
3. Following the logic in the code, a winner will be picked out of Players and the prize, `entranceFee` from all players, is transfered to them.

*A truly random, open, and verifiable lottery.*


## What can be implemented?

Feel free to contribute to this repo as you see fit.

Thank you for reading this far. And if you'd like to interact with this contract, the raffle contract is available on [sepolia testnet](https://sepolia.etherscan.io/address/0x2cf82a210f42800b6ba506969422e74f7331a279)


## Layout of A Contract:

- version
- imports
- errors
- interfaces, libraries, contracts
- Type declarations
- State variables
- Events
- Modifiers
- Functions
  - constructor
  - receive function (if exists)
  - fallback function (if exists)
  - external
  - internal
  - private
  - internal & private view & pure functions
  - external & public view & pure functions
