module controller(
    input               rst_n,
    input               dat_valid,
    input [15:0]        prox_dat,
    output reg [7:0]    Y_out,
    output reg          beeper_en
);

parameter THRESHOLD = 16'h80;
reg [15:0] prox_dat0, prox_dat1, prox_dat2;

always @(posedge dat_valid) begin
    prox_dat0 <= prox_dat;
    prox_dat1 <= prox_dat0;
    if ((prox_dat1 - prox_dat0 >= 16'h0400) || (prox_dat0 - prox_dat1 >= 16'h0400))
        prox_dat2 <= prox_dat2;
    else
        prox_dat2 <= prox_dat0;
end

always @(*) begin
    beeper_en = (prox_dat2 >= THRESHOLD) ? 1'b1 : 1'b0;
end

always @(*) begin
    case (prox_dat2[11:9])
        3'b000: Y_out = 8'b11111111;
        3'b001: Y_out = 8'b11110000;
        default: Y_out = 8'b00000000;
    endcase
end


endmodule