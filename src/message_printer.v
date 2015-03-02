
module message_printer (
    input clk,
    input rst,
    output [7:0] tx_data,
    output reg new_tx_data,
    input tx_busy,
    input [7:0] rx_data,
    input new_rx_data,
	 input sig_in
);

parameter COUNTSIZE = 32;  // word size of timer-counter
parameter COUNTSIZE2 = 16;  // word size of output-counter

localparam STATE_SIZE = 3;
localparam IDLE = 0,
           START_MESSAGE = 1,
           PRINT_MESSAGE = 2,
           PRINT_NUMBER = 3,
           RESET_IDX = 4,
           PRINT_COMMA = 5,
           PRINT_NUMBER2 = 6;
 
localparam MESSAGE_LEN = 2;  // # chars in output message string
localparam NIDX_MAX = 8; // how many hex digits of counter to send out
localparam NIDX2_MAX = 4; // how many hex digits of counter2 to send out
localparam MSB = (COUNTSIZE-1);  // fast counter MSB
localparam MSB2 = (COUNTSIZE2-1); // output word counter MSB
 
reg [STATE_SIZE-1:0] state_d, state_q;
reg [4:0] addr_d, addr_q;
reg [4:0] nidx_d, nidx_q;  // nybble index for hex value output

reg [MSB2:0] wcount_d = 16'h1234;  // word counter
reg [MSB2:0] wcount_q;  // output word counter 
reg [MSB:0] count_d, count_q;  // timer that counts up on every clock cycle
reg [MSB:0] ccap;  // capture register for timer 
reg [MSB:0] ccap_sr_q, ccap_sr_d; // shift register for hex value output
reg sig_start_q;
wire sig_start_d;

wire [7:0] tx_data_string;  // ASCII byte from message rom
// reg [7:0] tx_data_r;  // registered output of data byte
wire out_sel;  // control signal for output word mux
wire [7:0] hexword;  // 4 binary bits converted to ASCII hex character
wire start_p;  // start pulse signal

message_rom message_rom1_A (
    .clk(clk),
    .addr(addr_q),
    .data(tx_data_string)
); 


//assign tx_data_string = 8'd0;  // place-holder for message ROM

bin2hex bin2hex_A (
    .in(ccap_sr_q[MSB:(MSB-3)]),  // binary nybble in
	 .out(hexword)    // ASCII byte out
);

assign tx_data = (out_sel == 1'b1) ? tx_data_string : hexword;  // output byte select
assign out_sel = ((state_q == PRINT_NUMBER) || (state_q == PRINT_NUMBER2)) ? 1'b0 : 1'b1;  // control output
//assign sig_start_d = start_p;


edge_detect edge_d (   // rising edge detector
   .sig(sig_in),
   .clk(clk),
	.flag(sig_start_d)
 ); 
 
 
always @(*) begin
    state_d = state_q; // default values
    addr_d = addr_q;   // needed to prevent latches
	 count_d = count_q;
    new_tx_data = 1'b0;
	 ccap_sr_d = ccap_sr_q;
	 nidx_d = nidx_q;
	 wcount_d = wcount_q; // output word counter

    // tx_data_r = tx_data_string;

    case (state_q)
        IDLE: begin
            addr_d = 5'd0;
				nidx_d = 5'd0;
				if (sig_start_q == 1'b1)
                begin 
					   state_d = START_MESSAGE;				   
					 end
            if (new_rx_data && rx_data == "h")  // check for input char
                state_d = START_MESSAGE;
            if (new_rx_data && rx_data == "g")  // check for diff. char
				  begin
					 addr_d[4] = 1'b1;  // high-order bit selects 2nd message
                state_d = START_MESSAGE;
				  end
        end
        START_MESSAGE: begin  // extra state so 1st address set before xmit
				wcount_d = wcount_q + 1;  // increment count of words output
				state_d = PRINT_MESSAGE;
        end
        PRINT_MESSAGE: begin
		      ccap_sr_d = ccap;  // counter capture register value
            if (!tx_busy) begin
                new_tx_data = 1'b1;
                addr_d = addr_q + 1'b1;
                if (addr_q[3:0] == (MESSAGE_LEN-1))
                    state_d = PRINT_NUMBER;
            end
        end
		  PRINT_NUMBER: begin
            if (!tx_busy) begin
                new_tx_data = 1'b1;
  			       ccap_sr_d = {ccap_sr_q[MSB-4:0],4'b0}; // shift 4 bits left, 0-fill LSB's
			       nidx_d = nidx_q + 1'b1;  // nybble index
		          if (nidx_q == (NIDX_MAX-1))   // move on after all nybbles output
			         state_d = RESET_IDX;
            end
		  end
		  RESET_IDX: begin
	  				nidx_d = 5'd0;  // reset nybble pointer for hex output
					// NOTE! below line relies on wcount_q half # bits of ccap_sr_d
     		      ccap_sr_d = {wcount_q,wcount_q};  
					addr_d = 4'd3;  // character at this index is a comma
					state_d = PRINT_COMMA;  // move to next state
		  end
		  PRINT_COMMA: begin
            if (!tx_busy) begin
                new_tx_data = 1'b1; // character is ready to be sent out
			       state_d = PRINT_NUMBER2;
            end		  
		  end
		  PRINT_NUMBER2: begin
            if (!tx_busy) begin
                new_tx_data = 1'b1; // character ready to be sent out
  			       ccap_sr_d = {ccap_sr_q[MSB-4:0],4'b0}; // shift 4 bits left, 0-fill LSB's
			       nidx_d = nidx_q + 1'b1;  // nybble index
		          if (nidx_q == (NIDX2_MAX-1))   // move on after all nybbles output
			         state_d = IDLE;
            end
		  end
        default: state_d = IDLE;
    endcase
end
 
// synchronous part
// sets state_q, addr_q, counter_q, ccap
always @(posedge clk) begin
    if (rst) begin
        state_q <= IDLE;
        count_q <= 0;
		  ccap <= 0;
		  ccap_sr_q <= 0; // counter capture shift register
    end else begin
        state_q <= state_d;
		  count_q <= count_d + 1;
		  if (state_d == START_MESSAGE)
          ccap <= count_d;
    end
 
    sig_start_q <= sig_start_d;
    addr_q <= addr_d;
	 nidx_q <= nidx_d;  // nybble index for hex value output
	 ccap_sr_q <= ccap_sr_d;  // binary counter value shifts in 4-bit chunks
    wcount_q <= wcount_d; // output word counter
end
 
endmodule


