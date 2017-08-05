module i2c_controller #(
  parameter integer DATA_BYTES = 4,
  parameter integer BYTE_WIDTH = $clog2(DATA_BYTES),
  parameter integer DATA_WIDTH = DATA_BYTES*8,
  parameter integer CLOCK_DIVIDER = 100
  ) (
  input  logic                  clk,
  input  logic                  reset,
  
  input  logic                  scl_i,
  output logic                  scl_o,
  output logic                  scl_oe,
  input  logic                  sda_i,
  output logic                  sda_o,
  output logic                  sda_oe,
  
  input  logic                  access_request,
  input  logic [7:0]            dev_id,
  input  logic [DATA_WIDTH-1:0] address,
  input  logic [BYTE_WIDTH-1:0] address_byte,
  input  logic [BYTE_WIDTH-1:0] data_byte,
  input  logic [DATA_WIDTH-1:0] write_data,
  output logic [DATA_WIDTH-1:0] read_data,
  output logic                  access_complete,
  output logic                  invalid_access,
  
  output logic                  busy
  );
  
  typedef enum {
    IDLE,
    START,
    RESTART,
    DEV_ADDR,
    REG_ADDR,
    READ_DATA,
    WRITE_DATA,
    STOP,
    DONE
  } state_type;
  state_type state = IDLE;
  
  localparam COMD_LENGTH = 4;
  localparam DATA_LENGTH = 9*4;
  localparam COUNT_WIDTH = $clog2(9);
  logic [COUNT_WIDTH-1:0] count = {COUNT_WIDTH{1'b0}};
  
  logic [7:0]            dev_id_r;
  logic [DATA_WIDTH-1:0] address_r;
  logic [BYTE_WIDTH-1:0] address_byte_r;
  logic [BYTE_WIDTH-1:0] data_byte_r;
  logic [DATA_WIDTH-1:0] write_data_r;

  // clock divider logic for SCL
  localparam CLKDIV_WIDTH = $clog2(CLOCK_DIVIDER);
  logic [CLKDIV_WIDTH-1:0] clk_div = {CLKDIV_WIDTH{1'b0}};
  
  always_ff @(posedge clk) begin
    if (reset) begin
      clk_div <= {CLKDIV_WIDTH{1'b0}};
    end else begin
      if (clk_div >= CLOCK_DIVIDER-1) begin
        clk_div <= {CLKDIV_WIDTH{1'b0}};
      end else begin
        clk_div <= clk_div + 1;
      end
    end
  end
  
  logic request_pending = 1'b0;
  logic write_operation = 1'b0;
  
  always_ff @(posedge clk) begin
    if (reset) begin
      request_pending <= 0;
      write_operation <= 0;
    end else if (state == DONE) begin
      request_pending <= 0;
      write_operation <= 0;
    end else if (!request_pending && state == IDLE && access_request) begin
      request_pending <= 1;
      write_operation <= !dev_id[0]; // R/W_B
    end
  end
  
  assign busy = request_pending;
  
  always_ff @(posedge clk) begin
    if (!request_pending && state == IDLE && access_request) begin
      dev_id_r <= dev_id;
      address_r <= address;
      address_byte_r <= address_byte;
      data_byte_r <= data_byte;
      write_data_r <= write_data;
    end
  end
  
  // i2c state-machine for Slave interface
  always_ff @(posedge clk) begin
    if (reset) begin
      state <= IDLE;
      count <= {COUNT_WIDTH{1'b0}};
    end else if (clk_div == CLOCK_DIVIDER-1) begin
      case (state)
        IDLE : begin
          if (request_pending) begin
            state <= START;
          end
        end
        START : begin
          if (count >= COMD_LENGTH-1) begin
            state <= DEV_ADDR;
            count <= {COUNT_WIDTH{1'b0}};
          end else begin
            count <= count + 1;
          end
        end
        DEV_ADDR : begin
          if (count >= DATA_LENGTH-1) begin
            state <= DEV_ADDR;
            count <= {COUNT_WIDTH{1'b0}};
          end else begin
            count <= count + 1;
          end
        end
        STOP : begin
          state <= DONE;
        end
        DONE : begin
          state <= IDLE;
          count <= {COUNT_WIDTH{1'b0}};
        end
        default : begin
          state <= IDLE;
          count <= {COUNT_WIDTH{1'b0}};
        end
      endcase
    end
  end
  
endmodule
