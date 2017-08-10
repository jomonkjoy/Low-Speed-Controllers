module spi_mem_bridge (
  input  logic        clk,
  input  logic        reset,
  
  input  logic        sclk,    // spi clk
  input  logic        mosi,    // master out slave in
  input  logic        mosi_oe, // master out slave in output-enable (for bi-dir buffer)
  output logic        miso,    // master in slave out
  input  logic        ssel,    // slave select

  output logic        read,
  output logic        write,
  output logic [31:2] address,
  output logic [31:0] write_data,
  input  logic [31:0] read_data,
  input  logic        access_complete
  );

endmodule
