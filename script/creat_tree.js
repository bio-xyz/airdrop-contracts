import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

import fs from "node:fs";
import csv from "csv-parser";
import path from "node:path";

const values = [];

const columnOrder = [
  "Address",
  "Amount in Wei",
];

const FILE_NAME = "your_file_name";

/* 
EXAMPLE OF CSV FILE (recipients/your_file_name.csv)

Address,Amount in Wei
0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e,1000000000000000000000000
0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e,1000000000000000000000000

*/

// Ensure directories exist
const recipientsDir = path.resolve('/merkle_tree/recipients');
const treesDir = path.resolve('/merkle_tree/trees');
fs.mkdirSync(recipientsDir, { recursive: true });
fs.mkdirSync(treesDir, { recursive: true });

const CSV_FILE_PATH = path.resolve(`${recipientsDir}/${FILE_NAME}.csv`);
const JSON_OUTPUT_PATH = path.resolve(`${treesDir}/${Date.now()}_${FILE_NAME}.json`);

fs.createReadStream(CSV_FILE_PATH)
  .pipe(csv())
  .on("data", (row) => {
    const orderedRow = columnOrder.map((columnName) => row[columnName]);
    values.push(orderedRow);
  })
  .on("end", () => {
    const tree = StandardMerkleTree.of(values, [
      "address",
      "uint256",
    ]);

    console.log("Merkle Tree Created At:", JSON_OUTPUT_PATH);
    console.log("Merkle Root:", tree.root);
    fs.writeFileSync(JSON_OUTPUT_PATH,
      JSON.stringify(tree.dump())
    );
  });
