pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/comparators.circom";

template CheckBitLength(b) {
  assert(b < 254);
  signal input in;
  signal output out;

  signal bits[b];
  var sum_of_bits = 0;

  for (var i = 0; i < b; i++) {
    bits[i] <-- (in >> i) & 1;
    bits[i] * (1 - bits[i]) === 0;
    sum_of_bits += (2 ** i) * bits[i];
  }

  component is_eq = IsEqual();

  is_eq.in[0] <== sum_of_bits;
  is_eq.in[1] <== in;

  out <== is_eq.out;
}