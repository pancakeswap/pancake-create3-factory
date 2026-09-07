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

### Local dry run on anvil
`./script/local-deploy-test.sh` starts an anvil, funds the deployer, runs the deploy script with `--broadcast` and checks the
factory address, `owner()`, `computeAddress` and `KECCAK256_PROXY_CHILD_BYTECODE` against the values on BSC.
`PRIVATE_KEY` in `.env` must be the original deployer. Pass `--dry-run` to only simulate the script.

### Create3Factory verification on explorer
In case contract verification fail when running deployment script, run

`forge verify-contract <address> Create3Factory --watch --chain <chain_id>`

### Keeping create3 addresses identical across chains

The address of a contract deployed through the factory is derived from `(factory address, salt, KECCAK256_PROXY_CHILD_BYTECODE)`.
`KECCAK256_PROXY_CHILD_BYTECODE` is `keccak256(type(CustomizedProxyChild).creationCode)` and is baked into the factory at compile time.
The creation code ends with the solc metadata hash, so **any** change to the solc version, optimizer settings, evm version,
remappings (they are part of the metadata) or `CustomizedProxyChild.sol` changes the hash, and every future create3 address with it.

Reference values from the factory live on BSC (`0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1`) are stored in
[script/Create3FactoryConstants.sol](script/Create3FactoryConstants.sol):

| Item | Value |
| ---- | ----- |
| deployer (nonce 0) | `0xDB1fa6562f3784643c1b547b17dcAEDE0b79CA80` |
| KECCAK256_PROXY_CHILD_BYTECODE | `0x062e0b9e0e28785406fcd3ea3efde49e1d40668774057ec7ba53f120d0809763` |
| computeAddress(0x1234) | `0xC9025a31E39f73AD2B0c7Ce16cceC6A3416e52E0` |

They are enforced in three places:
- `script/01_DeployCreate3Factory.s.sol` reverts **before** broadcasting if the deployer would not produce the same factory
  address or if the compiled `KECCAK256_PROXY_CHILD_BYTECODE` differs, and re-checks `computeAddress` after deployment.
- `test/Create3Factory.t.sol` (`test_KECCAK256_PROXY_CHILD_BYTECODE_MatchesBsc`, `test_ComputeAddress_MatchesBsc`) fails on any mismatch.
- `test/Create3FactoryFork.t.sol` (`test_Deploy_OpenZeppelinERC20_LocalVsBscFork`) deploys an OpenZeppelin ERC20 through the
  factory live on BSC (fork) and through a locally compiled factory deployed by the real deployer with nonce 0 on a second BSC
  fork where the on-chain factory has been wiped (so the local build lands on the same address), and asserts both addresses match.
  It uses `MAINNET_FORK_URL_BSC` when set and falls back to a public BSC rpc otherwise.

Do not change `foundry.toml` (`solc = '0.8.26'`, `evm_version = 'cancun'`, `optimizer_runs = 30_000`) or `remappings.txt`
without confirming the tests above still pass. Note that `remappings.txt` deliberately lists the seven remappings that
were part of the original build; newer forge versions would otherwise drop the redundant `@openzeppelin/contracts/` entry
and change the metadata hash.

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
| Robinhood     | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |

- zksync is verified at https://sepolia-era.zksync.network 
- linea: https://sepolia.lineascan.build/
- robinhood: https://explorer.testnet.chain.robinhood.com/

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
| Robinhood     | 0x38Ab3f2CE00973A51d3A2A04d634C9bcbf20e4e1  |

- zksync is verified at https://era.zksync.network
- linea : https://lineascan.build/
- robinhood: https://robinhoodchain.blockscout.com/


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
