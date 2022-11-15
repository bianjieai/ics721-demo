# Interchain NFT

## Overview

The following repository contains a basic example of an Interchain NFT module and serves as a developer guide for teams that wish to use Interchain NFT functionality.

The Interchain NFT module is now maintained within the `ibc-go` repository
[here](https://github.com/bianjieai/ibc-go/blob/develop/modules/apps/nft-transfer).

### Developer Documentation

## Setup

1. Clone this repository and build the application binary

```bash
git clone https://github.com/bianjieai/ics721-demo.git
cd ics721-demo

make install 
```

2. Compile and install an IBC relayer.

```bash
git clone https://github.com/cosmos/relayer.git
cd relayer
git checkout main
make install
```

_Note that the commit used in the test was 1bbccc903facc9b7b0dedef66ebefab1ed1b3430_

3. Bootstrap two chains and create an IBC connection and start the relayer

```bash
make init-golang-rly
```

## Demo

**NOTE:** For the purposes of this demo the setup scripts have been provided with a set of hardcoded mnemonics that generate deterministic wallet addresses used below.

```bash
# Store the following account addresses within the current shell env
export DEMOWALLET_1=$(irisd keys show demowallet1 -a --keyring-backend test --home ./data/test-1) && echo $DEMOWALLET_1;
export DEMOWALLET_2=$(irisd keys show demowallet2 -a --keyring-backend test --home ./data/test-2) && echo $DEMOWALLET_2;
```

### Issue an nft class on the `test-1` chain

Issue an nft class using the `irisd tx nft issue` cmd.
Here the message signer is used as the account owner.

```bash
# Issue an nft class
irisd tx nft issue cat --name=xiaopi --symbol=pipi --description="my cat" --uri="hhahahh"  --from demowallet1 --chain-id test-1 --keyring-dir ./data/test-1 --fees=1uiris --keyring-backend=test -b block --node tcp://127.0.0.1:16657 --mint-restricted=false --update-restricted=false

# Query the class
irisd query nft collection cat --node tcp://127.0.0.1:16657

```

### Mint a nft on the `test-1` chain

```bash
# Mint a nft
irisd tx nft mint cat xiaopi --uri="http://wwww.baidu.com" --from demowallet1 --chain-id test-1 --keyring-dir ./data/test-1 --fees=1uiris --keyring-backend=test -b block --node tcp://127.0.0.1:16657

# query the nft
irisd query nft token cat xiaopi --node tcp://127.0.0.1:16657
```

### Transfer a nft from chain `test-1` to chain `test-2`

```bash
# Execute the nft tranfer command
irisd tx nft-transfer transfer nft-transfer channel-0 iaa10h9stc5v6ntgeygf5xf945njqq5h32r5y7qdwl cat xiaopi --from demowallet1 --chain-id test-1 --keyring-dir ./data/test-1 --fees=1uiris --keyring-backend=test -b block --node tcp://127.0.0.1:16657 --packet-timeout-height 2-10000

# Query the newly generated class-id through class-trace
irisd query nft-transfer class-hash nft-transfer/channel-0/cat --node tcp://127.0.0.1:26657

# Query nft information on test-2
irisd query nft token ibc/943B966B2B8A53C50A198EDAB7C9A41FCEAF24400A94167846679769D8BF8311 xiaopi --node tcp://127.0.0.1:26657
```

When the nft is transferred out, the nft on the original chain will be locked to the [escrow account](https://github.com/bianjieai/ibc-go/blob/develop/modules/apps/nft-transfer/types/keys.go#L45). You can use the following command to determine whether the transferred nft is escrow

```bash
irisd query nft token cat xiaopi --node tcp://127.0.0.1:16657
```

### Transfer a nft back from chain `test-2` to chain `test-1`

```bash
irisd tx nft transfer nft-transfer channel-0 cosmos1m9l358xunhhwds0568za49mzhvuxx9uxre5tud ibc/943B966B2B8A53C50A198EDAB7C9A41FCEAF24400A94167846679769D8BF8311 xiaopi --from demowallet2 --chain-id test-2 --keyring-dir ./data/test-2 --fees=1uiris --keyring-backend=test -b block --node tcp://127.0.0.1:26657 --packet-timeout-height 2-10000
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

Please use conventional commits  <https://www.conventionalcommits.org/en/v1.0.0/>

```
chore(bump): bumping version to 2.0
fix(bug): fixing issue with...
feat(featurex): adding feature...
```
