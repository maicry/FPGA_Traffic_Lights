module sensor (
    input wire clk,
    input wire rst_n,
    inout wire i2c_sda,
    output wire i2c_scl,
    output reg data_valid,
    output reg [15:0] proximity_data
);

localparam STATE_BITS = 4;
localparam IDLE_STATE = 4'd0;
localparam MAIN_STATE = 4'd1;
localparam MODE1_STATE = 4'd2;
localparam MODE2_STATE = 4'd3;
localparam START_STATE = 4'd4;
localparam WRITE_STATE = 4'd5;
localparam READ_STATE = 4'd6;
localparam STOP_STATE = 4'd7;
localparam DELAY_STATE = 4'd8;
localparam ACK_HIGH = 1'b1;
localparam ACK_LOW = 1'b0;
localparam TIMEOUT = 24'd4800;
parameter MAX_COUNT = 15;

reg [9:0] clock_counter;
reg [23:0] delay_timer;

reg phase_clock;
reg i2c_data_clk, i2c_data_bus;
reg ack_state, ack_flag;
reg [3:0] current_state, prev_state;

reg [3:0] step_counter_1, step_counter_2, step_counter_3, step_counter_4, step_counter_5;
reg [3:0] main_phase, mode1_phase, mode2_phase, start_phase, stop_phase;
reg [7:0] write_buffer, device_addr, reg_addr, reg_data, read_buffer;
reg [15:0] channel_0, channel_1;
reg [7:0] high_reg, low_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clock_counter <= 0;
        phase_clock <= 0;
    end else begin
        if (clock_counter == MAX_COUNT - 1) begin
            clock_counter <= 0;
        end else begin
            clock_counter <= clock_counter + 1;
        end
        if (clock_counter == MAX_COUNT - 1) begin
            phase_clock <= ~phase_clock;
        end
    end
end

always @(posedge phase_clock or negedge rst_n) begin
    if (!rst_n) begin
        i2c_data_clk <= 1'd1;
        i2c_data_bus <= 1'd1;
        ack_state <= ACK_LOW;
        ack_flag <= 1'b0;
        current_state <= IDLE_STATE;
        prev_state <= IDLE_STATE;
        main_phase <= 4'd0;
        mode1_phase <= 4'd0;
        mode2_phase <= 4'd0;
        start_phase <= 3'd0;
        step_counter_1 <= 0;
        step_counter_2 <= 0;
        step_counter_3 <= 0;
        step_counter_4 <= 0;
        step_counter_5 <= 0;
        device_addr <= 7'h38;
        reg_addr <= 8'h40;
        reg_data <= 8'h0a;
        read_buffer <= 8'h00;
        high_reg <= 8'h00;
        low_reg <= 8'h00;
        channel_0 <= 16'd0;
        channel_1 <= 16'd0;
        delay_timer <= TIMEOUT;
        proximity_data <= 16'd0;
        data_valid <= 0;
    end else begin
        case (current_state)
            IDLE_STATE: begin
                i2c_data_clk <= 1'd1;
                i2c_data_bus <= 1'd1;
                ack_state <= ACK_LOW;
                ack_flag <= 1'b0;
                step_counter_1 <= 0;
                main_phase <= 4'd0;
                mode1_phase <= 4'd0;
                mode2_phase <= 4'd0;
                start_phase <= 3'd0;
                current_state <= MAIN_STATE;
                prev_state <= IDLE_STATE;
            end

            MAIN_STATE: begin
                if (main_phase >= 4'd11) begin
                    main_phase <= 4'd4;
                end else begin
                    main_phase <= main_phase + 1;
                end

                case (main_phase)
                    4'd0: begin
                        device_addr <= 7'h38;
                        reg_addr <= 8'h40;
                        reg_data <= 8'h0a;
                        current_state <= MODE1_STATE;
                    end
                    4'd1: begin
                        device_addr <= 7'h38;
                        reg_addr <= 8'h41;
                        reg_data <= 8'hc6;
                        current_state <= MODE1_STATE;
                    end
                    4'd2: begin
                        device_addr <= 7'h38;
                        reg_addr <= 8'h42;
                        reg_data <= 8'h02;
                        current_state <= MODE1_STATE;
                    end
                    4'd3: begin
                        device_addr <= 7'h38;
                        reg_addr <= 8'h43;
                        reg_data <= 8'h01;
                        current_state <= MODE1_STATE;
                    end
                    4'd4: begin
                        current_state <= DELAY_STATE;
                        data_valid <= 0;
                    end
                    4'd5: begin
                        device_addr <= 7'h38;
                        reg_addr <= 8'h44;
                        current_state <= MODE2_STATE;
                    end
                    4'd6: begin
                        proximity_data <= {high_reg, low_reg};
                    end
                    4'd7: begin
                        device_addr <= 7'h38;
                        reg_addr <= 8'h46;
                        current_state <= MODE2_STATE;
                    end
                    4'd8: begin
                        channel_0 <= {high_reg, low_reg};
                    end
                    4'd9: begin
                        device_addr <= 7'h38;
                        reg_addr <= 8'h48;
                        current_state <= MODE2_STATE;
                    end
                    4'd10: begin
                        channel_1 <= {high_reg, low_reg};
                    end
                    4'd11: begin
                        data_valid <= 1;
                    end
                    default: current_state <= IDLE_STATE;
                endcase
            end

            MODE1_STATE: begin
                if (mode1_phase >= 4'd5) begin
                    mode1_phase <= 0;
                end else begin
                    mode1_phase <= mode1_phase + 1;
                end

                prev_state <= MODE1_STATE;

                case (mode1_phase)
                    4'd0: begin
                        current_state <= START_STATE;
                    end
                    4'd1: begin
                        write_buffer <= device_addr << 1;
                        current_state <= WRITE_STATE;
                    end
                    4'd2: begin
                        write_buffer <= reg_addr;
                        current_state <= WRITE_STATE;
                    end
                    4'd3: begin
                        write_buffer <= reg_data;
                        current_state <= WRITE_STATE;
                    end
                    4'd4: begin
                        current_state <= STOP_STATE;
                    end
                    4'd5: begin
                        current_state <= MAIN_STATE;
                    end
                    default: current_state <= IDLE_STATE;
                endcase
            end

            MODE2_STATE: begin
                if (mode2_phase >= 4'd10) begin
                    mode2_phase <= 0;
                end else begin
                    mode2_phase <= mode2_phase + 1;
                end

                prev_state <= MODE2_STATE;

                case (mode2_phase)
                    4'd0: begin
                        current_state <= START_STATE;
                    end
                    4'd1: begin
                        write_buffer <= device_addr << 1;
                        current_state <= WRITE_STATE;
                    end
                    4'd2: begin
                        write_buffer <= reg_addr;
                        current_state <= WRITE_STATE;
                    end
                    4'd3: begin
                        current_state <= START_STATE;
                    end
                    4'd4: begin
                        write_buffer <= (device_addr << 1) | 8'h01;
                        current_state <= WRITE_STATE;
                    end
                    4'd5: begin
                        ack_state <= ACK_LOW;
                        current_state <= READ_STATE;
                    end
                    4'd6: begin
                        low_reg <= read_buffer;
                    end
                    4'd7: begin
                        ack_state <= ACK_HIGH;
                        current_state <= READ_STATE;
                    end
                    4'd8: begin
                        high_reg <= read_buffer;
                    end
                    4'd9: begin
                        current_state <= STOP_STATE;
                    end
                    4'd10: begin
                        current_state <= MAIN_STATE;
                    end
                    default: current_state <= IDLE_STATE;
                endcase
            end

            START_STATE: begin
                if (start_phase >= 3'd5) begin
                    start_phase <= 0;
                end else begin
                    start_phase <= start_phase + 1;
                end

                case (start_phase)
                    3'd0: begin
                        i2c_data_bus <= 1'b1;
                        i2c_data_clk <= 1'b1;
                    end
                    3'd1: begin
                        i2c_data_bus <= 1'b1;
                        i2c_data_clk <= 1'b1;
                    end
                    3'd2: begin
                        i2c_data_bus <= 1'b0;
                    end
                    3'd3: begin
                        i2c_data_bus <= 1'b0;
                    end
                    3'd4: begin
                        i2c_data_clk <= 1'b0;
                    end
                    3'd5: begin
                        i2c_data_clk <= 1'b0;
                        current_state <= prev_state;
                    end
                    default: current_state <= IDLE_STATE;
                endcase
            end

            WRITE_STATE: begin
                if (step_counter_1 <= 3'd6) begin
                    if (step_counter_2 >= 3'd3) begin
                        step_counter_2 <= 0;
                        step_counter_1 <= step_counter_1 + 1;
                    end else begin
                        step_counter_2 <= step_counter_2 + 1;
                    end
                end else begin
                    if (step_counter_2 >= 3'd7) begin
                        step_counter_2 <= 0;
                        step_counter_1 <= 0;
                    end else begin
                        step_counter_2 <= step_counter_2 + 1;
                    end
                end

                case (step_counter_2)
                    3'd0: begin
                        i2c_data_clk <= 1'b0;
                        i2c_data_bus <= write_buffer[(7 - step_counter_1)];
                    end
                    3'd1: begin
                        i2c_data_clk <= 1'b1;
                    end
                    3'd2: begin
                        i2c_data_clk <= 1'b1;
                    end
                    3'd3: begin
                        i2c_data_clk <= 1'b0;
                    end
                    3'd4: begin
                        i2c_data_bus <= 1'bz;
                    end
                    3'd5: begin
                        i2c_data_clk <= 1'b1;
                    end
                    3'd6: begin
                        ack_flag <= i2c_sda;
                    end
                    3'd7: begin
                        i2c_data_clk <= 1'b0;
                        if (ack_flag) begin
                            current_state <= current_state;
                        end else begin
                            current_state <= prev_state;
                        end
                    end
                    default: current_state <= IDLE_STATE;
                endcase
            end

            READ_STATE: begin
                if (step_counter_3 <= 3'd6) begin
                    if (step_counter_4 >= 3'd3) begin
                        step_counter_4 <= 0;
                        step_counter_3 <= step_counter_3 + 1;
                    end else begin
                        step_counter_4 <= step_counter_4 + 1;
                    end
                end else begin
                    if (step_counter_4 >= 3'd7) begin
                        step_counter_4 <= 0;
                        step_counter_3 <= 0;
                    end else begin
                        step_counter_4 <= step_counter_4 + 1;
                    end
                end

                case (step_counter_4)
                    3'd0: begin
                        i2c_data_clk <= 1'b0;
                        i2c_data_bus <= 1'bz;
                    end
                    3'd1: begin
                        i2c_data_clk <= 1'b1;
                    end
                    3'd2: begin
                        read_buffer[(7 - step_counter_3)] <= i2c_sda;
                    end
                    3'd3: begin
                        i2c_data_clk <= 1'b0;
                    end
                    3'd4: begin
                        i2c_data_bus <= ack_state;
                    end
                    3'd5: begin
                        i2c_data_clk <= 1'b1;
                    end
                    3'd6: begin
                        i2c_data_clk <= 1'b1;
                    end
                    3'd7: begin
                        i2c_data_clk <= 1'b0;
                        current_state <= prev_state;
                    end
                    default: current_state <= IDLE_STATE;
                endcase
            end

            STOP_STATE: begin
                if (stop_phase >= 3'd5) begin
                    stop_phase <= 0;
                end else begin
                    stop_phase <= stop_phase + 1;
                end

                case (stop_phase)
                    3'd0: begin
                        i2c_data_bus <= 1'b0;
                    end
                    3'd1: begin
                        i2c_data_bus <= 1'b0;
                    end
                    3'd2: begin
                        i2c_data_clk <= 1'b1;
                    end
                    3'd3: begin
                        i2c_data_clk <= 1'b1;
                    end
                    3'd4: begin
                        i2c_data_bus <= 1'b1;
                    end
                    3'd5: begin
                        i2c_data_bus <= 1'b1;
                        current_state <= prev_state;
                    end
                    default: current_state <= IDLE_STATE;
                endcase
            end

            DELAY_STATE: begin
                if (delay_timer >= TIMEOUT) begin
                    delay_timer <= 0;
                    current_state <= MAIN_STATE;
                end else begin
                    delay_timer <= delay_timer + 1;
                end
            end

            default:;
        endcase
    end
end

assign i2c_scl = i2c_data_clk;
assign i2c_sda = i2c_data_bus;

endmodule