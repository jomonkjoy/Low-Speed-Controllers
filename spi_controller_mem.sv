module spi_controller_mem #(
    parameter MINIT_FILE = "",
    parameter ADDR_WIDTH = 5,
    parameter DATA_BYTES = 4,
    parameter DATA_WIDTH = DATA_BYTES*8
  ) (
    input  logic                  clka,
    input  logic [DATA_BYTES-1:0] wena,
    input  logic [ADDR_WIDTH-1:0] addra,
    input  logic [DATA_WIDTH-1:0] dina,
    output logic [DATA_WIDTH-1:0] douta,
    
    input  logic                  clkb,
    input  logic [ADDR_WIDTH-1:0] addrb,
    output logic [DATA_WIDTH-1:0] doutb
  );

  logic [DATA_WIDTH-1:0] mem [0:2**ADDR_WIDTH-1] = '{default:{DATA_WIDTH{1'b0}}};

  integer i;
  initial begin
    if (MINIT_FILE != "") begin
        $readmemh(MINIT_FILE, mem);
     end
  end
  
  always_ff @(posedge clka) begin
    for (i=0; i<DATA_BYTES; i++) begin
      if (wena[i]) begin
        mem[addra][8*i+:8] <= dina[8*i+:8];
      end
    end
  end

  always_ff @(posedge clka) begin
    douta <= mem[addra];
  end

  always_ff @(posedge clkb) begin
    doutb <= mem[addrb];
  end
        
endmodule
