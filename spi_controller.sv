// SPI Master controller
module spi_controller #(
  parameter CPOL = 1
  ) (
  input  logic        clk,
  input  logic        reset,
  
  output logic        sclk,    // spi clk
  output logic        mosi,    // master out slave in
  output logic        mosi_oe, // master out slave in output-enable (for bi-dir buffer)
  input  logic        miso,    // master in slave out
  output logic        ssel,    // slave select
  
  output logic        write_enable,
  output logic [7:0]  write_address,
  output logic [7:0]  write_data,
  output logic [7:0]  read_address,
  input  logic [7:0]  read_data,
  
  input  logic        access_request,
  input  logic        read_write_n,
  input  logic [2:0]  dummy_cycles,
  input  logic        dummy_valid,
  input  logic [31:0] address,
  input  logic [1:0]  address_bytes,
  input  logic        address_valid,
  input  logic [7:0]  command,
  input  logic [7:0]  data_bytes,
  input  logic        data_valid,
  output logic        access_complete
  );
  
  logic clk_b;
  assign clk_b = ~clk;
  
  typedef enum {
    IDLE,
    INIT,
    COMMAND,
    ADDRESS,
    DUMMY,
    DATA,
    DONE
  } state_type;
  state_type state = IDLE;
  
  localparam INIT_CYCLE = 16;
  localparam COMMAND_CYCE = 8;
  localparam COUNT_WIDTH = 16;
  
  logic [COUNT_WIDTH-1:0] count = {COUNT_WIDTH{1'b0}};
  logic [7:0] wr_data_buffer;
  logic [7:0] rd_data_buffer;
  
  always_ff @(posedge clk) begin
    wr_data_buffer <= {wr_data_buffer[6:0],1'b0};
  end
  
  always_ff @(posedge clk_b) begin
    rd_data_buffer <= {rd_data_buffer[6:0],miso};
  end
  
  logic frame_valid = 0;
  always_ff @(posedge clk) begin
    frame_valid <= state == COMMAND | state == ADDRESS | state == DUMMY | state == DATA;
  end
  
  always_ff @(posedge clk) begin
    if (read_write_n) begin
      mosi_oe <= state == COMMAND | state == ADDRESS | state == DUMMY;
    end else begin
      mosi_oe <= state == COMMAND | state == ADDRESS | state == DUMMY | state == DATA;
    end
  end
  
  assign sclk = CPOL ? ~(clk & frame_valid) | clk & frame_valid;
  assign ssel = ~frame_valid;
  
  assign read_address = count[COUNT_WIDTH-1:8];
  
  always_ff @(posedge clk) begin
    if (state == DATA && read_write_n) begin
      write_enable <= 1'b1;
    end else begin
      write_enable <= 1'b0;
    end
    write_address <= count[COUNT_WIDTH-1:8];
    write_data <= rd_data_buffer;
  end
  
  always_ff @(posedge clk) begin
    if (reset) begin
      state <= IDLE;
      count <= {COUNT_WIDTH{1'b0}};
    end else begin
      case (state)
        IDLE : begin
          if (access_request) begin
            state <= INIT;
          end
        end
        INIT : begin
          if (count >= INIT_CYCLE-1) begin
            state <= COMMAND;
            count <= {COUNT_WIDTH{1'b0}};
          end else begin
            count <= count + 1;
          end
        end
        COMMAND : begin
          if (count >= COMMAND_CYCE-1) begin
            state <= address_valid ? ADDRESS : data_valid ? DATA : DONE;
            count <= {COUNT_WIDTH{1'b0}};
          end else begin
            count <= count + 1;
          end
        end
        ADDRESS : begin
          if (count >= {address_bytes,3'b111}) begin
            state <= dummy_valid ? DUMMY : data_valid ? DATA : DONE;
            count <= {COUNT_WIDTH{1'b0}};
          end else begin
            count <= count + 1;
          end
        end
        DUMMY : begin
          if (count >= dummy_cycles) begin
            state <= data_valid ? DATA : DONE;
            count <= {COUNT_WIDTH{1'b0}};
          end else begin
            count <= count + 1;
          end
        end
        DATA : begin
          if (count >= data_bytes) begin
            state <= DONE;
            count <= {COUNT_WIDTH{1'b0}};
          end else begin
            count <= count + 1;
          end
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
