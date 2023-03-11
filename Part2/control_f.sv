// ------------------------------------------------------------------
// Author: Hemil Shah
// Module: control_f
// Control unit for the Filter input (F-vectors)
// ------------------------------------------------------------------

module control_f #(
  parameter FILTER_N      = 8,
  parameter LG_FILTER_N   = 3
)(
  input                       clk,
  input                       reset,

  input                       s_valid_f,
  output [LG_FILTER_N - 1:0]  addr_f,
  output                      wr_en_f,
  output                      s_ready_f,

  input                       mem_wr_state,
  input                       mem_wr_done,

  output                      done_f
);

  // ------------------------------------------------------------------
  // Internal Parameters
  // ------------------------------------------------------------------
  localparam [LG_FILTER_N-1:0] MAX_ADDR = {LG_FILTER_N{1'b1}};

  // ------------------------------------------------------------------
  // Internal Wires and Registers
  // ------------------------------------------------------------------
  wire  [LG_FILTER_N-1:0] addr;
  wire                    incr_addr;

  reg   [LG_FILTER_N-1:0] addr_q;
  reg                     done_f_q;

  // ------------------------------------------------------------------
  // Address flops
  // ------------------------------------------------------------------
  always_ff @(posedge clk or posedge reset)
    if (reset) begin
      addr_q <= {LG_FILTER_N{1'b0}};
    end else begin
      addr_q <= addr;
    end

  // ------------------------------------------------------------------
  // Done register
  // ------------------------------------------------------------------
  always_ff @(posedge clk or posedge reset)
    if (reset) begin
      done_f_q <= 1'b0;
    end else begin
      done_f_q <= done_f;
    end

  // ------------------------------------------------------------------
  // Comnbinational Logic
  // ------------------------------------------------------------------
  assign incr_addr = (s_ready_f & ~done_f) | mem_wr_done;
  assign addr = incr_addr ? addr_q + {{LG_FILTER_N-1{1'b0}}, 1'b1} : addr_q;

  // ------------------------------------------------------------------
  // Output Assignments
  // ------------------------------------------------------------------
  assign addr_f     = addr_q;
  assign wr_en_f    = s_valid_f & mem_wr_state & ~done_f_q;
  assign s_ready_f  = s_valid_f & mem_wr_state & ~done_f_q;
  assign done_f     = ((addr_q == MAX_ADDR) & s_valid_f) |
                      (done_f_q & (addr_q == MAX_ADDR));

endmodule

