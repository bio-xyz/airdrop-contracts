import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "node:fs";

const tree = StandardMerkleTree.load(JSON.parse(fs.readFileSync("path/to/your/merkle_tree.json")));

for (const [i, v] of tree.entries()) {
  console.log("-------");
  console.log("Proof for:", v[0]);
  const proof = tree.getProof(i);
  console.log("Proof:", proof);
}
