module beeper(
    input               clk,
    input               rst_n,
    input               beeper_en,
    output reg          beeper
);

parameter CYCLE = 24000;
parameter CYCLE_COUNT = 6000000;

reg [15:0] freq_cnt;
reg beeper_freq;
reg [23:0] pulse_cnt;
reg pulse_active;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        freq_cnt <= 0;
        beeper_freq <= 0;
        pulse_cnt <= 0;
        pulse_active <= 0;
        beeper <= 0;
    end else begin
        // 频率生成
        if (beeper_en) begin
            if (freq_cnt < CYCLE - 1)
                freq_cnt <= freq_cnt + 1;
            else begin
                freq_cnt <= 0;
                beeper_freq <= ~beeper_freq;
            end
        end else
            beeper_freq <= 0;

        // 脉冲周期控制
        if (pulse_cnt < CYCLE_COUNT - 1)
            pulse_cnt <= pulse_cnt + 1;
        else begin
            pulse_cnt <= 0;
            pulse_active <= ~pulse_active;
        end

        beeper <= beeper_freq & beeper_en & pulse_active;
    end
end

endmodule