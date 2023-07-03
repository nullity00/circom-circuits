pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/comparators.circom";

template Add(n) {
  signal input a[n];
  signal output out;

  signal temp[n];
  temp[0] <== a[0];

  for (var i = 1; i < n; i++) {
    temp[i] <== temp[i-1] + a[i];
  }

  out <== temp[n-1];
}

template Mul(n) {
  signal input a[n];
  signal output out;

  signal temp[n];
  temp[0] <== a[0];

  for (var i = 1; i < n; i++) {
    temp[i] <== temp[i-1] * a[i];
  }

  out <== temp[n-1];
}

template CheckIfOdd(n){
  signal input in;
  signal output out;
  component n2b = Num2Bits(n);
  n2b.in <== in;
  n2b.out[0] === 1;

  // --> Alternate implementation
  // out <== in % 2;
}

template CheckIfBinOdd(n){
  signal input in[n];
  signal output out;
  out <== in[0];
}

template IfElse() {
  signal input cond;
  signal input L;
  signal input R;
  signal output out;

  out <== cond * (L - R) + R;
}