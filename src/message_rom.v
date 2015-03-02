module message_rom (
    input clk,
    input [4:0] addr,
    output [7:0] data
);
 
wire [7:0] rom_data [29:0];
 
assign rom_data[0] = "\r"; // addr 00000
assign rom_data[1] = "\n";
assign rom_data[2] = " ";
assign rom_data[3] = ",";
assign rom_data[4] = "o";
assign rom_data[5] = " ";
assign rom_data[6] = "W";
assign rom_data[7] = "o";
assign rom_data[8] = "r";
assign rom_data[9] = "l";
assign rom_data[10] = "d";
assign rom_data[11] = "!";
assign rom_data[12] = "\r";
assign rom_data[13] = "\n";  // addr 01101

assign rom_data[16] = "\r";  // addr 10000
assign rom_data[17] = "\n";
assign rom_data[18] = " ";
assign rom_data[19] = ",";
assign rom_data[20] = "d";
assign rom_data[21] = "b";
assign rom_data[22] = "y";
assign rom_data[23] = " ";
assign rom_data[24] = "n";
assign rom_data[25] = "o";
assign rom_data[26] = "w";
assign rom_data[27] = ".";
assign rom_data[28] = "\r";
assign rom_data[29] = "\n"; // addr 11101
 
reg [7:0] data_d, data_q;
 
assign data = data_q;
 
always @(*) begin
    if (addr[3:0] > 4'd13)
        data_d = " ";
    else
        data_d = rom_data[addr];
end
 
always @(posedge clk) begin
    data_q <= data_d;
end
 
endmodule
