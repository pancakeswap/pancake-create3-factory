# Pancake-create3-factory

create3-factory to be used by PCS for v4 or future deployments for deterministic address

## Context

create1 was rejected as 
- its under an EOA (tied to 1 person)

create2 was rejected as
-  some of v4 contracts takes `WETH` as constructor args
- `WETH` address can differs across chains
- this would result in different address across chains 

create3 was selected as
- deterministic address based on just `salt` 
- a tweak on the proxy `CustomisedProxyChild.sol` allows us to run some methods (`transferOwnership`)

## Deployment 

### Pre-req: before deployment, the follow env variable needs to be set
```
// set rpc url
export RPC_URL=https://

// private key need to be prefixed with 0x
export PRIVATE_KEY=0x

// so contract can be verified on explorer
export ETHERSCAN_API_KEY=xx
```

### Create3Factory verification on explorer
In case contract verification fail when running deployment script, run

`forge verify-contract <address> Create3Factory --watch --chain <chain_id>`

## Address

Below list the chains this contract has been deployed on:

### Testnet

| Chain         | Address |
| ------------- | ------------- |
| BSC           | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
| Sepolia       | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
| Polygon zkEVM | <wip - failed to get EIP-1559 fee>  |
| zkSync Era    | 0x38ab3f2ce00973a51d3a2a04d634c9bcbf20e4e1  |
| Arbitrum One  | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
| Linea         | 0x38ab3f2ce00973a51d3a2a04d634c9bcbf20e4e1  |
| Base          | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
| opBnb         | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |

- zksync is verified at https://sepolia-era.zksync.network 
- linea: https://sepolia.lineascan.build/

### Mainnet

| Chain         | Address |
| ------------- | ------------- |
| BSC           | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
| ETH           | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
| Polygon zkEVM | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
| zkSync Era    | 0x38ab3f2ce00973a51d3a2a04d634c9bcbf20e4e1  |
| Arbitrum One  | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
| Linea         | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
| Base          | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
| opBnb         | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |

- zksync is verified at https://era.zksync.network
- linea : https://lineascan.build/


## Linea tweaks

As Linea do not support `push0` opcode yet, ensure `foundry.toml` is updated to use `london` instead

```
// FROM
evm_version = 'cancun'

// TO
evm_version = 'london'
```

## zkSync tweaks

As zkSync requires foundry-zksync, below list the steps to deploy on zkSync

1. Install foundry-zk: https://github.com/matter-labs/foundry-zksync

2. The above installation will overwrite your existing foundry, so do the below to move foundry-zk (forge, cast) in another folder and alias them.

```
> mv ~/.foundry/bin/forge ~/.foundry/bin/forge-zk
> mv ~/.foundry/bin/cast ~/.foundry/bin/cast-zk
> alias forge-zk="$HOME/.foundry/bin/forge-zk"
> alias cast-zk="$HOME/.foundry/bin/cast-zk"
```

3. Reinstall foundry: https://getfoundry.sh/introduction/getting-started

4. When deploying, instead of `forge` use `forge-zk` 

5. Verifying

```
// pre-req: get ether_api_key from etherscan

forge-zk verify-contract {address} Create3Factory --watch \n
--chain {324 | 320} \n
--etherscan-api-key {ether_api_key} \n
--verifier etherscan \n
--verifier-url "https://api.etherscan.io/v2/api"
```
