## MerkleAirdrop Contract

The MerkleAirdrop contract is a smart contract that enables efficient token distribution using Merkle proofs. This implementation allows for gas-efficient token claiming by users who are part of the Merkle tree.

### Features

- **ERC20 Token Distribution**: Supports airdropping any ERC20 token
- **Merkle Proof Verification**: Uses cryptographic proofs to verify claim eligibility
- **Gas Efficient**: Only stores one Merkle root instead of all user data
- **Claim Tracking**: Prevents double-claiming by maintaining a record of claimed addresses
- **Owner Controls**: Allows the owner to update the Merkle root and withdraw unclaimed tokens

### How to Use

#### 1. Create the Merkle Tree

First, prepare your airdrop data in a CSV file with the following format:
```csv
Address,Amount in Wei
0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e,1000000000000000000000000
0x2D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3f,2000000000000000000000000
```

Place your CSV file in the `merkle_tree/recipients` directory and update the `FILE_NAME` in `script/create_tree.js`.

Then run:
```shell
$ node script/create_tree.js
```

This will:
- Generate a Merkle tree from your CSV data
- Save the tree data to `merkle_tree/trees/{timestamp}_{filename}.json`
- Output the Merkle root to use in the contract deployment

#### 2. Generate Proofs

To generate proofs for each address in the Merkle tree:

```shell
$ node script/create_proof.js
```

Make sure to update the path to your Merkle tree JSON file in the script.

#### 3. Deploy the Contract

Deploy the contract with the token address and Merkle root:
```shell
$ forge script script/Deploy.s.sol:DeployScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

#### 4. Claim Tokens

Users can claim their tokens by providing their proof:
```solidity
function claim(bytes32[] calldata proof, uint256 amount) external
```

#### 5. Verify Claims

Check if an address has already claimed:
```solidity
function hasClaimed(address user) external view returns (bool)
```

### Security Considerations

- The Merkle root should be carefully generated and verified before deployment
- Only addresses included in the Merkle tree can claim tokens
- Each address can only claim once
- The contract owner has the ability to update the Merkle root and withdraw tokens


## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
