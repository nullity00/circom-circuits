pragma circom 2.0.0;

function log2(b){
  var n = 1, r = 1;
  while (n < b) {
    n *= 2;
    r++;
  }
  return r;
}

function gcd(left_operand, right_operand){
  var temp;
  var left;
  var right;
  left = left_operand;
  right = right_operand;

  while (right != 0){
    temp = left % right;
    left = right;
    right = temp;
  }
  return left;
}

function factorial(num){
  var result = 1;
  for(var i = 1; i <= num; i++){
    result = result * i;
  }
  return result;
}