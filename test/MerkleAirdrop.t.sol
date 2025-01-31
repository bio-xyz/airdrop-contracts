// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Token} from "./Token.sol";

import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";

contract MerkleAirdropTest is Test {
    Token internal token;
    MerkleAirdrop internal merkleAirdrop;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address deployer = makeAddr("bighead");

    address jane = makeAddr("jane");
    address john = makeAddr("john");

    bytes32[] aliceProof = new bytes32[](1);
    bytes32[] johnProof = new bytes32[](3);

    // merkleRoot of alice, bob, bighead
    bytes32 merkleRoot1 =
        0x5d4b0fe136f29f1d289db44799922e478233784e41f3503c3978c30aa062e340;

    function setUp() public {
        emit log_address(alice);
        emit log_address(bob);
        emit log_address(deployer);
        emit log_address(jane);
        emit log_address(john);

        // Merkle Proof for alice
        aliceProof[
            0
        ] = 0x561fb36e5ca9909a808f1e83a1363762ff75b9a121babb0178f6c9fc690a1367;

        // Merkle Proof for john after merkle tree update
        johnProof[
            0
        ] = 0x91f0946464aa7ec225a6fe8d6c3e196078687e2b51bcf5666e1289cbd40f949c;
        johnProof[
            1
        ] = 0x4d35e39cf877ec72e09d991a3afa2a98adc6975a4f8f792eccefc9b416159052;

        vm.startPrank(deployer);
        token = new Token("Test Token", "TT", 18, 1000000 ether);

        // Initiate MerkleAirdrop with the merkle root
        merkleAirdrop = new MerkleAirdrop(IERC20Metadata(token), merkleRoot1);
        token.transfer(address(merkleAirdrop), 1000000 ether);
        vm.stopPrank();
    }

    function testCanClaimAirdrop() public {
        vm.warp(1622551240);

        assertEq(token.balanceOf(alice), 0);

        vm.startPrank(alice);
        merkleAirdrop.claim(2 ether, aliceProof);
        vm.stopPrank();

        assertEq(token.balanceOf(alice), 2 ether);
        assertEq(merkleAirdrop.inMerkle(alice, 2 ether, aliceProof), true);
        assertEq(merkleAirdrop.hasClaimed(alice), true);
    }

    function testCanOnlyClaimOnce() public {
        vm.warp(1622551240);

        vm.startPrank(alice);
        merkleAirdrop.claim(2 ether, aliceProof);
        vm.expectRevert(MerkleAirdrop.AlreadyClaimed.selector);
        merkleAirdrop.claim(2 ether, aliceProof);
        vm.stopPrank();

        assertEq(token.balanceOf(alice), 2 ether);
    }

    function testProofMustBeValid() public {
        vm.warp(1622551240);
        vm.startPrank(alice);

        vm.expectRevert(MerkleAirdrop.NotInMerkleTree.selector);
        merkleAirdrop.claim(2000 ether, aliceProof);

        aliceProof[
            0
        ] = 0xca6d546259ec0929fd20fbc9a057c980806abef37935fb5ca5f6a179718f1481;

        vm.expectRevert(MerkleAirdrop.NotInMerkleTree.selector);
        merkleAirdrop.claim(2 ether, aliceProof);
        vm.stopPrank();

        assertEq(token.balanceOf(alice), 0);
    }

    function testCannotClaimWithoutTokens() public {
        vm.warp(1622551240);

        vm.startPrank(deployer);
        merkleAirdrop.withdraw(deployer, 1000000 ether);
        vm.stopPrank();

        assertEq(token.balanceOf(address(merkleAirdrop)), 0);

        vm.startPrank(alice);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        merkleAirdrop.claim(2 ether, aliceProof);
        vm.stopPrank();

        assertEq(merkleAirdrop.hasClaimed(alice), false);
    }

    function testUpdateMerkleRoot() public {
        // Test updating merkle root
        bytes32 newMerkleRoot = 0x1234567890123456789012345678901234567890123456789012345678901234;

        // Non-owner should not be able to update
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        merkleAirdrop.updateMerkleRoot(newMerkleRoot);
        vm.stopPrank();

        // Verify current merkle proof still works
        assertEq(merkleAirdrop.inMerkle(alice, 2 ether, aliceProof), true);

        // Owner updates merkle root
        vm.startPrank(deployer);
        merkleAirdrop.updateMerkleRoot(newMerkleRoot);
        vm.stopPrank();

        // Verify old merkle proof no longer works
        assertEq(merkleAirdrop.inMerkle(alice, 2 ether, aliceProof), false);
    }

    function testWithdraw() public {
        uint256 initialBalance = token.balanceOf(address(merkleAirdrop));

        // Non-owner should not be able to withdraw
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        merkleAirdrop.withdraw(alice, 100 ether);
        vm.stopPrank();

        // Owner should be able to withdraw
        vm.startPrank(deployer);
        merkleAirdrop.withdraw(deployer, 100 ether);
        vm.stopPrank();

        assertEq(
            token.balanceOf(address(merkleAirdrop)),
            initialBalance - 100 ether
        );
        assertEq(token.balanceOf(deployer), 100 ether);
    }

    function testInMerkleValidation() public {
        // Test with invalid amount
        assertEq(merkleAirdrop.inMerkle(alice, 3 ether, aliceProof), false);

        // Test with invalid proof
        bytes32[] memory invalidProof = new bytes32[](1);
        invalidProof[0] = bytes32(0);
        assertEq(merkleAirdrop.inMerkle(alice, 2 ether, invalidProof), false);
    }

    function testCannotClaimWhenRootNotSet() public {
        // Set merkle root to zero
        vm.startPrank(deployer);
        merkleAirdrop.updateMerkleRoot(bytes32(0));
        vm.stopPrank();

        // Try to claim
        vm.startPrank(alice);
        vm.expectRevert(MerkleAirdrop.NotInMerkleTree.selector);
        merkleAirdrop.claim(2 ether, aliceProof);
        vm.stopPrank();
    }
}
