pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

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

template bitwiseAND(n){
  assert(n < 254);
  signal input a;
  signal input b;
  signal output out;

  component n2ba = Num2Bits(n);
  n2ba.in <== a;
  component n2bb = Num2Bits(n);
  n2bb.in <== b;

  signal bits[n];

  for (var i = 0; i < n; i++) {
    bits[i] <== n2ba.out[i] * n2bb.out[i];
    bits[i] * (1 - bits[i]) === 0;
  }

  component b2n = Bits2Num(n);
  b2n.in <== bits;
  out <== b2n.out;
}

template bitwiseOR(n){
  assert(n < 254);
  signal input a;
  signal input b;
  signal output out;

  component n2ba = Num2Bits(n);
  n2ba.in <== a;
  component n2bb = Num2Bits(n);
  n2bb.in <== b;

  signal bits[n];

  for (var i = 0; i < n; i++) {
    bits[i] <== n2ba.out[i] + n2bb.out[i] - n2ba.out[i]*n2bb.out[i];
  }

  component b2n = Bits2Num(n);
  b2n.in <== bits;
  out <== b2n.out;
}


