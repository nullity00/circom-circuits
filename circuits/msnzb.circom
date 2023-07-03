pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/comparators.circom";

// Most Significant Non Zero Bit

template MSNZB(b) {
  assert(b < 254);
  signal input in;
  signal output one_hot[b];

  for (var i = 0 ; i < b; i++) {
    var temp;
    // refactor this
    if (((1 << i) <= in) && (in < (1 << (i+1)))) {
      temp = 1;
    } else {
      temp = 0;
    }
    one_hot[i] <-- temp;
  }

  var lc;

  for (var i = 0; i < b; i++) {
    one_hot[i] * (1 - one_hot[i]) === 0;
    lc += one_hot[i];
  }

  lc === 1;

  var pow2 = 0;
  var pow21 = 0;

  for (var i = 0; i < b; i++) {
    pow2 += one_hot[i] * (1 << i);
    pow21 += one_hot[i] * (1 << (i+1));
  }

  component lt1 = LessThan(b+1);
  lt1.in[0] <== in;
  lt1.in[1] <== pow21;
  lt1.out === 1;

  component lt2 = LessThan(b+1);
  lt2.in[0] <== pow2 - 1;
  lt2.in[1] <== in;
  lt2.out === 1;
}