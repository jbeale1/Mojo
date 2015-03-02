// convert a 4-bit binary word to the hex value as an 8-bit ASCII character

module bin2hex (
   input [3:0] in,
	output reg [7:0] out
);

always @(in)
begin
 case ( in )
  4'h0 : out = 7'h30;
  4'h1 : out = 7'h31;
  4'h2 : out = 7'h32;
  4'h3 : out = 7'h33;
  4'h4 : out = 7'h34;
  4'h5 : out = 7'h35;
  4'h6 : out = 7'h36;
  4'h7 : out = 7'h37;
  4'h8 : out = 7'h38;
  4'h9 : out = 7'h39;
  4'ha : out = "A";
  4'hb : out = "B";
  4'hc : out = "C";
  4'hd : out = "D";
  4'he : out = "E";
  4'hf : out = "F";
 endcase
end

endmodule 