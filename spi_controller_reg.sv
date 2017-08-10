module spi_controller_reg (
  input  logic        clk,
  input  logic        reset,
  
  output logic        access_request = 1'b0,
  output logic        read_write_n,
  output logic [2:0]  dummy_cycles,
  output logic        dummy_valid,
  output logic [31:0] address,
  output logic [1:0]  address_bytes,
  output logic        address_valid,
  output logic [7:0]  command,
  output logic [7:0]  data_bytes,
  output logic        data_valid,
  input  logic        access_complete,

  input  logic        cpu_if_read,
  input  logic        cpu_if_write,
  input  logic [31:0] cpu_if_write_data,
  input  logic [31:2] cpu_if_address,
  output logic [31:0] cpu_if_read_data,
  output logic        cpu_if_access_complete
  );
  
  always_ff @(posedge clk) begin
    cpu_if_access_complete <= cpu_if_read | cpu_if_write;
  end
  
  logic access_complete_r = 1'b0;
  always_ff @(posedge clk) begin
    access_complete_r <= access_complete;
  end
  
  always_ff @(posedge clk) begin
    if (cpu_if_write && cpu_if_address == 30'd0) begin
      command <= cpu_if_write_data[7:0];
      read_write_n <= cpu_if_write_data[8];
      access_request <= 1'b1;
    end else begin
      access_request <= 1'b0;
    end
  end
  
  always_ff @(posedge clk) begin
    if (cpu_if_write && cpu_if_address == 30'd1) begin
      address <= cpu_if_write_data;
    end
  end
  
  always_ff @(posedge clk) begin
    if (cpu_if_write && cpu_if_address == 30'd2) begin
      address_bytes <= cpu_if_write_data[1:0];
      address_valid <= cpu_if_write_data[31];
    end
  end
  
  always_ff @(posedge clk) begin
    if (cpu_if_write && cpu_if_address == 30'd3) begin
      dummy_cycles <= cpu_if_write_data[2:0];
      dummy_valid <= cpu_if_write_data[31];
    end
  end
  
  always_ff @(posedge clk) begin
    if (cpu_if_write && cpu_if_address == 30'd4) begin
      data_bytes <= cpu_if_write_data[7:0];
      data_valid <= cpu_if_write_data[31];
    end
  end
  
  always_ff @(posedge clk) begin
    if (cpu_if_read) begin
      case (cpu_if_address)
        30'd0   : cpu_if_read_data <= {access_complete_r,22'd0,read_write_n,command};
        30'd1   : cpu_if_read_data <= {address};
        30'd2   : cpu_if_read_data <= {address_valid,23'd0,6'd0,address_bytes};
        30'd3   : cpu_if_read_data <= {dummy_valid,23'd0,5'd0,dummy_cycles};
        30'd4   : cpu_if_read_data <= {data_valid,23'd0,data_bytes};
        default : cpu_if_read_data <= 32'hDEADBEEF;
      endcase
    end
  end
  
endmodule
