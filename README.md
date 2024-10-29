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
| zkSync Era    | <wip - require foundry-zksync>  |
| Arbitrum One  | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
| Linea         | <wip - no push0 support>  |
| Base          | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
| opBnb         | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |

### Mainnet

| Chain         | Address |
| ------------- | ------------- |
| BSC           | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
| ETH           | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
| Polygon zkEVM | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
| zkSync Era    | <wip - require foundry-zksync>  |
| Arbitrum One  | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
| Linea         | <wip - no push0 support>  |
| Base          | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
| opBnb         | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |
