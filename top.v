module top(
    input clk,
    input reset_n,
    
    input  		   	lpc_clk,
    input  		   	lpc_lreset_n,
    input  [3:0]   	lpc_lad,
    input  		   	lpc_lframe_n,
    
    input 		 	com_debug_rx,
    
    output [6:0]   	seg7_segment,
    output [1:0]   	seg7_common
);

localparam CLOCK_FREQENCY = 25_000_000;

//
// lpc debug 
//
wire 		lpc_code_sync;
wire [7:0] 	lpc_code;
diagcard_generic_lpc lpcdebug_inst (
  	.lpc_clk		(lpc_clk),
    .lpc_lreset_n	(lpc_lreset_n),
    .lpc_lad		(lpc_lad),
    .lpc_lframe_n	(lpc_lframe_n),
    
    .code 			(lpc_code),
    .code_sync		(lpc_code_sync)
);

reg [1:0]  lpc_code_valid_sync;
always @(posedge clk) begin // cross clk domain
    if (reset_n) begin
    	lpc_code_valid_sync[1:0] = 2'b00;
    end else begin
    	lpc_code_valid_sync[0] <= lpc_code_sync;
    	lpc_code_valid_sync[1] <= lpc_code_valid_sync[0];
    end
end

//
// com debug (ASUS)
//
wire [7:0] 	com_code;
wire		com_code_sync;
thcattus_uart_rx #(
    .DATA_WIDTH	(1),
	.CLOCK_FREQ (CLOCK_FREQENCY),
    .BAUD_RATE	(115200)
) comdebug_inst (
    .axis_aclk		(clk),
    .axis_arestn	(reset_n),
    .axis_tvalid	(com_code_sync),
    .axis_tready	(1'b1),
    .axis_tdata		(com_code),
    
    .uart_rx 		(com_debug_rx)
);

//
// display logic
//
reg [7:0] display_code;
thcattus_seg7_display_driver #(
    .PART_NUMBER(2),
    .CLOCK_FREQ (CLOCK_FREQENCY),
    .REFESH_RATE(10000)
) driver (
    .clk		(clk),
    .reset_n	(reset_n),
    
    .data		(display_code),
    
    .segment 	(seg7_segment),
    .common     (seg7_common)
);
always @(posedge clk) begin
	if (lpc_code_valid_sync[0] ^ lpc_code_valid_sync[1]) begin
    	display_code <= lpc_code;
   	end else if (com_code_sync) begin
       	display_code <= com_code_sync;
    end
end

endmodule