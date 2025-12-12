`timescale 1ns / 1ps
module prng_dice (
    input  wire       clk_i,
    input  wire       rst_ni,
    input  wire [1:0] state_i,
    output reg        done_o,
    output reg        win_o,
    output reg  [2:0] sym1_o,
    output reg  [2:0] sym2_o,
    output reg  [2:0] sym3_o,
    output reg  [2:0] sym4_o,
    output reg  [2:0] sym5_o
);

    localparam [1:0] ST_RUN = 2'b10;

    reg [31:0] run_ctr_r;

    reg [7:0]  lfsr_a_r;
    reg [7:0]  lfsr_b_r;
    reg [7:0]  lfsr_c_r;
    reg [7:0]  lfsr_d_r;
    reg [7:0]  lfsr_e_r;

    wire fb_a_w = lfsr_a_r[7] ^ lfsr_a_r[4] ^ lfsr_a_r[3] ^ lfsr_a_r[2];
    wire fb_b_w = lfsr_b_r[7] ^ lfsr_b_r[5] ^ lfsr_b_r[4] ^ lfsr_b_r[1];
    wire fb_c_w = lfsr_c_r[7] ^ lfsr_c_r[5] ^ lfsr_c_r[2] ^ lfsr_c_r[1];
    wire fb_d_w = lfsr_d_r[7] ^ lfsr_d_r[6] ^ lfsr_d_r[4];
    wire fb_e_w = lfsr_e_r[7] ^ lfsr_e_r[5] ^ lfsr_e_r[4] ^ lfsr_e_r[3];

    function [2:0] map_1_to_4;
        input [7:0] v;
        reg   [2:0] t;
        begin
            t = ((v - 8'd1) % 8'd4) + 3'd1;
            map_1_to_4 = t;
        end
    endfunction

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            lfsr_a_r <= 8'h01;
            lfsr_b_r <= 8'h01;
            lfsr_c_r <= 8'h01;
            lfsr_d_r <= 8'h01;
            lfsr_e_r <= 8'h01;
        end else begin
            lfsr_a_r <= {lfsr_a_r[6:0], fb_a_w};
            lfsr_b_r <= {lfsr_b_r[6:0], fb_b_w};
            lfsr_c_r <= {lfsr_c_r[6:0], fb_c_w};
            lfsr_d_r <= {lfsr_d_r[6:0], fb_d_w};
            lfsr_e_r <= {lfsr_e_r[6:0], fb_e_w};
        end
    end

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            run_ctr_r <= 32'd0;
            done_o    <= 1'b0;
        end else if (state_i == ST_RUN) begin
            if (run_ctr_r >= 32'd150_000_000 - 1) begin
                done_o    <= 1'b1;
                run_ctr_r <= run_ctr_r;
            end else begin
                done_o    <= 1'b0;
                run_ctr_r <= run_ctr_r + 1'b1;
            end
        end else begin
            done_o    <= 1'b0;
            run_ctr_r <= 32'd0;
        end
    end

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sym1_o <= 3'd1;
            sym2_o <= 3'd1;
            sym3_o <= 3'd1;
            sym4_o <= 3'd1;
            sym5_o <= 3'd1;
        end else if (state_i == ST_RUN) begin
            if ((run_ctr_r % 32'd500_000) == 0) begin
                sym1_o <= map_1_to_4(lfsr_a_r);
                sym2_o <= map_1_to_4(lfsr_b_r);
                sym3_o <= map_1_to_4(lfsr_c_r);
                sym4_o <= map_1_to_4(lfsr_d_r);
                sym5_o <= map_1_to_4(lfsr_e_r);
            end
        end
    end

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            win_o <= 1'b0;
        end else if (done_o) begin
            if ((sym1_o == sym2_o) && (sym1_o == sym3_o) && (sym1_o == sym4_o) && (sym1_o == sym5_o))
                win_o <= 1'b1;
            else
                win_o <= 1'b0;
        end else begin
            win_o <= 1'b0;
        end
    end

endmodule

