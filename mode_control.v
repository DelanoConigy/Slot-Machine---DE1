`timescale 1ns / 1ps
module mode_control(
    input                   clk_i,
    input                   rst_ni,
    input                   start_pulse_i,
    input                   reset_pulse_i,
    input                   bet_pulse_i,
    input                   done_i,
    input                   win_i,
    output reg      [15:0]  score_o,
    output reg      [1:0]   state_o
);

    localparam [1:0] ST_RST  = 2'b00;
    localparam [1:0] ST_IDLE = 2'b01;
    localparam [1:0] ST_RUN  = 2'b10;
    localparam [1:0] ST_END  = 2'b11;

    reg [32:0] splash_wait_r;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            splash_wait_r <= 33'd0;
            score_o       <= 16'd0;
            state_o       <= ST_RST;
        end else begin
            case (state_o)
                ST_RST: begin
                    if (splash_wait_r > 33'd1500) begin
                        splash_wait_r <= splash_wait_r;
                        if (start_pulse_i) begin
                            state_o <= ST_IDLE;
                            score_o <= 16'd1000;
                        end
                    end else begin
                        splash_wait_r <= splash_wait_r + 1'b1;
                        state_o       <= ST_RST;
                        score_o       <= 16'd0;
                    end
                end

                ST_IDLE: begin
                    if (bet_pulse_i) begin
                        state_o <= ST_RUN;
                        score_o <= score_o - 16'd100;
                    end else if (reset_pulse_i) begin
                        state_o <= ST_RST;
                        score_o <= score_o;
                    end else begin
                        state_o <= ST_IDLE;
                        score_o <= score_o;
                    end
                end

                ST_RUN: begin
                    if (done_i)
                        state_o <= ST_END;
                    else
                        state_o <= ST_RUN;
                end

                ST_END: begin
                    state_o <= ST_IDLE;
                    if (win_i)
                        score_o <= score_o + 16'd100;
                    else
                        score_o <= score_o - 16'd100;
                end

                default: begin
                    state_o <= ST_RST;
                end
            endcase
        end
    end

endmodule

