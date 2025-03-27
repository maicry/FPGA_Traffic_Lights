module detecter(
    input               clk,
    input               rst_n,
	
    output              i2c_scl,
    inout               i2c_sda,
    output [7:0]        led,
    output              beeper_singal
);

wire dat_valid;
wire [15:0] ch0_dat, ch1_dat, prox_dat;
wire [31:0] lux_data;
wire beeper_en;

sensor u1(
    .clk(clk),
    .rst_n(rst_n),
    .i2c_scl(i2c_scl),
    .i2c_sda(i2c_sda),
    .data_valid(dat_valid),
    .proximity_data(prox_dat)
);

controller u2(
    .rst_n(rst_n),
    .dat_valid(dat_valid),
    .prox_dat(prox_dat),
    .Y_out(led),
    .beeper_en(beeper_en)
);

beeper u3(
    .clk(clk),
    .rst_n(rst_n),
    .beeper_en(beeper_en),
    .beeper(beeper_singal)
);

endmodule