# Interchain NFT

## Disclaimer

The following repository and [`x/inter-nft`](./x/inter-nft/) module serves as an example and is used to exercise the functionality of Interchain nft end-to-end for development purposes only.
This module **SHOULD NOT** be used in production systems and developers building on Interchain NFT are encouraged to design their own authentication modules which fit their use case.

## Overview 

The following repository contains a basic example of an Interchain NFT module and serves as a developer guide for teams that wish to use Interchain NFT functionality.

The Interchain NFT module is now maintained within the `ibc-go` repository 
[here](https://github.com/bianjieai/ibc-go/blob/ics-721-nft-transfer/modules/apps/nft-transfer). 

### Developer Documentation

## Setup

1. Clone this repository and build the application binary

```bash
git clone https://github.com/bianjieai/ics721-demo.git
cd ics721-demo

make install 
```

2. Compile and install an IBC relayer.
```
git clone https://github.com/cosmos/relayer/justin/sdk-0.46.0.git
cd relayer
make install
```

3. Bootstrap two chains and create an IBC connection and start the relayer
```
make init-golang-rly
```

## Demo

**NOTE:** For the purposes of this demo the setup scripts have been provided with a set of hardcoded mnemonics that generate deterministic wallet addresses used below.

```bash
# Store the following account addresses within the current shell env
export DEMOWALLET_1=$(nftd keys show demowallet1 -a --keyring-backend test --home ./data/test-1) && echo $DEMOWALLET_1;
export DEMOWALLET_2=$(nftd keys show demowallet2 -a --keyring-backend test --home ./data/test-2) && echo $DEMOWALLET_2;
```

### Issue an nft class on the `test-1` chain

Issue an nft class using the `nftd tx nft issue` cmd. 
Here the message signer is used as the account owner.

```bash
# Issue an nft class
nftd tx nft issue cat --name xiaopi --symbol pipi --description "my cat" --uri "hhahahh"  --from demowallet1 --chain-id test-1 --keyring-dir ./data/test-1 --fees=1stake --keyring-backend=test -b block --node tcp://127.0.0.1:16657

# Query the class
nftd query nft class cat --node tcp://127.0.0.1:16657

```

### Mint a nft on the `test-1` chain

```bash
# Mint a nft
nftd tx nft mint cat xiaopi --uri="http://wwww.baidu.com" --from demowallet1 --chain-id test-1 --keyring-dir ./data/test-1 --fees=1stake --keyring-backend=test -b block --node tcp://127.0.0.1:16657

# query the nft
nftd query nft nft cat xiaopi --node tcp://127.0.0.1:16657
```

### Transfer a nft from chain `test-1` to chain `test-2`

```bash
# Execute the nft tranfer command
nftd tx nft transfer nft-transfer channel-0 cosmos10h9stc5v6ntgeygf5xf945njqq5h32r53uquvw cat xiaopi --from demowallet1 --chain-id test-1 --keyring-dir ./data/test-1 --fees=1stake --keyring-backend=test -b block --node tcp://127.0.0.1:16657 --packet-timeout-height 2-10000

# Query the newly generated class-id through class-trace
nftd query nft-transfer class-hash nft-transfer/channel-0/cat --node tcp://127.0.0.1:26657

# Query nft information on test-2
nftd query nft nft ibc/943B966B2B8A53C50A198EDAB7C9A41FCEAF24400A94167846679769D8BF8311 xiaopi --node tcp://127.0.0.1:26657
```

#### Testing timeout scenario

1. Stop the relayer process and send an transfer nft transaction using one of the examples provided above.

2. Wait for approx. 1 minute for the timeout to elapse.

3. Restart the relayer process

```bash
rly start test1-nft-test2 --home $CHAIN_DIR/$RELAYER_DIR
```

4. Observe the packet timeout and relayer reacting appropriately (issuing a MsgTimeout to testchain `test-1`).

5. Due to the nature of ordered channels, the timeout will subsequently update the state of the channel to `STATE_CLOSED`.
Observe both channel ends by querying the IBC channels for each node.

```bash
# inspect channel ends on test chain 1
icad q ibc channel channels --home ./data/test-1 --node tcp://localhost:16657

# inspect channel ends on test chain 2
icad q ibc channel channels --home ./data/test-2 --node tcp://localhost:26657
```

## Collaboration

Please use conventional commits  https://www.conventionalcommits.org/en/v1.0.0/

```
chore(bump): bumping version to 2.0
fix(bug): fixing issue with...
feat(featurex): adding feature...
```
