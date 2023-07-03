pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "./utils.circom";
include "./basic.circom";

template RightShift(b, shift) {
  assert(shift < b);

  signal input x;
  signal output y;

  component x_bits = Num2Bits(b);
  x_bits.in <== x;

  signal y_bits[ b - shift ];
  for (var i = 0; i < b - shift; i++) {
    y_bits[i] <== x_bits.out[i + shift];
  }

  component y_num = Bits2Num(b - shift);
  y_num.in <== y_bits;
  y <== y_num.out;
}

template LeftShift(shift_bound) {
  signal input x;
  signal input shift;
  signal output y;

  var n = log2(shift_bound);

  component shift_bits = Num2Bits(n);
  shift_bits.in <== shift;

  component lt = LessThan(shift_bound);
  lt.in[0] <== shift;
  lt.in[1] <== shift_bound;
  lt.out === 1;

  var pow_shift = 1;
  component muxes[n];

  for (var i = 0; i < n; i++) {
    muxes[i] = IfElse();
    muxes[i].cond <== shift_bits.out[i];
    muxes[i].L <== pow_shift * (2 ** (2 ** i));
    muxes[i].R <== pow_shift;
    pow_shift = muxes[i].out;
  }

  y <== x * pow_shift;
}
