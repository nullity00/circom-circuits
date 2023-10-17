// https://zkrepl.dev/?gist=d02f3ab7b7d049a87b8df1957e096bec

pragma circom 2.1.4;

include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/sha256/constants.circom";
include "../../node_modules/circomlib/circuits/sha256/sha256compression.circom";

template VariableLengthHash() {
    signal input input_bytes[10][32];
    signal input length;
    signal output hash;

    assert(length < 11);
    var k;

    /* <------ Computing the suffix array -------> */

    signal arr[2][512];
    signal shift[2][64];
    signal and[2][64];
    signal odd[2][64];
    signal quotient[2][64];
    arr[0][0] <== 1; 
    arr[1][0] <== 1; 

    /* 
    Safe way to do this (Costs an extra 2k constraints):
    Compute the shift in binary using Num2Bits
    Assign the 0th bit to arr
    */

    // 256 bit
    for (var j = 0; j<64; j++) {
        shift[0][64 -j -1] <-- (256 * length) >> j;
        and[0][64 -j -1] <-- (256 * length) & (2**(j) - 1);
        and[0][64 -j -1] + shift[0][64 -j -1] * 2** j === 256 * length;

        odd[0][64 - j -1] <-- shift[0][64 -j -1] % 2;
        odd[0][64 - j -1] * (odd[0][64 - j -1] - 1) === 0;

        quotient[0][64 - j -1] <-- shift[0][64 -j -1] \ 2;
        quotient[0][64 - j -1] * 2  + odd[0][64 - j -1] === shift[0][64 -j -1];

        arr[0][256 - j -1] <-- shift[0][64 -j -1] & 1;
        arr[0][256 - j -1] === odd[0][64 - j -1];
    }
    for (k=1; k<192; k++){
        arr[0][k] <== 0;
    }
    for (k=256; k<512; k++){
        arr[0][k] <== 0;
    }

    // 512 bit
    for (var j = 0; j<64; j++) {
        shift[1][64 -j -1] <-- (256 * length) >> j;
        and[1][64 -j -1] <-- (256 * length) & (2**(j) - 1);
        and[1][64 -j -1] + shift[1][64 -j -1] * 2** j === 256 * length;

        odd[1][64 - j -1] <-- shift[1][64 -j -1] % 2;
        odd[1][64 - j -1] * (odd[1][64 - j -1] - 1) === 0;

        quotient[1][64 - j -1] <-- shift[1][64 -j -1] \ 2;
        quotient[1][64 - j -1] * 2  + odd[1][64 - j -1] === shift[1][64 -j -1];

        arr[1][512 - j -1] <-- shift[1][64 -j -1] & 1;
        arr[1][512 - j -1] === odd[0][64 - j -1];
    }
    for (k=1; k<448; k++){
        arr[1][k] <== 0;
    }

    /* <------ Convert the input bytes to bits -------> */

    signal bytes2bits[12][256];
    component n2b[12][32];

    for (var i = 0; i < 10; i++) {

        for (var j = 0; j < 32; j++) {

            n2b[i][j] = Num2Bits(8);
            n2b[i][j].in <== input_bytes[i][j];


            for (var k = 0; k < 8; k++) {
                bytes2bits[i][j * 8 + k] <== n2b[i][j].out[7 - k];
            }    
        } 
    }

    for (var i=10; i<12; i++){
        for(var j = 0; j <256; j++){
            bytes2bits[i][j] <== 0;
        }
    }

    /* <------ Compute the concatenated bits by appending the suffix array -------> */

    signal bits[3072]; // Max = nBlocks x 512 = 6 x 512 = 3072
    component lt[12];
    component leqi[12];
    component leqi1[12];
    signal prod1[12];
    signal prod2[12];
    signal prod3[12][256];
    signal prod4[12][256];
    signal prod5[12][256];
    signal prod6[12][256];
    component length2bits = Num2Bits(5);
    length2bits.in <== length;
    

    for (var i = 0; i < 12; i++) {

        lt[i] = LessThan(4);
        lt[i].in[0] <== i;
        lt[i].in[1] <== length;

        leqi[i] = IsEqual();
        leqi[i].in[0] <== i;
        leqi[i].in[1] <== length;

        leqi1[i] = IsEqual();
        leqi1[i].in[0] <== i;
        leqi1[i].in[1] <== length + 1;

        prod1[i] <== (1 - length2bits.out[0]) * leqi[i].out;
        prod2[i] <== (1 - length2bits.out[0]) * leqi1[i].out;

        for (var j = 0; j < 256; j++) {
            prod3[i][j] <== length2bits.out[0] * arr[0][j];
            prod4[i][j] <== prod1[i] * arr[1][j] + prod3[i][j];
            prod5[i][j] <== prod2[i] * arr[1][256+j] + prod4[i][j];
            prod6[i][j] <== (1 - lt[i].out) * prod5[i][j];
            bits[i*256 + j] <== lt[i].out * bytes2bits[i][j] + prod6[i][j] ;
        } 
    }

    /* 
    Constraint Reduction Tip : Combine the process of bytes_to_bits & concatenated_bits
    */

    /* <------ Compute the SHA Compression Blocks for all 6 blocks -------> */

    var nBlocks = 6; // Max Blocks with input of 10 entries
    component ha0 = H(0);
    component hb0 = H(1);
    component hc0 = H(2);
    component hd0 = H(3);
    component he0 = H(4);
    component hf0 = H(5);
    component hg0 = H(6);
    component hh0 = H(7);

    component sha256compression[nBlocks];

    for (var i=0; i<nBlocks; i++) {

        sha256compression[i] = Sha256compression() ;

        if (i==0) {
            for (var k=0; k<32; k++ ) {
                sha256compression[i].hin[0*32+k] <== ha0.out[k];
                sha256compression[i].hin[1*32+k] <== hb0.out[k];
                sha256compression[i].hin[2*32+k] <== hc0.out[k];
                sha256compression[i].hin[3*32+k] <== hd0.out[k];
                sha256compression[i].hin[4*32+k] <== he0.out[k];
                sha256compression[i].hin[5*32+k] <== hf0.out[k];
                sha256compression[i].hin[6*32+k] <== hg0.out[k];
                sha256compression[i].hin[7*32+k] <== hh0.out[k];
            }
        } else {
            for (var k=0; k<32; k++ ) {
                sha256compression[i].hin[32*0+k] <== sha256compression[i-1].out[32*0+31-k];
                sha256compression[i].hin[32*1+k] <== sha256compression[i-1].out[32*1+31-k];
                sha256compression[i].hin[32*2+k] <== sha256compression[i-1].out[32*2+31-k];
                sha256compression[i].hin[32*3+k] <== sha256compression[i-1].out[32*3+31-k];
                sha256compression[i].hin[32*4+k] <== sha256compression[i-1].out[32*4+31-k];
                sha256compression[i].hin[32*5+k] <== sha256compression[i-1].out[32*5+31-k];
                sha256compression[i].hin[32*6+k] <== sha256compression[i-1].out[32*6+31-k];
                sha256compression[i].hin[32*7+k] <== sha256compression[i-1].out[32*7+31-k];
            }
        }
        for (var k=0; k<512; k++) {
            sha256compression[i].inp[k] <== bits[i*512+k];
        }
    }

    /* <------ Find the SHA compression Hash for the block of given length -------> */

    signal total_bits <== 256 * length;
    signal n <-- (total_bits + 576)\512;

    // Range Check for n
    component lessthan = LessThan(4);
    lessthan.in[0] <== 0;
    lessthan.in[1] <== n;

    component greaterthan = LessThan(4);
    greaterthan.in[0] <== n;
    greaterthan.in[1] <== 7;

    signal rem <-- (total_bits + 576) % 512;

    // Range Check for rem
    component lessthan512 = LessThan(10);
    lessthan512.in[0] <== 0;
    lessthan512.in[1] <== n;

    n * 512 + rem === total_bits + 576;

    component isEqual2n[6];

    for(var i=0; i<6; i++){
        isEqual2n[i] = IsEqual();
        isEqual2n[i].in[0] <== i + 1;
        isEqual2n[i].in[1] <== n;
    }

    signal hashbits[256];
    signal sum[6][256];

    for(var i=0; i<6; i++){
        for(var j=0; j<256; j++){
            sum[i][j] <== isEqual2n[i].out * sha256compression[i].out[j];
        }
    }
    
    for(var i=0; i<256; i++){
        hashbits[i] <== sum[0][i] + sum[1][i] + sum[2][i] + sum[3][i] + sum[4][i] + sum[5][i];
    }

    component b2num = Bits2Num(256);
    b2num.in <== hashbits;
    hash <== b2num.out;

}

component main { public [ input_bytes, length  ] } = VariableLengthHash();

/* INPUT = {
    "input_bytes": [
        ["155","27","72","217","112","216","250","208","157","235","226","113","109","41","165","99","244","210","27","101","232","42","165","85","66","208","220","11","16","8","68","54"], 
        ["46","2","86","202","227","28","150","177","138","109","92","238","235","171","249","134","94","168","134","67","220","229","59","160","98","41","85","11","15","226","67","173"], 
        ["155","80","235","144","195","28","98","58","75","57","203","87","148","251","104","142","149","245","73","25","214","71","147","153","7","205","224","41","214","13","183","176"],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        ["155","27","72","217","112","216","250","208","157","235","226","113","109","41","165","99","244","210","27","101","232","42","165","85","66","208","220","11","16","8","68","54"], 
        ["46","2","86","202","227","28","150","177","138","109","92","238","235","171","249","134","94","168","134","67","220","229","59","160","98","41","85","11","15","226","67","173"], 
        ["155","80","235","144","195","28","98","58","75","57","203","87","148","251","104","142","149","245","73","25","214","71","147","153","7","205","224","41","214","13","183","176"],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        ["155","27","72","217","112","216","250","208","157","235","226","113","109","41","165","99","244","210","27","101","232","42","165","85","66","208","220","11","16","8","68","54"], 
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    ],
    "length": "10"
} */