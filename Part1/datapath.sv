// ------------------------------------------------------------------
// Author: Hemil Shah
// Module: datapath
// Datapath for the convolution system
// ------------------------------------------------------------------

module datapath #(
  parameter DATA_N      = 8,
  parameter FILTER_N    = 4,
  parameter LG_DATA_N   = 3,
  parameter LG_FILTER_N = 2
)(
  input                     clk,
  input                     reset,

  input signed [7:0]        s_data_x,
  input [LG_DATA_N - 1:0]   addr_x,
  input                     wr_en_x,

  input signed [7:0]        s_data_f,
  input [LG_FILTER_N - 1:0] addr_f    ,
  input                     wr_en_f,

  input                     clear_acc,
  input                     en_acc,

  output signed [17:0]      m_data_out_y
);

  // ------------------------------------------------------------------
  // Internal Wires and Registers
  // ------------------------------------------------------------------
  wire signed [7:0]   mem_data_x;
  wire signed [7:0]   mem_data_f;

  wire signed [15:0]  mult_data;

  wire  [17:0]        acc_data;

  // ------------------------------------------------------------------
  // Data Memory
  // ------------------------------------------------------------------
  memory #(
    .WIDTH    (8),
    .SIZE     (DATA_N),
    .LOGSIZE  (LG_DATA_N)
  ) DATA_MEM (
    .clk        (clk),
    .data_in    (s_data_x),
    .data_out   (mem_data_x),
    .addr       (addr_x),
    .wr_en      (wr_en_x)
  );

  // ------------------------------------------------------------------
  // Filter Memory
  // ------------------------------------------------------------------
  memory #(
    .WIDTH    (8),
    .SIZE     (FILTER_N),
    .LOGSIZE  (LG_FILTER_N)
  ) FILTER_MEM (
    .clk        (clk),
    .data_in    (s_data_f),
    .data_out   (mem_data_f),
    .addr       (addr_f),
    .wr_en      (wr_en_f)
  );

  // ------------------------------------------------------------------
  // Accumulator
  // ------------------------------------------------------------------
  accumulator ACC (
    .clk          (clk),
    .reset        (reset),
    .addr_data_a  (mult_data),
    .clear_acc    (clear_acc),
    .en_acc       (en_acc),
    .acc_data_o   (acc_data)
  );

  // ------------------------------------------------------------------
  // Comnbinational Logic for MAC unit
  // ------------------------------------------------------------------
  assign mult_data = $signed(mem_data_x[7:0]) * $signed(mem_data_f[7:0]);

  // ------------------------------------------------------------------
  // Output assignments
  // ------------------------------------------------------------------
  assign m_data_out_y = acc_data;

endmodule
