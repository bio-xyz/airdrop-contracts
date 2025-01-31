// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

contract DeploymentScript is Script {
    address public tokenAddress;
    bytes32 public merkleRoot;
    uint256 public deployerPrivateKey;

    // Initialize in constructor
    constructor() {
        tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        merkleRoot = vm.envBytes32("MERKLE_ROOT");
        deployerPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOYER_PROD");
    }
}

contract DeployMerkleAirdrop is DeploymentScript {
    error AirdropDeploymentFailed();

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("Deployer address: %s", deployerAddress);
        console.log("Token address: %s", tokenAddress);
        console.log("Merkle root: %s", vm.toString(merkleRoot));

        require(tokenAddress != address(0), "Invalid token address");
        require(merkleRoot != bytes32(0), "Invalid merkle root");

        MerkleAirdrop merkleAirdrop = new MerkleAirdrop(
            IERC20Metadata(tokenAddress),
            merkleRoot
        );

        if (address(merkleAirdrop) == address(0)) {
            revert AirdropDeploymentFailed();
        }

        console.log(
            "MerkleAirdrop deployed successfully at: %s",
            address(merkleAirdrop)
        );

        vm.stopBroadcast();
    }
}
