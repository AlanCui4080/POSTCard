`timescale 1ns/1ps

module top_tb;

reg clk;
reg reset_n;

reg lpc_clk;
reg lpc_lreset_n;
reg lpc_lframe_n;
reg [3:0] lpc_lad_drive;
wire [3:0] lpc_lad;

wire [6:0] seg7_segment;
wire [1:0] seg7_common;
wire [7:0] debug_led;

// 拉线 inout
assign lpc_lad = lpc_lad_drive;

top uut (
    .clk            (clk),
    .reset_n        (reset_n),

    .seg7_segment   (seg7_segment),
    .seg7_common    (seg7_common),

    .lpc_clk        (lpc_clk),
    .lpc_lreset_n   (lpc_lreset_n),
    .lpc_lad        (lpc_lad),
    .lpc_lframe_n   (lpc_lframe_n),

    .debug_led      (debug_led)
);

// 生成系统时钟、LPC时钟
always #20  clk = ~clk;       // 100 MHz
always #15 lpc_clk = ~lpc_clk; // 50 MHz LPC


initial begin
    // 初始值
    clk = 0;
    lpc_clk = 0;

    reset_n = 0;
    lpc_lreset_n = 0;
    lpc_lframe_n = 1;
    lpc_lad_drive = 4'h1;

    // release reset
    #100 reset_n = 1;
    #50 lpc_lreset_n = 1;

    #1000

    // =============================
    // LPC Transaction: WRITE 0x0080 = 0x5A
    // =============================

    // START
    @(negedge lpc_clk);
    lpc_lframe_n = 0;  // start cycle
    lpc_lad_drive = 4'h0;


    @(negedge lpc_clk);
    lpc_lframe_n = 1;  
    lpc_lad_drive = 4'b0010; 
    
    @(negedge lpc_clk);
    lpc_lad_drive = 4'h0; 
    
    @(negedge lpc_clk);
    lpc_lad_drive = 4'h0; 

    @(negedge lpc_clk);
    lpc_lad_drive = 4'h8; 

    @(negedge lpc_clk);
    lpc_lad_drive = 4'h0; 

    @(negedge lpc_clk);
    lpc_lad_drive = 4'h2; 

    @(negedge lpc_clk);
    lpc_lad_drive = 4'h0; 

    @(negedge lpc_clk);
    lpc_lad_drive = 4'hf;
    @(negedge lpc_clk);
    @(negedge lpc_clk);
    @(negedge lpc_clk);
    @(negedge lpc_clk);
    @(negedge lpc_clk);
    @(negedge lpc_clk);
    @(negedge lpc_clk);

    // ABORT / END
    @(negedge lpc_clk);
    lpc_lframe_n = 0;
    lpc_lad_drive = 4'hf;

    @(negedge lpc_clk);
    lpc_lframe_n = 0;
    lpc_lad_drive = 4'hf;

    @(negedge lpc_clk);
    lpc_lframe_n = 0;
    lpc_lad_drive = 4'hf;

    @(negedge lpc_clk);
    lpc_lframe_n = 0;
    lpc_lad_drive = 4'hf;

    @(negedge lpc_clk);
    lpc_lframe_n = 1;
    lpc_lad_drive = 4'h0;

    #100

    $display("Simulation Done.");
    $stop;
end

endmodule
