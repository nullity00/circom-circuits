const path = require("path");
const assert = require("chai").assert;
const wasm_tester = require("circom_tester").wasm;

describe("CheckAddition", () => {
  var circ_file = path.join(__dirname, "circuits", "basic.circom");
  var circ, num_constraints;

  before(async () => {
      circ = await wasm_tester(circ_file);
      await circ.loadConstraints();
      num_constraints = circ.constraints.length;
      console.log("Number of constraints: " + num_constraints);
  });

  it("Addition of 3 and 4", async () => {
      const input = {
          "a": "3",
          "b": "4"
      };
      const witness = await circ.calculateWitness(input);
      await circ.checkConstraints(witness);
      await circ.assertOut(witness, {"c": "7"});
  });
});