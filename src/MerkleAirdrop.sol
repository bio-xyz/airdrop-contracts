//SPDX-License-Identifier: Unlicense
// Forkd from https://github.com/sodamnfoolish/simple-solidity-airdrop-contract-with-merkle-tree/blob/master/contracts/Airdrop.sol
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { MerkleProofLib } from "solady/utils/MerkleProofLib.sol";



contract MerkleAirdrop is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    bytes32 private merkleRoot;
    IERC20 private erc20;
    mapping(bytes32 => mapping(address => bool)) private merkleToClaimed;

    /// @dev Event emitted
    event MerkleRootUpdated(bytes32 indexed merkleRoot);
    event Withdraw(address indexed who, uint256 amount);
    event Claimed(address indexed who, uint256 amount);

    /// @dev Errors emitted
    error NotInMerkleTree();
    error AlreadyClaimed();
    error MerkleRootNotSet();

    /**
     * @notice Constructor to initialize the MerkleAirdrop contract
     * @param _erc20 The ERC20 token to be airdropped
     * @param _merkleRoot The initial merkle root for the airdrop
     */
    constructor(IERC20 _erc20, bytes32 _merkleRoot) {
        erc20 = _erc20;
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice Allows a user to claim their airdrop
     * @param amount The amount of tokens to claim
     * @param proof The merkle proof to validate the claim
     * @dev Reverts if the claim conditions are not met
     */
    function claim(uint256 amount, bytes32[] calldata proof) external nonReentrant {
        if (!inMerkle(msg.sender, amount, proof)) {
            revert NotInMerkleTree();
        }
        if (hasClaimed(msg.sender)) {
            revert AlreadyClaimed();
        }
        if (merkleRoot == bytes32(0)) {
            revert MerkleRootNotSet();
        }

        merkleToClaimed[merkleRoot][msg.sender] = true;
        erc20.safeTransfer(msg.sender, amount);

        emit Claimed(msg.sender, amount);
    }

    /**
     * @notice Checks if a user can claim the airdrop
     * @param who The address of the user
     * @param amount The amount of tokens to claim
     * @param proof The merkle proof to validate the claim
     * @return bool True if the user can claim, false otherwise
     */
    function inMerkle(address who, uint256 amount, bytes32[] calldata proof) public view returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(who, amount))));
        return (MerkleProofLib.verify(proof, merkleRoot, leaf));
    }

    /**
     * @notice Checks if a user has already claimed the airdrop
     * @param who The address of the user
     * @return bool True if the user has claimed, false otherwise
     */
    function hasClaimed(address who) public view returns (bool) {
        return merkleToClaimed[merkleRoot][who];
    }

    /**
     * @notice Updates the merkle root
     * @param _root new merkle root
     */
    function updateMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
        emit MerkleRootUpdated(_root);
    }

    /**
     * @notice Allows the owner to withdraw tokens from the contract
     * @param recipient The amount of tokens to withdraw
     * @param amount The amount of tokens to withdraw
     */
    function withdraw(address recipient, uint256 amount) external onlyOwner {
        erc20.safeTransfer(recipient, amount);
    }
}
