module uart_controller (
  input  logic       clk,
  input  logic       reset,
  input  logic       clk_enable,
  input  logic       parity_en,
  input  logic       rx_uart,
  output logic       tx_uart,
  output logic       tx_data_ready,
  input  logic       tx_data_valid,
  input  logic [7:0] tx_data,
  output logic       rx_data_error,
  output logic       rx_data_valid,
  output logic [7:0] rx_data
  );
  
  typedef enum {
    IDLE,
    ACTIVE,
    DONE
  } state_type;
  state_type state_tx = IDLE;
  state_type state_rx = IDLE;
  
  logic [10:0] tx_data_buffer = {11{1'b1}};
  logic [10:0] rx_data_buffer = {11{1'b1}};
  
  localparam COUNT_TX = 16*11;
  localparam COUNT_RX = 16*10;
  localparam COUNT_WIDTH = $clog2(COUNT_TX);
  
  logic [COUNT_WIDTH-1:0] count_tx = {COUNT_WIDTH{1'b0}};
  logic [COUNT_WIDTH-1:0] count_rx = {COUNT_WIDTH{1'b0}};
  
  logic tx_parity;
  logic rx_parity;
  
  assign tx_parity = parity_en ? ^tx_data : 1'b1;
  assign rx_parity = ^rx_data;
  
  always_ff @(posedge clk) begin
    if (state_tx == IDLE && tx_data_valid && tx_data_ready && clk_enable) begin
      tx_data_buffer <= {1'b1,tx_parity,tx_data,1'b0};
    end else if (state_tx == ACTIVE && count_tx[3:0] == 4'hF && clk_enable) begin
      tx_data_buffer <= {1'b1,tx_data_buffer[7:1]};
    end
  end
  
  always_ff @(posedge clk) begin
    if (reset) begin
      tx_data_ready <= 1'b0;
    end else begin
      tx_data_ready <= state_tx == IDLE;
    end
  end
  
  assign tx_uart = tx_data_buffer[0];
  
  // state-machine for UART-TX
  always_ff @(posedge clk) begin
    if (reset) begin
      state_tx <= IDLE;
      count_tx <= {COUNT_WIDTH{1'b0}};
    end else if (clk_enable) begin
      case (state_tx)
        IDLE : begin
          if (tx_data_valid && tx_data_ready) begin
            state_tx <= ACTIVE;
          end
        end
        ACTIVE : begin
          if (count_tx >= COUNT_TX-1) begin
            state_tx <= DONE;
            count_tx <= {COUNT_WIDTH{1'b0}};
          end else begin
            count_tx <= count_tx + 1;
          end
        end
        DONE : begin
          state_tx <= IDLE;
          count_tx <= {COUNT_WIDTH{1'b0}};
        end
        default : begin
          state_tx <= IDLE;
          count_tx <= {COUNT_WIDTH{1'b0}};
        end
      endcase
    end
  end
  
  always_ff @(posedge clk) begin
    if (state_rx == IDLE && clk_enable) begin
      rx_data_buffer <= {rx_uart,rx_data_buffer[10:1]};
    end else if (state_rx == ACTIVE && count_tx[3:0] == 4'hF && clk_enable) begin
      rx_data_buffer <= {rx_uart,rx_data_buffer[10:1]};
    end
  end
  
  assign rx_data = rx_data_buffer[8:1];
  
  always_ff @(posedge clk) begin
    if (reset) begin
      rx_data_valid <= 1'b0;
      rx_data_error <= 1'b0;
    end else begin
      rx_data_valid <= state_rx == DONE && clk_enable;
      rx_data_error <= rx_parity == rx_data_buffer[9];
    end
  end
  
  // state-machine for UART-RX
  always_ff @(posedge clk) begin
    if (reset) begin
      state_rx <= IDLE;
      count_rx <= {COUNT_WIDTH{1'b0}};
    end else if (clk_enable) begin
      case (state_rx)
        IDLE : begin
          if (rx_data_buffer == 11'hFC0) begin
            state_rx <= ACTIVE;
          end
        end
        ACTIVE : begin
          if (count_rx >= COUNT_RX-1) begin
            state_rx <= DONE;
            count_rx <= {COUNT_WIDTH{1'b0}};
          end else begin
            count_rx <= count_rx + 1;
          end
        end
        DONE : begin
          state_rx <= IDLE;
          count_rx <= {COUNT_WIDTH{1'b0}};
        end
        default : begin
          state_rx <= IDLE;
          count_rx <= {COUNT_WIDTH{1'b0}};
        end
      endcase
    end
  end
  
endmodule
