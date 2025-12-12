`timescale 1ns / 1ps
module top(
    input         CLOCK_50,
    input  [2:0]  KEY,

    output [7:0]  VGA_R,
    output [7:0]  VGA_G,
    output [7:0]  VGA_B,
    output        VGA_HS,
    output        VGA_VS,
    output        VGA_CLK,
    output        VGA_BLANK_N,
    output        VGA_SYNC_N
);

    wire pll_ok_w;
    wire rst_ni_w;

    wire clk50_w;
    wire clk25_w;

    wire start_pulse_w;
    wire bet_pulse_w;

    wire done_w;
    wire win_w;

    wire [15:0] score_w;
    wire [1:0]  state_w;

    wire [2:0] sym1_w, sym2_w, sym3_w, sym4_w, sym5_w;

    assign VGA_CLK    = clk25_w;
    assign VGA_SYNC_N = 1'b0;

    assign rst_ni_w = KEY[2] & pll_ok_w;

    pll u_pll (
        .refclk   (CLOCK_50),
        .rst      (~KEY[2]),
        .outclk_0 (clk50_w),
        .outclk_1 (clk25_w),
        .locked   (pll_ok_w)
    );

    key_filter #(.CNT_MAX(20'd5000)) u_key_start (
        .clk_i   (clk25_w),
        .rst_ni  (rst_ni_w),
        .key_i   (KEY[0]),
        .pulse_o (start_pulse_w)
    );

    key_filter #(.CNT_MAX(20'd5000)) u_key_bet (
        .clk_i   (clk25_w),
        .rst_ni  (rst_ni_w),
        .key_i   (KEY[1]),
        .pulse_o (bet_pulse_w)
    );

    prng_dice u_rng (
        .clk_i   (clk25_w),
        .rst_ni  (rst_ni_w),
        .state_i (state_w),
        .done_o  (done_w),
        .win_o   (win_w),
        .sym1_o  (sym1_w),
        .sym2_o  (sym2_w),
        .sym3_o  (sym3_w),
        .sym4_o  (sym4_w),
        .sym5_o  (sym5_w)
    );

    mode_control u_fsm (
        .clk_i          (clk25_w),
        .rst_ni         (rst_ni_w),
        .start_pulse_i  (start_pulse_w),
        .reset_pulse_i  (1'b0),
        .bet_pulse_i    (bet_pulse_w),
        .done_i         (done_w),
        .win_i          (win_w),
        .score_o        (score_w),
        .state_o        (state_w)
    );

    vga_display u_vga (
        .pix_clk_i  (clk25_w),
        .rst_ni     (rst_ni_w),

        .score_i    (score_w),
        .state_i    (state_w),

        .x_o        (),
        .y_o        (),

        .sym1_i     (sym1_w),
        .sym2_i     (sym2_w),
        .sym3_i     (sym3_w),
        .sym4_i     (sym4_w),
        .sym5_i     (sym5_w),

        .hs_o       (VGA_HS),
        .vs_o       (VGA_VS),
        .rgb_o      ({VGA_R, VGA_G, VGA_B}),
        .blank_n_o  (VGA_BLANK_N)
    );

endmodule

