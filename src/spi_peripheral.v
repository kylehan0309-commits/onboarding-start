module spi_peripheral (
    input  wire clk,
    input  wire rst_n,

    input  wire nCS,
    input  wire SCLK,
    input  wire COPI,

    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

//Signal Synchronization

reg[2:0] ncsSync; //Using 3 bits for bit[2] = old value, bit[1] = stable value, bit[0] = unstable value (Edge detection)
reg[1:0] copiSync; //bit[0] = unstable, bit[1] stable, only the level matters and not edge detection
reg[2:0] sclkSync; //Using 3 bits for bit[2] = old value, bit[1] = stable value, bit[0] = unstable value (Edge detection)

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin //reset reg
        ncsSync <= 3'b111;
        copiSync <= 2'b00;
        sclkSync <= 3'b000;
    end else begin //Shift each async input through flip flops to bring into clk, only bits 1 and 2 are used for metastability (bits 0 and 1 for COPI)
        ncsSync <= {ncsSync[1:0], nCS};
        copiSync <= {copiSync[0], COPI};
        sclkSync <= {sclkSync[1:0], SCLK};
    end
end

//Edge detection

wire sclkPos = (sclkSync[2] == 1'b0) && (sclkSync[1] == 1'b1); //If old is 0 and new is 1 = SCLK positive edge (rising)
wire ncsNeg = (ncsSync[2] == 1'b1) && (ncsSync[1] == 1'b0); //If old is 1 and new is 0 = nCS negative edge (falling)
wire ncsPos = (ncsSync[2] == 1'b0) && (ncsSync[1] == 1'b1); //If old is 0 and new is 1 = nCS positive edge (rising)

//Bit Count & Shift

reg[15:0] shiftReg; //Capture 16 bits
reg[4:0] bitCount; //Counter can reach 16

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin //reset reg
        shiftReg <= 16'b0;
        bitCount <= 5'b0;
    end else if(ncsNeg) begin //reset bit count
        bitCount <= 5'b0;
    end else if(!ncsSync[1] && sclkPos) begin //Putting values of COPI into shiftReg and counting number of SCLK edges
        shiftReg <= {shiftReg[14:0], copiSync[1]};
        bitCount <= bitCount + 1;
    end
end

//Address Validation & Register Update & Transaction Finalization

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin //Reset reg
        en_reg_out_7_0 <= 8'h00;
        en_reg_out_15_8 <= 8'h00;
        en_reg_pwm_7_0 <= 8'h00;
        en_reg_pwm_15_8 <= 8'h00;
        pwm_duty_cycle <= 8'h00;
    end else if(ncsPos && bitCount == 5'd16 && shiftReg[15]) begin //If write is true
        case(shiftReg[14:8]) //Route data[7:0] to dedicated register
            7'h00: en_reg_out_7_0  <= shiftReg[7:0]; 
            7'h01: en_reg_out_15_8 <= shiftReg[7:0];
            7'h02: en_reg_pwm_7_0  <= shiftReg[7:0];
            7'h03: en_reg_pwm_15_8 <= shiftReg[7:0]; 
            7'h04: pwm_duty_cycle  <= shiftReg[7:0]; 
            default: ; //Ignore other addresses
        endcase
    end
end


endmodule