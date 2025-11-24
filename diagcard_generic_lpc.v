module diagcard_generic_lpc(
    input  		   lpc_clk,
    input  		   lpc_lreset_n,
    input  [3:0]   lpc_lad,
    input  		   lpc_lframe_n,
    
    output [7:0]   code,
    output 		   code_sync
);
reg code_sync_r;
assign code_sync = code_sync_r;

reg [15:0] io_addr;
reg [7:0]  io_0080_code;

localparam STATUS_LPC_IDLE  	   = 16'b0000_0000_0000_0000;
localparam STATUS_LPC_START 	   = 16'b0000_0000_0000_0001;
localparam STATUS_LPC_TYPE  	   = 16'b0000_0000_0000_0010;
localparam STATUS_LPC_ADDR0        = 16'b0000_0000_0000_0100;
localparam STATUS_LPC_ADDR1        = 16'b0000_0000_0000_1000;
localparam STATUS_LPC_ADDR2        = 16'b0000_0000_0001_0000;
localparam STATUS_LPC_ADDR3        = 16'b0000_0000_0010_0000;
localparam STATUS_LPC_DATA0        = 16'b0000_0000_0100_0000;
localparam STATUS_LPC_DATA1        = 16'b0000_0000_1000_0000;
localparam STATUS_LPC_WAIT_ABORT   = 16'b0000_0001_0000_0000;

reg [15:0] status_curr;
reg [15:0] status_next;

always @(posedge lpc_clk) begin
	if (!lpc_lreset_n) begin
	    status_curr <= STATUS_LPC_IDLE;
    end else begin
    	status_curr <= status_next;
    end
end

always @(*) begin
	case (status_curr)
    	STATUS_LPC_IDLE: begin
        	status_next = lpc_lframe_n == 1 ? STATUS_LPC_START : status_curr;
        end
        STATUS_LPC_START: begin
        	status_next = lpc_lframe_n == 0 && lpc_lad == 4'b0000 ? STATUS_LPC_TYPE : status_curr;
        end
        STATUS_LPC_TYPE: begin
        	status_next = lpc_lad == 4'b0010 ? STATUS_LPC_ADDR0 : status_curr; // 0010: I/O Write
        end
        STATUS_LPC_ADDR0,
        STATUS_LPC_ADDR1,
        STATUS_LPC_ADDR2,
        STATUS_LPC_ADDR3: begin
        	status_next = lpc_lframe_n == 1 ? status_curr << 1 : STATUS_LPC_IDLE;
        end
        STATUS_LPC_DATA0: begin
        	status_next = (io_addr >= 16'h0080 && io_addr <= 16'h0083) ? STATUS_LPC_DATA1 : STATUS_LPC_IDLE; // 0x0080: POST code address
        end
        STATUS_LPC_DATA1: begin // we excepted a abort here so wait for abort
        	status_next = lpc_lframe_n == 1 ? STATUS_LPC_WAIT_ABORT : STATUS_LPC_IDLE;
        end
        STATUS_LPC_WAIT_ABORT: begin // wait for resume
	        status_next = lpc_lframe_n == 0 ? STATUS_LPC_IDLE : status_curr;
        end
    endcase
end

always @(posedge lpc_clk) begin
	if (!lpc_lreset_n) begin
        io_addr       <= 16'b0;
        io_0080_code  <= 8'hFF;
        code_sync_r   <= 1'b1;
    end else begin
    	case (status_curr)
        	STATUS_LPC_IDLE,
            STATUS_LPC_START,
            STATUS_LPC_TYPE: begin
            	// nothing to do
            end
            STATUS_LPC_ADDR0: begin
            	io_addr[15:12] <= lpc_lad;
            end
            STATUS_LPC_ADDR1: begin
            	io_addr[11:8]  <= lpc_lad;
            end
            STATUS_LPC_ADDR2: begin
            	io_addr[7:4]   <= lpc_lad;
            end
            STATUS_LPC_ADDR3: begin
            	io_addr[3:0]   <= lpc_lad;
            end
            STATUS_LPC_DATA0: begin
            	io_0080_code[7:4] <= lpc_lad;
            end
            STATUS_LPC_DATA1: begin
            	io_0080_code[3:0] <= lpc_lad;
            end
            STATUS_LPC_WAIT_ABORT: begin
            	code_sync_r <= ~code_sync_r;
            end
        endcase	
    end
end

endmodule