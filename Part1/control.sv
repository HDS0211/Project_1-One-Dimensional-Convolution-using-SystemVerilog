// ------------------------------------------------------------------
// Author: Hemil Shah
// Module: control
// Control unit for the convolution system
// ------------------------------------------------------------------

module control #(
  parameter DATA_N      = 8,
  parameter LG_DATA_N   = 3,
  parameter FILTER_N    = 4,
  parameter LG_FILTER_N = 2,
  parameter CONV_N      = 5,
  parameter LG_CONV_N   = 3
)(
  input                       clk,
  input                       reset,

  input                       s_valid_x,
  output [LG_DATA_N - 1:0]    addr_x,
  output                      wr_en_x,
  output                      s_ready_x,

  input                       s_valid_f,
  output [LG_FILTER_N - 1:0]  addr_f,
  output                      wr_en_f,
  output                      s_ready_f,

  output                      m_valid_y,
  input                       m_ready_y,

  output                      clear_acc,
  output                      en_acc
);

  // ------------------------------------------------------------------
  // Internal Parameters
  // ------------------------------------------------------------------
  localparam [2:0] CT_IDLE     = 3'b000;
  localparam [2:0] CT_MEM_WR   = 3'b001;
  localparam [2:0] CT_IN_COMP  = 3'b010;
  localparam [2:0] CT_INCR_CYC = 3'b011;
  localparam [2:0] CT_DONE     = 3'b100;
  localparam [2:0] CT_WAIT     = 3'b101;

  // ------------------------------------------------------------------
  // Internal Wires and Registers
  // ------------------------------------------------------------------
  reg  [2:0]              cntrl_state;
  reg  [2:0]              cntrl_state_q;

  wire [LG_DATA_N-1:0]    int_addr_x;
  wire                    int_wr_en_x;

  wire [LG_DATA_N-1:0]    rd_addr_x;

  wire [LG_FILTER_N-1:0]  int_addr_f;
  wire                    int_wr_en_f;

  wire [LG_FILTER_N-1:0]  rd_addr_f;

  wire                    done_x;
  wire                    done_acc;
  wire                    done_f;

  wire [LG_CONV_N-1:0]    comp_cyc;
  reg  [LG_CONV_N-1:0]    comp_cyc_q;

  wire                    mem_wr_state;
  wire                    mem_wr_done;
  wire                    in_compute;
  wire                    incr_comp_cyc;
  wire                    curr_comp_done;
  wire                    comp_done;

  // ------------------------------------------------------------------
  // State register
  // ------------------------------------------------------------------
  always_ff @(posedge clk or posedge reset)
    if (reset) begin
      cntrl_state_q <= 3'b000;
    end else begin
      cntrl_state_q <= cntrl_state;
    end

  // ------------------------------------------------------------------
  // Main Computation cycle counter
  // ------------------------------------------------------------------
  always_ff @(posedge clk or posedge reset)
    if (reset) begin
      comp_cyc_q <= {LG_CONV_N{1'b0}};
    end else if (comp_done | incr_comp_cyc) begin
      comp_cyc_q <= comp_cyc;
    end

  // ------------------------------------------------------------------
  // Comnbinational Logic - Next state generation
  // ------------------------------------------------------------------
  always_comb begin
    case (cntrl_state_q)
      CT_IDLE: begin
        cntrl_state = (s_valid_x | s_valid_f) ? CT_MEM_WR : CT_IDLE;
      end
      CT_MEM_WR: begin
        cntrl_state = (done_x & done_f) ? CT_WAIT : CT_MEM_WR;
      end
      CT_WAIT: begin
        cntrl_state = CT_IN_COMP;
      end
      CT_IN_COMP: begin
        cntrl_state = (done_acc) ? CT_INCR_CYC : CT_IN_COMP;
      end
      CT_INCR_CYC: begin
        cntrl_state = CT_DONE;
      end
      CT_DONE: begin
        cntrl_state = (m_valid_y & m_ready_y) ? 
                      comp_done ? CT_IDLE : CT_IN_COMP :
                      CT_DONE;
      end
    endcase
  end

  // ------------------------------------------------------------------
  // Comnbinational Logic
  // ------------------------------------------------------------------
  assign mem_wr_state   = (cntrl_state_q == CT_MEM_WR);
  assign mem_wr_done    = (cntrl_state_q == CT_WAIT);
  assign in_compute     = (cntrl_state_q == CT_IN_COMP);
  assign incr_comp_cyc  = (cntrl_state_q == CT_INCR_CYC);
  assign curr_comp_done = (cntrl_state_q == CT_DONE) & (m_valid_y & m_ready_y);

  assign comp_done      = (comp_cyc_q == CONV_N) & (m_valid_y & m_ready_y);

  assign comp_cyc       = comp_done ? {LG_CONV_N{1'b0}} :
                          (cntrl_state_q == CT_INCR_CYC) ?
                          comp_cyc_q + {{LG_CONV_N-1{1'b0}}, 1'b1} : comp_cyc_q;

  // ------------------------------------------------------------------
  // Control For Data Vectors
  // ------------------------------------------------------------------
  control_x #(
    .DATA_N     (DATA_N),
    .LG_DATA_N  (LG_DATA_N)
  ) CNTRL_X(
    .clk          (clk),
    .reset        (reset),
    .s_valid_x    (s_valid_x),
    .addr_x       (int_addr_x),
    .wr_en_x      (int_wr_en_x),
    .s_ready_x    (s_ready_x),
    .mem_wr_state (mem_wr_state),
    .mem_wr_done  (mem_wr_done ),
    .done_x       (done_x)
  );

  // ------------------------------------------------------------------
  // Control For Filter Vectors
  // ------------------------------------------------------------------
  control_f #(
    .FILTER_N     (FILTER_N),
    .LG_FILTER_N  (LG_FILTER_N)
  ) CNTRL_F(
    .clk          (clk),
    .reset        (reset),
    .s_valid_f    (s_valid_f),
    .addr_f       (int_addr_f),
    .wr_en_f      (int_wr_en_f),
    .s_ready_f    (s_ready_f),
    .mem_wr_state (mem_wr_state),
    .mem_wr_done  (mem_wr_done ),
    .done_f       (done_f)
  );

  // ------------------------------------------------------------------
  // Control For Accumulator/Compute
  // ------------------------------------------------------------------
  control_acc #(
    .FILTER_N     (FILTER_N),
    .LG_FILTER_N  (LG_FILTER_N)
  ) CNTRL_ACC(
    .clk              (clk),
    .reset            (reset),
    .in_compute       (in_compute),
    .curr_comp_done   (curr_comp_done),
    .clear_acc        (clear_acc),
    .en_acc           (en_acc),
    .done_acc         (done_acc)
  );

  // ------------------------------------------------------------------
  // Control For Memory read ops
  // ------------------------------------------------------------------
  control_mem_rd #(
    .DATA_N       (DATA_N),
    .FILTER_N     (FILTER_N),
    .LG_DATA_N    (LG_DATA_N),
    .LG_FILTER_N  (LG_FILTER_N),
    .LG_CONV_N    (LG_CONV_N)
  ) CNTRL_MEM_RD(
    .clk            (clk),
    .reset          (reset),
    .in_compute     (in_compute),
    .incr_comp_cyc  (incr_comp_cyc),
    .mem_wr_state   (mem_wr_state),
    .compute_cyc    (comp_cyc_q),
    .rd_addr_x      (rd_addr_x),
    .rd_addr_f      (rd_addr_f)
  );

  // ------------------------------------------------------------------
  // Output Assignments
  // ------------------------------------------------------------------
  assign addr_x = in_compute ? rd_addr_x : int_addr_x;
  assign addr_f = in_compute ? rd_addr_f : int_addr_f;
  assign wr_en_x = in_compute ? 1'b0 : int_wr_en_x;
  assign wr_en_f = in_compute ? 1'b0 : int_wr_en_f;
  assign m_valid_y = (cntrl_state_q == CT_DONE);

endmodule
