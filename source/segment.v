module segment (
    input               clk,  
    input               rst_n,  
    input        [3:0]  data_1,   
    input        [3:0]  data_2,     
    input        [7:0]  data_en,   
    input        [7:0]  dot_en,   
	
    output reg   seg_rck, 
    output reg   seg_sck, 
    output reg   seg_din   
);

parameter IDLE  = 3'd0;
parameter MAIN  = 3'd1;
parameter WRITE = 3'd2;
parameter LOW   = 1'b0;
parameter HIGH  = 1'b1;
parameter CNT   = 300;

// 定义七段数码管的数据
reg [6:0] seg_data [15:0];
initial begin
    seg_data[0] = 7'h3f; // 0
    seg_data[1] = 7'h06; // 1
    seg_data[2] = 7'h5b; // 2
    seg_data[3] = 7'h4f; // 3
    seg_data[4] = 7'h66; // 4
    seg_data[5] = 7'h6d; // 5
    seg_data[6] = 7'h7d; // 6
    seg_data[7] = 7'h07; // 7
    seg_data[8] = 7'h7f; // 8
    seg_data[9] = 7'h6f; // 9
end

// 时钟分频
reg [9:0] clk_div_cnt;
wire clk_40;
assign clk_40 = (clk_div_cnt >= (CNT >> 1)) ? 1'b1 : 1'b0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_div_cnt <= 10'd0;
    end else if (clk_div_cnt >= (CNT - 1)) begin
        clk_div_cnt <= 10'd0;
    end else begin
        clk_div_cnt <= clk_div_cnt + 1'b1;
    end
end

// 状态机相关寄存器
reg [1:0] state;  // 2位状态
reg [15:0] shift_data;
reg [2:0] main_cnt;
reg [5:0] write_cnt;

always @(posedge clk_40 or negedge rst_n) begin
    if (!rst_n) begin
        state    <= IDLE;
        main_cnt <= 3'd0;
        write_cnt <= 6'd0;
        seg_din   <= 1'b0;
        seg_sck   <= LOW;
        seg_rck   <= LOW;
    end else begin
        case (state)
            IDLE: begin
                state    <= MAIN;
                main_cnt <= 3'd0;
                write_cnt <= 6'd0;
                seg_din   <= 1'b0;
                seg_sck   <= LOW;
                seg_rck   <= LOW;
            end

            MAIN: begin
                main_cnt <= main_cnt + 1'b1;
                state    <= WRITE;
                case (main_cnt)
                    3'd0: begin
                        if (data_en[7]) begin
                            shift_data <= {dot_en[7], seg_data[data_1], 8'hfe};
                        end else begin
                            shift_data <= {dot_en[7], seg_data[data_1], 8'hff};
                        end
                    end
                    3'd1: begin
                        if (data_en[6]) begin
                            shift_data <= {dot_en[6], seg_data[data_2], 8'hfd};
                        end else begin
                            shift_data <= {dot_en[6], seg_data[data_2], 8'hff};
                        end
                    end
                    default: shift_data <= 0;
                endcase
            end

            WRITE: begin
                if (write_cnt >= 34) begin
                    write_cnt <= 6'd0;
                end else begin
                    write_cnt <= write_cnt + 1'b1;
                end

                case (write_cnt)
                    6'd0: begin seg_sck <= LOW; seg_din <= shift_data[15]; end
                    6'd1: begin seg_sck <= HIGH; end
                    6'd2: begin seg_sck <= LOW; seg_din <= shift_data[14]; end
                    6'd3: begin seg_sck <= HIGH; end
                    6'd4: begin seg_sck <= LOW; seg_din <= shift_data[13]; end
                    6'd5: begin seg_sck <= HIGH; end
                    6'd6: begin seg_sck <= LOW; seg_din <= shift_data[12]; end
                    6'd7: begin seg_sck <= HIGH; end
                    6'd8: begin seg_sck <= LOW; seg_din <= shift_data[11]; end
                    6'd9: begin seg_sck <= HIGH; end
                    6'd10: begin seg_sck <= LOW; seg_din <= shift_data[10]; end
                    6'd11: begin seg_sck <= HIGH; end
                    6'd12: begin seg_sck <= LOW; seg_din <= shift_data[9]; end
                    6'd13: begin seg_sck <= HIGH; end
                    6'd14: begin seg_sck <= LOW; seg_din <= shift_data[8]; end
                    6'd15: begin seg_sck <= HIGH; end
                    6'd16: begin seg_sck <= LOW; seg_din <= shift_data[7]; end
                    6'd17: begin seg_sck <= HIGH; end
                    6'd18: begin seg_sck <= LOW; seg_din <= shift_data[6]; end
                    6'd19: begin seg_sck <= HIGH; end
                    6'd20: begin seg_sck <= LOW; seg_din <= shift_data[5]; end
                    6'd21: begin seg_sck <= HIGH; end
                    6'd22: begin seg_sck <= LOW; seg_din <= shift_data[4]; end
                    6'd23: begin seg_sck <= HIGH; end
                    6'd24: begin seg_sck <= LOW; seg_din <= shift_data[3]; end
                    6'd25: begin seg_sck <= HIGH; end
                    6'd26: begin seg_sck <= LOW; seg_din <= shift_data[2]; end
                    6'd27: begin seg_sck <= HIGH; end
                    6'd28: begin seg_sck <= LOW; seg_din <= shift_data[1]; end
                    6'd29: begin seg_sck <= HIGH; end
                    6'd30: begin seg_sck <= LOW; seg_din <= shift_data[0]; end
                    6'd31: begin seg_sck <= HIGH; end
                    6'd32: begin seg_rck <= HIGH; end
                    6'd33: begin seg_rck <= LOW; state <= MAIN; end
                    default: begin end
                endcase
            end

            default: begin
                state <= IDLE;
            end
        endcase
    end
end

endmodule