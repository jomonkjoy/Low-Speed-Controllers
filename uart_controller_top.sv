module uart_controller_top #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_DEPTH = 4,
  parameter CLK_FREQUENCY = 100 // in MHz
  ) (
  input  logic                    clk,
  input  logic                    reset,
  input  logic                    parity_en,
  input  logic                    rx_uart,
  output logic                    tx_uart,
  // UART tx side
  input  logic                    s_aclk,
  input  logic                    s_areset_n,
  input  logic [DATA_WIDTH-1:0]   s_tdata,
  input  logic [DATA_WIDTH/8-1:0] s_tkeep,
  input  logic                    s_tvalid,
  output logic                    s_tready,
  input  logic                    s_tlast,
  // UART rx side
  input  logic                    m_aclk,
  input  logic                    m_areset_n,
  output logic [DATA_WIDTH-1:0]   m_tdata,
  output logic [DATA_WIDTH/8-1:0] m_tkeep,
  output logic                    m_tvalid,
  input  logic                    m_tready,
  output logic                    m_tlast
);

logic       tx_data_ready;
logic       tx_data_valid;
logic [7:0] tx_data;
logic       rx_data_error;
logic       rx_data_valid;
logic [7:0] rx_data;

uart_controller uart_controller_inst (
  .clk           (clk),
  .reset         (reset),
  .parity_en     (parity_en),
  .rx_uart       (rx_uart),
  .tx_uart       (tx_uart),
  .tx_data_ready (tx_data_ready),
  .tx_data_valid (tx_data_valid),
  .tx_data       (tx_data),
  .rx_data_error (rx_data_error),
  .rx_data_valid (rx_data_valid),
  .rx_data       (rx_data)
);

axis_fifo #(
  .DATA_WIDTH (DATA_WIDTH),
  .ADDR_DEPTH (ADDR_DEPTH)
) axis_fifo_txuart_inst (
  .s_aclk     (s_aclk),
  .s_areset_n (s_areset_n),
  .s_tdata    (s_tdata),
  .s_tkeep    (s_tkeep),
  .s_tvalid   (s_tvalid),
  .s_tready   (s_tready),
  .s_tlast    (s_tlast),
  .m_aclk     (clk),
  .m_areset_n (!reset),
  .m_tdata    (tx_data),
  .m_tkeep    (),
  .m_tvalid   (tx_data_valid),
  .m_tready   (tx_data_ready),
  .m_tlast    ()
);

axis_fifo #(
  .DATA_WIDTH (DATA_WIDTH),
  .ADDR_DEPTH (ADDR_DEPTH)
) axis_fifo_rxuart_inst (
  .s_aclk     (clk),
  .s_areset_n (!reset),
  .s_tdata    (rx_data),
  .s_tkeep    (!rx_data_error),
  .s_tvalid   (rx_data_valid),
  .s_tready   (),
  .s_tlast    (1'b0),
  .m_aclk     (m_aclk),
  .m_areset_n (m_areset_n),
  .m_tdata    (m_tdata),
  .m_tkeep    (m_tkeep),
  .m_tvalid   (m_tvalid),
  .m_tready   (m_tready),
  .m_tlast    (m_tlast)
);

endmodule
