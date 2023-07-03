pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/comparators.circom";

template MultiOR(n){
  signal input in[n];
  signal output out;

  signal sums[n];
  sums[0] <== in[0];
  for (var i = 1; i < n; i++) {
    sums[i] <== sums[i-1] + in[i];
  }

  component is_zero = IsZero();
  is_zero.in <== sums[n-1];
  out <== 1 - is_zero.out;
}

template MultiAND(n){
  signal input in[n];
  signal output out;

  signal sums[n];
  sums[0] <== in[0];
  for (var i = 1; i < n; i++) {
    sums[i] <== sums[i-1] * in[i];
  }

  component is_zero = IsZero();
  is_zero.in <== sums[n-1];
  out <== 1 - is_zero.out;
}