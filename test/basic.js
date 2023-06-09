const path = require("path");
const assert = require("chai").assert;
const wasm_tester = require("circom_tester").wasm;

describe("Check Addition", () => {
  var circ_file = path.join(__dirname, "circuits", "add.circom");
  var circ, num_constraints;

  before(async () => {
    circ = await wasm_tester(circ_file);
    await circ.loadConstraints();
    num_constraints = circ.constraints.length;
    console.log("Number of constraints: " + num_constraints);
  });

  it("Addition of 3, 4, 5, 6", async () => {
    const input = {
      a: ["3", "4", "5", "6"],
    };
    const witness = await circ.calculateWitness(input);
    await circ.checkConstraints(witness);
    await circ.assertOut(witness, { out: "18" });
  });
});

describe("Check Multiplication", () => {
  var circ_file = path.join(__dirname, "circuits", "mul.circom");
  var circ, num_constraints;

  before(async () => {
    circ = await wasm_tester(circ_file);
    await circ.loadConstraints();
    num_constraints = circ.constraints.length;
    console.log("Number of constraints: " + num_constraints);
  });

  it("Multiplication of 3, 4, 5, 6", async () => {
    const input = {
      a: ["3", "4", "5", "6"],
    };
    const witness = await circ.calculateWitness(input);
    await circ.checkConstraints(witness);
    await circ.assertOut(witness, { out: "360" });
  });
});

describe("Check if odd", () => {
  var circ_file = path.join(__dirname, "circuits", "odd.circom");
  var circ, num_constraints;

  before(async () => {
    circ = await wasm_tester(circ_file);
    await circ.loadConstraints();
    num_constraints = circ.constraints.length;
    console.log("Number of constraints: " + num_constraints);
  });

  it("Check if 57 is odd", async () => {
    const input = {
      in: "57",
    };
    const witness = await circ.calculateWitness(input);
    await circ.checkConstraints(witness);
    await circ.assertOut(witness, { out: "1" });
  });
});
