pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/switcher.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "./utils.circom";
include "./basic.circom";
include "./msnzb.circom";
include "./bitops.circom";
include "./shift.circom";

template Normalize(k, p, P) {
  signal input e;
  signal input m;
  signal output e_out;
  signal output m_out;
  assert(P > p);

  component msnzb = MSNZB( P + 1 );
  msnzb.in <== m;

  var ell, l;
  for (var i = 0; i < P + 1; i++) {
    ell += msnzb.one_hot[i] * i;
    l += msnzb.one_hot[i] * (1 << (P - i));
  }

  m_out <== m * l;
  e_out <== e + ell - p;
}


// Credit : Deevashwer Rathee @ UC Berkeley
template CheckWellFormedness(k, p) {
  signal input e;
  signal input m;

  // check if `e` is zero
  component is_e_zero = IsZero();
  is_e_zero.in <== e;

  // Case I: `e` is zero
  //// `m` must be zero
  component is_m_zero = IsZero();
  is_m_zero.in <== m;

  // Case II: `e` is nonzero
  //// `e` is `k` bits
  component check_e_bits = CheckBitLength(k);
  check_e_bits.in <== e;
  //// `m` is `p`+1 bits with the MSB equal to 1
  //// equivalent to check `m` - 2^`p` is in `p` bits
  component check_m_bits = CheckBitLength(p);
  check_m_bits.in <== m - (1 << p);

  // choose the right checks based on `is_e_zero`
  component if_else = IfElse();
  if_else.cond <== is_e_zero.out;
  if_else.L <== is_m_zero.out;
  //// check_m_bits.out * check_e_bits.out is equivalent to check_m_bits.out AND check_e_bits.out
  if_else.R <== check_m_bits.out * check_e_bits.out;

  // assert that those checks passed
  if_else.out === 1;
}

template RoundAndCheck(k, p, P) {
  signal input e;
  signal input m;
  signal output e_out;
  signal output m_out;
  assert(P > p);

  // check if no overflow occurs
  component if_no_overflow = LessThan(P+1);
  if_no_overflow.in[0] <== m;
  if_no_overflow.in[1] <== (1 << (P+1)) - (1 << (P-p-1));
  signal no_overflow <== if_no_overflow.out;

  var round_amt = P-p;
  // Case I: no overflow
  // compute (m + 2^{round_amt-1}) >> round_amt
  var m_prime = m + (1 << (round_amt-1));
  component right_shift = RightShift(P+1, round_amt);
  right_shift.x <== m_prime;
  var m_out_1 = right_shift.y;
  var e_out_1 = e;

  // Case II: overflow
  var e_out_2 = e + 1;
  var m_out_2 = (1 << p);

  // select right output based on no_overflow
  component if_else[2];
  for (var i = 0; i < 2; i++) {
    if_else[i] = IfElse();
    if_else[i].cond <== no_overflow;
  }
  if_else[0].L <== e_out_1;
  if_else[0].R <== e_out_2;
  if_else[1].L <== m_out_1;
  if_else[1].R <== m_out_2;
  e_out <== if_else[0].out;
  m_out <== if_else[1].out;
}

template FloatAdd(k, p) {
  signal input e[2];
  signal input m[2];
  signal output e_out;
  signal output m_out;

  component cwf1 = CheckWellFormedness(k, p);
  cwf1.e <== e[0];
  cwf1.m <== m[0];

  component cwf2 = CheckWellFormedness(k, p);
  cwf2.e <== e[1];
  cwf2.m <== m[1];

  signal mag1 <== (e[0] * (1 << (p + 1))) + m[0];
  signal mag2 <== (e[1] * (1 << (p + 1))) + m[1];

  component lt = LessThan(k + p + 2);
  lt.in[0] <== mag2;
  lt.in[1] <== mag1;

  var input1[2] = [e[0], m[0]];
  var input2[2] = [e[1], m[1]];

  component switcher[2];

  for (var i = 0; i < 2; i++) {
    switcher[i] = Switcher();
    switcher[i].L <== input1[i];
    switcher[i].R <== input2[i];
    switcher[i].sel <== lt.out;
  }

  signal alpha_e <== switcher[0].outR;
  signal beta_e <== switcher[0].outL;

  signal alpha_m <== switcher[1].outR;
  signal beta_m <== switcher[1].outL;
  signal diff <-- alpha_e - beta_e;

  component lt1 = LessThan(k);
  lt1.in[0] <== (p+1);
  lt1.in[1] <== diff;

  signal greater_than <== lt1.out;

  component iz = IsZero();
  iz.in <== alpha_e;

  component or = OR();
  or.a <== iz.out;
  or.b <== greater_than;
  signal cond <== or.out;

  component lshift = LeftShift(p + 2);
  lshift.x <== alpha_m;
  lshift.shift <== diff;
  lshift.skip_checks <== cond;
  
  signal alpha_m2 <== lshift.y ;
  signal m2 <== alpha_m2 + beta_m;

  component normalize = Normalize(k, p, 2*p + 1);
  normalize.m <== m2;
  normalize.e <== beta_e;
  normalize.skip_checks <== cond;

  component round = RoundAndCheck(k, p, 2*p + 1);
  round.e <== normalize.e_out;
  round.m <== normalize.m_out;
  
  // use if else here
  e_out <-- cond ? alpha_e : round.e_out;
  m_out <-- cond ? alpha_m : round.m_out;
}