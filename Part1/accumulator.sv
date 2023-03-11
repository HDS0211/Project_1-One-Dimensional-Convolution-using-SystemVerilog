// ------------------------------------------------------------------
// Author: Hemil Shah
// Module: accumulator
// Generic module of an adder plus a register
// ------------------------------------------------------------------

module accumulator (
  input         clk,
  input         reset,

  input [15:0]  addr_data_a,

  input         clear_acc,
  input         en_acc,

  output [17:0] acc_data_o
);

  // ------------------------------------------------------------------
  // Internal Wires and Registers
  // ------------------------------------------------------------------
  wire [17:0] addr_sum;
  wire [17:0] acc_data;

  reg  [17:0] acc_data_q;

  // ------------------------------------------------------------------
  // Comnbinational Logic for accumulator
  // ------------------------------------------------------------------
  assign addr_sum[17:0] = {{2{addr_data_a[15]}}, addr_data_a} + acc_data_q;
  assign acc_data[17:0] = addr_sum[17:0];

  // ------------------------------------------------------------------
  // Register for accumulator
  // ------------------------------------------------------------------
  always @(posedge clk or posedge reset)
    if (reset) begin
      acc_data_q[17:0] <= 18'h0;
    end else if (clear_acc) begin
      acc_data_q[17:0] <= 18'h0;
    end else if (en_acc) begin
      acc_data_q[17:0] <= acc_data;
    end

  // ------------------------------------------------------------------
  // Output assignments
  // ------------------------------------------------------------------
  assign acc_data_o = acc_data_q;

endmodule
