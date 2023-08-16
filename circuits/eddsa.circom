pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/compconstant.circom";
include "../node_modules/circomlib/circuits/pointbits.circom";
include "../node_modules/circomlib/circuits/escalarmulfix.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/escalarmulany.circom";
include "../node_modules/circomlib/circuits/babyjub.circom";


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

  var BASE8[2] = [
        5299619240641551281634865583518297030282874472190772894086521144482721001553,
        16950150798460657717958625567821834550301663161624707787222815936182638968203
    ];

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
    hash.inputs[0] <== R8x;
    hash.inputs[1] <== R8y;
    hash.inputs[2] <== Ax;
    hash.inputs[3] <== Ay;
    hash.inputs[4] <== msg;

    // LHS : s * G
    component lhs = EscalarMulFix(256, BASE8);
    
    for( var i=0; i < 256; i++) {
        lhs.e[i] <== S[i];
    }

    // RHS : R + h(m, R, A) * A

    
    // converting hash to bits

    component n2b = Num2Bits(256);
    n2b.in <== hash.out; // output of the Poseidon Hash

    // hash * A
    component mulHash = EscalarMulAny(256);
    
    for(var i=0; i<256; i++) {
        mulHash.e[i] <== n2b.out[i];
    }

    mulHash.p[0] <== Ax;
    mulHash.p[1] <== Ay;

    // R + hash * A

    component rhs = BabyAdd();
    rhs.x1 <== R8x;
    rhs.y1 <== R8y;
    rhs.x2 <== mulHash.out[0];
    rhs.y2 <== mulHash.out[1];

    // Check if LHS = RHS

    lhs.out[0] === rhs.xout;
    lhs.out[1] === rhs.yout;

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