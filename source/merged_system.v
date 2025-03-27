module merged_system(
    input               clk,    
    input               rst_n,  
	
    output wire         red_light1, 
    output wire         green_light1,
	output wire			blue_light1,
	output wire			red_light2,
	output wire			green_light2,
	output wire			blue_light2,
	
    output wire         seg_rck, 
    output wire         seg_sck,  
    output wire         seg_din,  
	
    output wire         bee,  
	
    output              i2c_scl, 
    inout               i2c_sda,
	
    output [7:0]        led 
);

wire beeper; 
traffic_light u_traffic_light (
    .clk(clk),
    .rst_n(rst_n),
	
    .red_light1(red_light1),
    .green_light1(green_light1),
	.blue_light1(blue_light1),
	
	.red_light2(red_light2),
    .green_light2(green_light2),
	.blue_light2(blue_light2),
	
    .seg_rck(seg_rck),
    .seg_sck(seg_sck),
    .seg_din(seg_din),
	
    .beeper(beeper)
);

wire beeper_singal;
detecter u_detecter (
    .clk(clk),
    .rst_n(rst_n),
    .i2c_scl(i2c_scl),
    .i2c_sda(i2c_sda),
    .led(led),
    .beeper_singal(beeper_singal)
);

assign bee = beeper | beeper_singal;

endmodule