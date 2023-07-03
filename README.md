# circom-circuits

## usage

Run tests using this command. If you don't have mocha installed, be sure to install it using ``npm install -g mocha``

```
mocha test
```

## Gist of circuits

- ``basic.circom`` : Multi operand addition & multiplication, if else circuit
- ``shift.circom`` : Right & left shift circuits
- ``gates.circom`` : Multi operand AND , OR gates
- ``bitops.circom`` : Checks if the decimal & binary values are the same
- ``msnzb.circom`` : Circuit to find the Most Significant Non Zero Bit
- ``float_add.circom``: Adds two floating point numbers represented as exponent & mantissa
- ``utils.circom`` : helper functions to find gcd, factorial, log2 of a num

## To do

- implement [pruneBuffer](https://github.com/iden3/circomlibjs/blob/main/src/eddsa.js#L29) function as a template inside a circuit, to allow the same random value to be the private key both inside and outside the circuit. Off-circuit pubkey generation requires the private key to be massaged (“pruned”) before being passed into a circuit. 
- circuits for proof of burn, proof of solvency 
- tests !!!!
