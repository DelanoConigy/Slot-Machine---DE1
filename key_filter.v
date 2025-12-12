`timescale 1ns / 1ps
module key_filter
#(
    parameter CNT_MAX = 20'd999_999
)
(
    input  wire clk_i,
    input  wire rst_ni,
    input  wire key_i,
    output reg  pulse_o
);

    reg [19:0] db_cnt_r;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            db_cnt_r <= 20'd0;
        else if (key_i)
            db_cnt_r <= 20'd0;
        else if ((db_cnt_r == CNT_MAX) && !key_i)
            db_cnt_r <= db_cnt_r;
        else
            db_cnt_r <= db_cnt_r + 1'b1;
    end

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            pulse_o <= 1'b0;
        else if (db_cnt_r == (CNT_MAX - 1'b1))
            pulse_o <= 1'b1;
        else
            pulse_o <= 1'b0;
    end

endmodule



