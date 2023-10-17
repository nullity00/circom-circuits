## Commands to generate a proof 


### Compile a circuit 
```
circom circuit.circom
```

### Generate an R1CS File 
```
circom circuit.circom --r1cs --sym
```

### Read R1CS File
```
snarkjs r1cs print circuit.r1cs
snarkjs r1cs info circuit.r1cs
```

### JS File to create a witness vector
```
circom circuit.circom --r1cs --sym --wasm
```
Create an input.json file & give the input values 
```
{"a": "4","b": "73"}
```
### Export witness 
```
node generate_witness.js sha256.wasm input.json witness.wtns
snarkjs wtns export json witness.wtns
```
### Set up plonk proving key
```
snarkjs plonk setup circuit.r1cs powersOfTau28_hez_final_08.ptau circuit_final.zkey
```
### Verify if you have the right zkey
```
snarkjs zkey verify circuit.r1cs powersOfTau28_hez_final_08.ptau circuit_final.zkey
```
### Export Verification Key
```
snarkjs zkey export verificationkey circuit_final.zkey verification_key.json
```
### prove 
```
snarkjs plonk prove circuit_final.zkey witness.wtns proof.json public.json
```
### Verify using vkey
```
snarkjs plonk verify verification_key.json public.json proof.json
```
### Export solidity Verifier
```
snarkjs zkey export solidityverifier circuit_final.zkey verifier.sol
```
### Export proof as uint256 arrays
```
snarkjs zkey export soliditycalldata public.json proof.json
```
