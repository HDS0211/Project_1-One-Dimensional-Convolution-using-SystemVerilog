// ------------------------------------------------------------------
// Author: Hemil Shah
// Module: conv_8_4
// Top module for the convolution system
// ------------------------------------------------------------------

module conv_8_4 (
  input                   clk,
  input                   reset,

  input                   s_valid_x,
  output                  s_ready_x,
  input signed [7:0]      s_data_in_x,

  input                   s_valid_f,
  output                  s_ready_f,
  input signed [7:0]      s_data_in_f,

  input                   m_ready_y,
  output                  m_valid_y,
  output signed [17:0]    m_data_out_y
);

  // ------------------------------------------------------------------
  // Internal Parameters
  // ------------------------------------------------------------------
  localparam DATA_N       = 8;
  localparam FILTER_N     = 4;
  localparam CONV_N       = DATA_N - FILTER_N + 1;
  localparam LG_DATA_N    = $clog2(DATA_N);
  localparam LG_FILTER_N  = $clog2(FILTER_N);
  localparam LG_CONV_N    = $clog2(CONV_N);

  // ------------------------------------------------------------------
  // Internal Wires and Registers
  // ------------------------------------------------------------------
  wire [LG_DATA_N-1:0]    addr_x;
  wire [LG_FILTER_N-1:0]  addr_f;
  wire                    wr_en_x;
  wire                    wr_en_f;

  wire                    clear_acc;
  wire                    en_acc;

  // ------------------------------------------------------------------
  // Datapath
  // ------------------------------------------------------------------
  datapath #(
    .DATA_N       (DATA_N),
    .FILTER_N     (FILTER_N),
    .LG_DATA_N    (LG_DATA_N),
    .LG_FILTER_N  (LG_FILTER_N)
  ) DP0 (
      .clk          (clk),
      .reset        (reset),
      .s_data_x     (s_data_in_x),
      .addr_x       (addr_x),
      .wr_en_x      (wr_en_x),
      .s_data_f     (s_data_in_f),
      .addr_f       (addr_f),
      .wr_en_f      (wr_en_f),
      .clear_acc    (clear_acc),
      .en_acc       (en_acc),
      .m_data_out_y (m_data_out_y)
  );

  // ------------------------------------------------------------------
  // Control
  // ------------------------------------------------------------------
  control #(
    .DATA_N       (DATA_N),
    .FILTER_N     (FILTER_N),
    .CONV_N       (CONV_N),
    .LG_DATA_N    (LG_DATA_N),
    .LG_FILTER_N  (LG_FILTER_N),
    .LG_CONV_N    (LG_CONV_N)
  ) CP0 (
      .clk          (clk),
      .reset        (reset),
      .s_valid_x    (s_valid_x),
      .addr_x       (addr_x),
      .wr_en_x      (wr_en_x),
      .s_ready_x    (s_ready_x),
      .s_valid_f    (s_valid_f),
      .addr_f       (addr_f),
      .wr_en_f      (wr_en_f),
      .s_ready_f    (s_ready_f),
      .clear_acc    (clear_acc),
      .m_valid_y    (m_valid_y),
      .m_ready_y    (m_ready_y),
      .en_acc       (en_acc)
  );

endmodule
