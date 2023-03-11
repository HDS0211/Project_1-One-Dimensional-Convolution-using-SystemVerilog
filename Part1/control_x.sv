// ------------------------------------------------------------------
// Author: Hemil Shah
// Module: control_x
// Control unit for the Data input (X-vectors)
// ------------------------------------------------------------------

module control_x #(
  parameter DATA_N      = 8,
  parameter LG_DATA_N   = 3
)(
  input                       clk,
  input                       reset,

  input                       s_valid_x,
  output [LG_DATA_N - 1:0]    addr_x,
  output                      wr_en_x,
  output                      s_ready_x,

  input                       mem_wr_state,
  input                       mem_wr_done,

  output                      done_x
);

  // ------------------------------------------------------------------
  // Internal Parameters
  // ------------------------------------------------------------------
  localparam [LG_DATA_N-1:0] MAX_ADDR = {LG_DATA_N{1'b1}};

  // ------------------------------------------------------------------
  // Internal Wires and Registers
  // ------------------------------------------------------------------
  wire  [LG_DATA_N-1:0] addr;
  wire                  incr_addr;

  reg   [LG_DATA_N-1:0] addr_q;
  reg                   done_x_q;

  // ------------------------------------------------------------------
  // Address flops
  // ------------------------------------------------------------------
  always_ff @(posedge clk or posedge reset)
    if (reset) begin
      addr_q <= {LG_DATA_N{1'b0}};
    end else begin
      addr_q <= addr;
    end

  // ------------------------------------------------------------------
  // Done register
  // ------------------------------------------------------------------
  always_ff @(posedge clk or posedge reset)
    if (reset) begin
      done_x_q <= 1'b0;
    end else if (s_valid_x) begin
      done_x_q <= done_x;
    end

  // ------------------------------------------------------------------
  // Comnbinational Logic
  // ------------------------------------------------------------------
  assign incr_addr = (s_ready_x & ~done_x) | mem_wr_done;
  assign addr = incr_addr ? addr_q + {{LG_DATA_N-1{1'b0}}, 1'b1} : addr_q;

  // ------------------------------------------------------------------
  // Output Assignments
  // ------------------------------------------------------------------
  assign addr_x     = addr_q;
  assign wr_en_x    = s_valid_x & mem_wr_state & ~done_x_q;
  assign s_ready_x  = s_valid_x & mem_wr_state & ~done_x_q;
  assign done_x     = ((addr_q == MAX_ADDR) & s_valid_x) |
                      (done_x_q & (addr_q == MAX_ADDR));

endmodule
