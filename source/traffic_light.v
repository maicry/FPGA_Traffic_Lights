module traffic_light(
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
	
    output wire         beeper
);

parameter GREEN_LIGHT = 2'd0;
parameter RED_LIGHT = 2'd1;

reg [1:0] current_state = GREEN_LIGHT;
reg [3:0] countdown_timer;

// RGBµÆ¿ØÖÆ
reg red_light_internal1;
reg green_light_internal1;
reg blue_light_internal1;

reg red_light_internal2;
reg green_light_internal2;
reg blue_light_internal2;

assign red_light1 = red_light_internal1;
assign green_light1 = green_light_internal1;
assign blue_light1 = blue_light_internal1;

assign red_light2 = red_light_internal2;
assign green_light2 = green_light_internal2;
assign blue_light2 = blue_light_internal2;

reg [23:0] clk_counter = 0;
reg sec_pulse = 1'b0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_counter <= 0;
        sec_pulse <= 1'b0;
    end else begin
        clk_counter <= clk_counter + 1;
        if (clk_counter == 12000000 - 1) begin
            clk_counter <= 0;
            sec_pulse <= 1'b1;
        end else begin
            sec_pulse <= 1'b0;
        end
    end
end

reg beeper_en = 1'b0;

always @(posedge clk or negedge rst_n) begin
	blue_light_internal1 <= 1'b1;
	
	green_light_internal2 <= 1'b1;
	red_light_internal2 <= 1'b1;
	blue_light_internal2 <= 1'b1;
	
    if (!rst_n) begin
        current_state <= GREEN_LIGHT;
        countdown_timer <= 4'd8;
        green_light_internal1 <= 1'b0;
        red_light_internal1 <= 1'b0;
        beeper_en <= 1'b0;
    end else begin
        if (sec_pulse) begin
            case (current_state)
                GREEN_LIGHT: begin
                    if (countdown_timer > 0) begin
                        green_light_internal1 <= 1'b1;
                        red_light_internal1 <= 1'b0;
                        countdown_timer <= countdown_timer - 1;
                        beeper_en <= 1'b0;
                    end else begin
						green_light_internal1 <= 1'b0;
                        red_light_internal1 <= 1'b1;
                        current_state <= RED_LIGHT;
                        countdown_timer <= 4'd12;
                        beeper_en <= 1'b0;
                    end
                end
                RED_LIGHT: begin
                    if (countdown_timer > 0) begin
                        green_light_internal1 <= 1'b0;
                        red_light_internal1 <= 1'b1;
                        countdown_timer <= countdown_timer - 1;
                        beeper_en <= (countdown_timer <= 4'd6) ? 1'b1 : 1'b0;
                       
                    end else begin
						green_light_internal1 <= 1'b1;
                        red_light_internal1 <= 1'b0;
                        current_state <= GREEN_LIGHT;
                        countdown_timer <= 4'd8;
                        beeper_en <= 1'b0;
                    end
                end
            endcase
        end
    end
end


wire [3:0] dat_1 = (countdown_timer >= 10) ? 4'd1 : 4'd0;
wire [3:0] dat_2 = countdown_timer % 10;

wire [7:0] dat_en = 8'b1100_0000;
wire [7:0] dot_en = 8'b0;


beeper u_beeper (
    .clk(clk),
    .rst_n(rst_n),
    .beeper_en(beeper_en), 
    .beeper(beeper)
);

segment u_segment (
    .clk(clk),
    .rst_n(rst_n),
    .data_1(dat_1),
    .data_2(dat_2),
    .data_en(dat_en),
    .dot_en(dot_en),
    .seg_rck(seg_rck),
    .seg_sck(seg_sck),
    .seg_din(seg_din)
);

endmodule