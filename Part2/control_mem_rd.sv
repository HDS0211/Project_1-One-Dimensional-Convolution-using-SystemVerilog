// ------------------------------------------------------------------
// Author: Hemil Shah
// Module: control_mem_rd
// Control unit for address generation during memory read ops
// ------------------------------------------------------------------

module control_mem_rd #(
  parameter DATA_N      = 8,
  parameter LG_DATA_N   = 3,
  parameter FILTER_N    = 4,
  parameter LG_FILTER_N = 2,
  parameter LG_CONV_N   = 3
)(
  input                     clk,
  input                     reset,

  input                     in_compute,
  input                     incr_comp_cyc,
  input                     mem_wr_state,
  input [LG_CONV_N-1:0]     compute_cyc,

  output [LG_DATA_N-1:0]    rd_addr_x,

  output [LG_FILTER_N-1:0]  rd_addr_f
);

  // ------------------------------------------------------------------
  // Internal Wires and Registers
  // ------------------------------------------------------------------
  wire  [LG_DATA_N-1:0]   rd_addr_x_t0;
  wire  [LG_FILTER_N-1:0] rd_addr_f_t0;

  wire  [LG_DATA_N-1:0]   rd_addr_x_init;
  
  reg   [LG_DATA_N-1:0]   rd_addr_x_q;
  reg   [LG_FILTER_N-1:0] rd_addr_f_q;

  reg                     incr_comp_cyc_q;

  // ------------------------------------------------------------------
  // Address for X-vectors
  // ------------------------------------------------------------------
  always_ff @(posedge clk or posedge reset)
    if (reset) begin
      rd_addr_x_q <= {LG_DATA_N{1'b0}};
    end else if (mem_wr_state) begin
      rd_addr_x_q <= {LG_DATA_N{1'b0}};
    end else if (in_compute | incr_comp_cyc_q) begin
      rd_addr_x_q <= rd_addr_x_t0;
    end

  // ------------------------------------------------------------------
  // Address for F-vectors
  // ------------------------------------------------------------------
  always_ff @(posedge clk or posedge reset)
    if (reset) begin
      rd_addr_f_q <= {LG_FILTER_N{1'b0}};
    end else if (mem_wr_state) begin
      rd_addr_f_q <= {LG_FILTER_N{1'b0}};
    end else if (in_compute | incr_comp_cyc_q) begin
      rd_addr_f_q <= rd_addr_f_t0;
    end

  // ------------------------------------------------------------------
  // Flope for increment cycle
  // ------------------------------------------------------------------
  always_ff @(posedge clk or posedge reset)
    if (reset) begin
      incr_comp_cyc_q <= 1'b0;
    end else begin
      incr_comp_cyc_q <= incr_comp_cyc;
    end

  // ------------------------------------------------------------------
  // Comnbinational Logic
  // ------------------------------------------------------------------
  assign rd_addr_x_t0 = incr_comp_cyc_q ? rd_addr_x_init :
                        in_compute ?
                        rd_addr_x_q + {{LG_DATA_N-1{1'b0}}, 1'b1} :
                        rd_addr_x_q;

  assign rd_addr_f_t0 = incr_comp_cyc_q ? {LG_FILTER_N{1'b0}}:
                        in_compute ?
                        rd_addr_f_q + {{LG_FILTER_N-1{1'b0}}, 1'b1} :
                        rd_addr_f_q;

  assign rd_addr_x_init = {{LG_DATA_N-LG_CONV_N{1'b0}}, compute_cyc};

  // ------------------------------------------------------------------
  // Output Assignments
  // ------------------------------------------------------------------
  assign rd_addr_x = rd_addr_x_q;
  assign rd_addr_f = rd_addr_f_q;


endmodule

