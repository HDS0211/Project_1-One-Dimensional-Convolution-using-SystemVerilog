// ------------------------------------------------------------------
// Author: Hemil Shah
// Module: conv_128_32
// Top module for the convolution system
// ------------------------------------------------------------------

module conv_128_32_opt (
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
  output signed [20:0]    m_data_out_y
);

  // ------------------------------------------------------------------
  // Internal Parameters
  // ------------------------------------------------------------------
  localparam DATA_N       = 128;
  localparam FILTER_N     = 32;
  localparam CONV_N       = DATA_N - FILTER_N + 1;
  localparam LG_DATA_N    = $clog2(DATA_N);
  localparam LG_FILTER_N  = $clog2(FILTER_N);
  localparam LG_CONV_N    = $clog2(CONV_N);

  // ------------------------------------------------------------------
  // Internal Wires and Registers
  // ------------------------------------------------------------------
  wire [LG_DATA_N-1:0]    addr_x0;
  wire [LG_FILTER_N-1:0]  addr_f0;
  wire                    wr_en_x0;
  wire                    wr_en_f0;

  wire                    clear_acc0;
  wire                    en_acc0;

  wire                    s_valid_x0;
  wire                    s_valid_f0;
  wire                    s_ready_x0;
  wire                    s_ready_f0;

  wire                    m_valid_y0;
  wire [20:0]             m_data_out_y0;

  wire [LG_DATA_N-1:0]    addr_x1;
  wire [LG_FILTER_N-1:0]  addr_f1;
  wire                    wr_en_x1;
  wire                    wr_en_f1;

  wire                    clear_acc1;
  wire                    en_acc1;

  wire                    s_valid_x1;
  wire                    s_valid_f1;
  wire                    s_ready_x1;
  wire                    s_ready_f1;

  wire                    m_valid_y1;
  wire [20:0]             m_data_out_y1;

  wire                    in_comp0;
  wire                    in_comp1;
  wire                    conv_done;
  wire                    conv_done0;
  wire                    conv_done1;
  reg                     conv_done_q;
  
  // ------------------------------------------------------------------
  // Datapath 0
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
      .addr_x       (addr_x0),
      .wr_en_x      (wr_en_x0),
      .s_data_f     (s_data_in_f),
      .addr_f       (addr_f0),
      .wr_en_f      (wr_en_f0),
      .clear_acc    (clear_acc0),
      .en_acc       (en_acc0),
      .m_data_out_y (m_data_out_y0)
  );

  // ------------------------------------------------------------------
  // Control 0
  // ------------------------------------------------------------------
  control #(
    .DATA_N       (DATA_N),
    .FILTER_N     (FILTER_N),
    .CONV_N       (CONV_N),
    .LG_DATA_N    (LG_DATA_N),
    .LG_FILTER_N  (LG_FILTER_N),
    .LG_CONV_N    (LG_CONV_N)
  ) CP0 (
      .clk              (clk),
      .reset            (reset),
      .s_valid_x        (s_valid_x0),
      .addr_x           (addr_x0),
      .wr_en_x          (wr_en_x0),
      .s_ready_x        (s_ready_x0),
      .s_valid_f        (s_valid_f0),
      .addr_f           (addr_f0),
      .wr_en_f          (wr_en_f0),
      .s_ready_f        (s_ready_f0),
      .clear_acc        (clear_acc0),
      .m_valid_y        (m_valid_y0),
      .m_ready_y        (m_ready_y),
      .en_acc           (en_acc0),
      .other_ct_in_comp (in_comp1),
      .conv_done        (conv_done0),
      .in_comp          (in_comp0)
  );

  // ------------------------------------------------------------------
  // Datapath 1
  // ------------------------------------------------------------------
  datapath #(
    .DATA_N       (DATA_N),
    .FILTER_N     (FILTER_N),
    .LG_DATA_N    (LG_DATA_N),
    .LG_FILTER_N  (LG_FILTER_N)
  ) DP1 (
      .clk          (clk),
      .reset        (reset),
      .s_data_x     (s_data_in_x),
      .addr_x       (addr_x1),
      .wr_en_x      (wr_en_x1),
      .s_data_f     (s_data_in_f),
      .addr_f       (addr_f1),
      .wr_en_f      (wr_en_f1),
      .clear_acc    (clear_acc1),
      .en_acc       (en_acc1),
      .m_data_out_y (m_data_out_y1)
  );

  // ------------------------------------------------------------------
  // Control 1
  // ------------------------------------------------------------------
  control #(
    .DATA_N       (DATA_N),
    .FILTER_N     (FILTER_N),
    .CONV_N       (CONV_N),
    .LG_DATA_N    (LG_DATA_N),
    .LG_FILTER_N  (LG_FILTER_N),
    .LG_CONV_N    (LG_CONV_N)
  ) CP1 (
      .clk              (clk),
      .reset            (reset),
      .s_valid_x        (s_valid_x1),
      .addr_x           (addr_x1),
      .wr_en_x          (wr_en_x1),
      .s_ready_x        (s_ready_x1),
      .s_valid_f        (s_valid_f1),
      .addr_f           (addr_f1),
      .wr_en_f          (wr_en_f1),
      .s_ready_f        (s_ready_f1),
      .clear_acc        (clear_acc1),
      .m_valid_y        (m_valid_y1),
      .m_ready_y        (m_ready_y),
      .en_acc           (en_acc1),
      .other_ct_in_comp (in_comp0),
      .conv_done        (conv_done1),
      .in_comp          (in_comp1)
  );

  always_ff @(posedge clk or posedge reset)
    if (reset) begin
      conv_done_q <= 1'b0;
    end else if (conv_done0 | conv_done1) begin
      conv_done_q <= conv_done;
    end

  assign conv_done = (conv_done0 | conv_done1) + conv_done_q;

  assign s_valid_x0 = ((conv_done_q | in_comp1) & ~in_comp0) ? s_valid_x : 1'b0;
  assign s_valid_f0 = ((conv_done_q | in_comp1) & ~in_comp0) ? s_valid_f : 1'b0;

  assign s_valid_x1 = ((~conv_done_q | in_comp0) & ~in_comp1) ? s_valid_x : 1'b0;
  assign s_valid_f1 = ((~conv_done_q | in_comp0) & ~in_comp1) ? s_valid_f : 1'b0;

  assign s_ready_x = s_ready_x0 | s_ready_x1;
  assign s_ready_f = s_ready_f0 | s_ready_f1;

  assign m_valid_y = m_valid_y0 | m_valid_y1;
  assign m_data_out_y = m_valid_y0 ? m_data_out_y0 : m_data_out_y1;

endmodule
