# To fund our VRF subscription progarmatically
Transfer of LINK from Metamask to SubscriptionID
```
forge script script/interactions.s.sol:FundSubscription --rpc-url $SEPOLIA_RPC_URL --private-key $SEPOLIA_PRIVATE_KEY --broadcast
```

# To print in .txt file total coverage
```
forge coverage --report debug > coverage.txt
```

# Testing on a fork url (Sepolia)
```
forge test --fork-url $SEPOLIA_RPC_URL -vvvvv
```

