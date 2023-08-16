pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/compconstant.circom";
include "../node_modules/circomlib/circuits/pointbits.circom";
include "../node_modules/circomlib/circuits/escalarmulfix.circom";


// ECDSA Signature
// sign(m, sk) = (R, s)

// ECDSA Verification
// s * G  = R + h(m, R, A) * A
template EddsaVerifier() {

  signal input msg;

  signal input Ax;
  signal input Ay;
  signal input R8[256];
  signal input S[256];

  signal R8x;
  signal R8y;

// Convert R8 to Field elements (And verify R8)

    component bits2pointR8 = Bits2Point_Strict();

    var i;

    for (i=0; i<256; i++) {
        bits2pointR8.in[i] <== R8[i];
    }
    R8x <== bits2pointR8.out[0];
    R8y <== bits2pointR8.out[1];

    component onCurve = OnCurve();
    onCurve.pt[0] <== R8x;
    onCurve.pt[1] <== R8y;

    component orderCheck = OrderCheck();
    orderCheck.Rx <== R8x;
    orderCheck.Ry <== R8y;

    component hash = Poseidon(5);

    // LHS : s * G


}


// https://github.com/Zokrates/ZoKrates/blob/latest/zokrates_stdlib/stdlib/ecc/edwardsOnCurve.zok

template OnCurve() {

  // a * x2 + y2 = 1 + d * x2 * y2

  signal input pt[2];

  var a = 168700;
  var d = 168696;

  signal x2 <== pt[0]*pt[0];
  signal y2 <== pt[1]*pt[1];

  signal x2_y2 <== x2*y2;

  a * x2 + y2 === 1 + d * x2_y2;

}

template OrderCheck(){
  signal input Rx;
  signal input Ry;

  // Check if Rx = 0 && Ry = 1

  component is_zero = IsZero();
  is_zero.in <== Rx;
  is_zero.out === 0;

  signal diff <== Ry - 1; // 1 - 1 = 0
  component diff_is_zero = IsZero();
  diff_is_zero.in <== diff;
  diff_is_zero.out === 0;

}