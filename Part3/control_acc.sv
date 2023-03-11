// ------------------------------------------------------------------
// Author: Hemil Shah
// Module: control_acc
// Control unit for the Accumulator Register
// ------------------------------------------------------------------

module control_acc #(
  parameter FILTER_N    = 4,
  parameter LG_FILTER_N = 2
)(
  input         clk,
  input         reset,

  input         in_compute,
  input         curr_comp_done,

  output        clear_acc,
  output        en_acc,

  output        done_acc
);

  // ------------------------------------------------------------------
  // Internal Parameters
  // ------------------------------------------------------------------
  localparam [LG_FILTER_N-1:0] COMPUTE_CYCLES = {LG_FILTER_N{1'b1}};

  // ------------------------------------------------------------------
  // Internal Wires and Registers
  // ------------------------------------------------------------------
  wire [LG_FILTER_N-1:0]  cyc_cnt;
  wire                    cnt_en;

  reg                     cnt_en_q;
  reg  [LG_FILTER_N-1:0]  cyc_cnt_q;

  // ------------------------------------------------------------------
  // Counters
  // ------------------------------------------------------------------
  always_ff @(posedge clk or posedge reset)
    if (reset) begin
      cyc_cnt_q <= {LG_FILTER_N{1'b0}};
    end else if (done_acc) begin
      cyc_cnt_q <= {LG_FILTER_N{1'b0}};
    end else begin
      cyc_cnt_q <= cyc_cnt;
    end

  // ------------------------------------------------------------------
  // Count enable flop
  // ------------------------------------------------------------------
  always_ff @(posedge clk or posedge reset)
    if (reset) begin
      cnt_en_q <= 1'b0;
    end else begin
      cnt_en_q <= cnt_en;
    end

  // ------------------------------------------------------------------
  // Comnbinational Logic
  // ------------------------------------------------------------------
  assign cnt_en = in_compute;
  assign cyc_cnt = cnt_en ? cyc_cnt_q + {{LG_FILTER_N-1{1'b0}}, 1'b1} : cyc_cnt_q;

  // ------------------------------------------------------------------
  // Output Assignments
  // ------------------------------------------------------------------
  assign done_acc = (cyc_cnt_q == COMPUTE_CYCLES);
  assign clear_acc = ~cnt_en & curr_comp_done;
  assign en_acc    = cnt_en_q;

endmodule
