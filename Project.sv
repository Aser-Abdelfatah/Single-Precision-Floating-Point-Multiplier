module multiplier(input logic [31:0] a,
		input logic [31:0]b,
		output logic [31:0]c);

// extract the sign bit and calculate the sign bit of the output 
logic a_sign, b_sign, c_sign;
assign a_sign = a[31];
assign b_sign = b[31];
// sign bit of the output is the sign of a xor the sign of b
assign c_sign = a_sign ^ b_sign;


// extract the exponent bits and calculate the exponent bits of the output
logic [7:0] a_exponent;
logic [7:0] b_exponent;
logic [7:0] c_exponent;
logic [7:0] a_temp_exponent;
logic [7:0] b_temp_exponent;
logic [7:0] c_temp_exponent;
// remove the bias from the exponents of the inputs to complete the addition of the exponents
assign a_temp_exponent = a[30:23] - 127;
assign b_temp_exponent = b[30:23] - 127;
// calculate the exponent of the output by adding the exponents of the inputs together 
assign c_temp_exponent = b_temp_exponent + a_temp_exponent;
// add the bias to the exponent of the output
assign c_exponent = c_temp_exponent + 127;


// extract the mantissa of the inputs
logic[23:0] a_mantissa, b_mantissa;
logic[47:0] temp_mantissa;
logic[47:0] temp_mantissa_2;
logic[7:0] c_exponent_2;
logic one;
assign one = 1'b1;
assign a_mantissa = {one, a[22:0]};
assign b_mantissa = {one, b[22:0]};
assign temp_mantissa = a_mantissa * b_mantissa;
always_comb
begin
if(temp_mantissa[47]) begin
// adjust the exponent of the output depending on how many one's before the radix point
// if there are 11 before the radix point, increase the exponent by 1. Otherwise, the exponent is the same.
 c_exponent_2 = c_exponent + 1;
// shift the result to keep only 24 bits, 23 of them form the mantissa, and the most significant bit represent the 1 before the radix point.
 temp_mantissa_2 = temp_mantissa >> 24;
end
else begin
 c_exponent_2 = c_exponent; 
 temp_mantissa_2 = temp_mantissa[46:0] >> 23;
end
end
logic [22:0] c_mantissa;
// extract the 23 bits of the mantissa
assign c_mantissa = temp_mantissa_2[22:0];


// combine the sign, the exponent, and the mantissa together
assign c = {c_sign, c_exponent_2, c_mantissa};
endmodule



module testbench1();
 logic clk, reset;
 logic [31:0]a1;
 logic [31:0]b1;
 logic [31:0]c1;
 logic [31:0]cexpected;
 logic [31:0] vectornum, errors;
 logic [95:0] testvectors[10000:0];
 // instantiate device under test
 multiplier dut(a1, b1, c1);
  // generate clock
 always
 begin
 clk = 1; #5; clk = 0; #5;
 end
 // at start of test, load vectors
 // and pulse reset
 initial
 begin
 $readmemb("test_vectors.tv", testvectors);
 vectornum = 0; errors = 0;
 reset = 1; #22; reset = 0;
 end
 // apply test vectors on rising edge of clk
 always @(posedge clk)
 begin
 #1; {a1, b1, cexpected} = testvectors[vectornum];
 end
 // check results on falling edge of clk
 always @(negedge clk)
 if (~reset) begin // skip during reset
 if (c1 !== cexpected) begin // check result
 $display("Error: inputs = %b", {a1, b1});
 $display(" outputs = %b (%b expected)", c1, cexpected);
 errors = errors + 1;
 end
 vectornum = vectornum + 1;
 if (testvectors[vectornum] === 96'bx) begin
 $display("%d tests completed with %d errors",
 vectornum, errors);
 $stop;
 end
 end
endmodule
