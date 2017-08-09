module spi_controller_top #(
  parameter SYNC_STAGE = 4,
  parameter CPOL = 1
  ) (
  input  logic        sys_clk,
  input  logic        sys_reset,
  input  logic        spi_clk,
  
  output logic        sclk,    // spi clk
  output logic        mosi,    // master out slave in
  output logic        mosi_oe, // master out slave in output-enable (for bi-dir buffer)
  input  logic        miso,    // master in slave out
  output logic        ssel,    // slave select
  
  input  logic        wrb_if_read,
  input  logic        wrb_if_write,
  input  logic [31:0] wrb_if_write_data,
  input  logic [31:2] wrb_if_address,
  output logic [31:0] wrb_if_read_data,
  output logic        wrb_if_access_complete,
  
  input  logic        rdb_if_read,
  input  logic [31:2] rdb_if_address,
  output logic [31:0] rdb_if_read_data,
  output logic        rdb_if_access_complete,
  
  input  logic        cpu_if_read,
  input  logic        cpu_if_write,
  input  logic [31:0] cpu_if_write_data,
  input  logic [31:2] cpu_if_address,
  output logic [31:0] cpu_if_read_data,
  output logic        cpu_if_access_complete
  );

  logic        spi_reset;
  logic        spi_reset_n;

  logic        write_enable;
  logic [7:0]  write_address;
  logic [7:0]  write_data;
  logic [7:0]  read_address;
  logic [7:0]  read_data;

  logic        access_request;
  logic        read_write_n;
  logic [2:0]  dummy_cycles;
  logic        dummy_valid;
  logic [31:0] address;
  logic [1:0]  address_bytes;
  logic        address_valid;
  logic [7:0]  command;
  logic [7:0]  data_bytes;
  logic        data_valid;
  logic        access_complete;
  
  logic        spi_if_read;
  logic        spi_if_write;
  logic [31:0] spi_if_write_data;
  logic [31:2] spi_if_address;
  logic [31:0] spi_if_read_data;
  logic        spi_if_access_complete;
  
  reset_synchronizer #(
    .SYNC_STAGE                ( SYNC_STAGE )
  ) reset_synchronizer_inst (
    .clk                       ( spi_clk ) ,
    .reset_async               ( sys_reset ) ,
    .reset_sync                ( spi_reset ) ,
    .reset_sync_n              ( spi_reset_n )
  );

  cpu_if_cdc #( 
    .SYNC_STAGE                ( SYNC_STAGE ) 
  ) cpu_if_cdc_inst (
    .h_clk                     ( sys_clk ) ,
    .h_reset                   ( sys_reset ) ,
    .h_cpu_if_read             ( cpu_if_read ) ,
    .h_cpu_if_write            ( cpu_if_write ) ,
    .h_cpu_if_write_data       ( cpu_if_write_data ) ,
    .h_cpu_if_address          ( cpu_if_address ) ,
    .h_cpu_if_read_data        ( cpu_if_read_data ) ,
    .h_cpu_if_access_complete  ( cpu_if_access_complete ) ,
    .l_clk                     ( spi_clk ) ,
    .l_reset                   ( spi_reset ) ,
    .l_cpu_if_read             ( spi_if_read ) ,
    .l_cpu_if_write            ( spi_if_write ) ,
    .l_cpu_if_write_data       ( spi_if_write_data ) ,
    .l_cpu_if_address          ( spi_if_address ) ,
    .l_cpu_if_read_data        ( spi_if_read_data ) ,
    .l_cpu_if_access_complete  ( spi_if_access_complete )
  );

  spi_controller_reg spi_controller_reg_inst (
    .access_request            ( access_request ) ,
    .read_write_n              ( read_write_n ) ,
    .dummy_cycles              ( dummy_cycles ) ,
    .dummy_valid               ( dummy_valid ) ,
    .address                   ( address ) ,
    .address_bytes             ( address_bytes ) ,
    .address_valid             ( address_valid ) ,
    .command                   ( command ) ,
    .data_bytes                ( data_bytes ) ,
    .data_valid                ( data_valid ) ,
    .access_complete           ( access_complete ) ,
    .cpu_if_read               ( spi_if_read ) ,
    .cpu_if_write              ( spi_if_write ) ,
    .cpu_if_write_data         ( spi_if_write_data ) ,
    .cpu_if_address            ( spi_if_address ) ,
    .cpu_if_read_data          ( spi_if_read_data ) ,
    .cpu_if_access_complete    ( spi_if_access_complete ) 
  );
  
  spi_controller #(
    .CPOL                      ( CPOL )
  ) spi_controller_inst (
    .clk                       ( spi_clk ) ,
    .reset                     ( spi_reset ) ,
    .sclk                      ( sclk ) ,    // spi clk
    .mosi                      ( mosi ) ,    // master out slave in
    .mosi_oe                   ( mosi_oe ) , // master out slave in output-enable (for bi-dir buffer)
    .miso                      ( miso ) ,    // master in slave out
    .ssel                      ( ssel ) ,    // slave select
    .write_enable              ( write_enable ) ,
    .write_address             ( write_address ) ,
    .write_data                ( write_data ) ,
    .read_address              ( read_address ) ,
    .read_data                 ( read_data ) ,
    .access_request            ( access_request ) ,
    .read_write_n              ( read_write_n ) ,
    .dummy_cycles              ( dummy_cycles ) ,
    .dummy_valid               ( dummy_valid ) ,
    .address                   ( address ) ,
    .address_bytes             ( address_bytes ) ,
    .address_valid             ( address_valid ) ,
    .command                   ( command ) ,
    .data_bytes                ( data_bytes ) ,
    .data_valid                ( data_valid ) ,
    .access_complete           ( access_complete )
  );

endmodule
