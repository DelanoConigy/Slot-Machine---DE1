`timescale 1ns/1ps
module vga_display(
    input                   pix_clk_i,
    input                   rst_ni,

    input       [15:0]      score_i,
    input       [1:0]       state_i,

    output      [9:0]       x_o,
    output      [9:0]       y_o,

    input       [2:0]       sym1_i,
    input       [2:0]       sym2_i,
    input       [2:0]       sym3_i,
    input       [2:0]       sym4_i,
    input       [2:0]       sym5_i,

    output reg              hs_o,
    output reg              vs_o,
    output reg  [23:0]      rgb_o,
    output                  blank_n_o
);

    // -------------------- Game states --------------------
    localparam [1:0] ST_RST  = 2'b00;
    localparam [1:0] ST_IDLE = 2'b01;
    localparam [1:0] ST_RUN  = 2'b10;
    localparam [1:0] ST_END  = 2'b11;

    // -------------------- Colors (24-bit RGB) --------------------
    localparam [23:0] C_RED    = 24'hFF0000;
    localparam [23:0] C_GREEN  = 24'h00FF00;
    localparam [23:0] C_BLUE   = 24'h0000FF;
    localparam [23:0] C_YELLOW = 24'hFFFF00;
    localparam [23:0] C_PINK   = 24'hFF00FF;
    localparam [23:0] C_WHITE  = 24'hFFFFFF;
    localparam [23:0] C_BLACK  = 24'h000000;

    // -------------------- VGA 640x480@60 timing --------------------
    parameter HS_PW   = 96;
    parameter HS_BP   = 48;
    parameter HS_ACT  = 640;
    parameter HS_FP   = 16;
    parameter HS_TOT  = 800;

    parameter VS_PW   = 2;
    parameter VS_BP   = 33;
    parameter VS_ACT  = 480;
    parameter VS_FP   = 10;
    parameter VS_TOT  = 525;

    parameter HCTR_W  = 10;
    parameter VCTR_W  = 10;

    // -------------------- Layout constants --------------------
    parameter PIC_H = 120;
    parameter PIC_W = 160;

    parameter GLYPH_W       = 8;
    parameter GLYPH_H       = 16;
    parameter BIGWORD_W     = 40;
    localparam [10:0] HUD_X0      = 11'd33;
    localparam [10:0] HUD_Y0      = 11'd33;
    localparam [10:0] HUD_W       = 11'd88;
    localparam [10:0] SLOT_W      = 11'd64;
    localparam [10:0] HUD_H       = 11'd16;
    localparam [10:0] BIG_X0      = 11'd10;
    localparam [10:0] BIG_Y0      = 11'd120;

    // -------------------- VGA counters --------------------
    reg  [HCTR_W-1:0] h_ctr_r;
    reg  [VCTR_W-1:0] v_ctr_r;

    wire h_vis_w, v_vis_w, vis_w;

    assign h_vis_w = (h_ctr_r > (HS_PW + HS_BP - 1)) && (h_ctr_r < (HS_TOT - HS_FP));
    assign v_vis_w = (v_ctr_r > (VS_PW + VS_BP - 1)) && (v_ctr_r < (VS_TOT - VS_FP));
    assign vis_w   = h_vis_w && v_vis_w;

    assign blank_n_o = vis_w;

    assign x_o = vis_w ? (h_ctr_r - (HS_PW + HS_BP - 1'b1)) : 10'd0;
    assign y_o = vis_w ? (v_ctr_r - (VS_PW + VS_BP - 1'b1)) : 10'd0;

    always @(posedge pix_clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            h_ctr_r <= {HCTR_W{1'b0}};
        end else begin
            if (h_ctr_r == HS_TOT - 1)
                h_ctr_r <= {HCTR_W{1'b0}};
            else
                h_ctr_r <= h_ctr_r + 1'b1;
        end
    end

    always @(posedge pix_clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            v_ctr_r <= {VCTR_W{1'b0}};
        end else if (h_ctr_r == HS_TOT - 1) begin
            if (v_ctr_r == VS_TOT - 1)
                v_ctr_r <= {VCTR_W{1'b0}};
            else
                v_ctr_r <= v_ctr_r + 1'b1;
        end
    end

    always @(posedge pix_clk_i or negedge rst_ni) begin
        if (!rst_ni) hs_o <= 1'b1;
        else        hs_o <= (h_ctr_r < HS_PW) ? 1'b0 : 1'b1;
    end

    always @(posedge pix_clk_i or negedge rst_ni) begin
        if (!rst_ni) vs_o <= 1'b1;
        else        vs_o <= (v_ctr_r < VS_PW) ? 1'b0 : 1'b1;
    end

    // -------------------- Score digits --------------------
    wire [3:0] d0_w, d1_w, d2_w, d3_w;
    assign d0_w = score_i % 4'd10;
    assign d1_w = (score_i / 4'd10)    % 4'd10;
    assign d2_w = (score_i / 7'd100)   % 4'd10;
    assign d3_w = (score_i / 10'd1000) % 4'd10;

    // -------------------- 8x16 font table --------------------
    reg [127:0] font_lut_r [16:0];
    always @(posedge pix_clk_i) begin
        font_lut_r[0]  <= 128'h00000018244242424242424224180000;
        font_lut_r[1]  <= 128'h000000107010101010101010107C0000;
        font_lut_r[2]  <= 128'h0000003C4242420404081020427E0000;
        font_lut_r[3]  <= 128'h0000003C424204180402024244380000;
        font_lut_r[4]  <= 128'h000000040C14242444447E04041E0000;
        font_lut_r[5]  <= 128'h0000007E404040586402024244380000;
        font_lut_r[6]  <= 128'h0000001C244040586442424224180000;
        font_lut_r[7]  <= 128'h0000007E444408081010101010100000;
        font_lut_r[8]  <= 128'h0000003C4242422418244242423C0000;
        font_lut_r[9]  <= 128'h0000001824424242261A020224380000;

        font_lut_r[10] <= 128'h000000000000003E42403C02427C0000;
        font_lut_r[11] <= 128'h000000000000001C22404040221C0000;
        font_lut_r[12] <= 128'h000000000000003C42424242423C0000;
        font_lut_r[13] <= 128'h00000000000000EE3220202020F80000;
        font_lut_r[14] <= 128'h000000000000003C42427E40423C0000;
        font_lut_r[15] <= 128'h000000000000003E42403C02427C0000;
        font_lut_r[16] <= 128'h00000000000018180000000018180000;
    end

    // -------------------- "START" big text --------------------
    reg [127:0] big_txt_r [10:0];
    always @(posedge pix_clk_i) begin
        big_txt_r[0] <= 128'h0000003E4242402018040242427C0000;
        big_txt_r[1] <= 128'h000000FE921010101010101010380000;
        big_txt_r[2] <= 128'h0000001010182828243C444242E70000;
        big_txt_r[3] <= 128'h000000FC4242427C4848444442E30000;
        big_txt_r[4] <= 128'h000000FE921010101010101010380000;
    end

    // -------------------- 64x64 shape ROM address --------------------
    reg  [11:0] rom_addr_r;

    wire win1_w = (y_o >  90 && y_o < 155) && (x_o > 240 && x_o < (240 + SLOT_W + 1));
    wire win2_w = (y_o > 164 && y_o < 229) && (x_o > 240 && x_o < (240 + SLOT_W + 1));
    wire win3_w = (y_o > 238 && y_o < 303) && (x_o > 240 && x_o < (240 + SLOT_W + 1));
    wire win4_w = (y_o > 312 && y_o < 377) && (x_o > 240 && x_o < (240 + SLOT_W + 1));
    wire win5_w = (y_o > 386 && y_o < 451) && (x_o > 240 && x_o < (240 + SLOT_W + 1));

    always @(posedge pix_clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rom_addr_r <= 12'd0;
        end else if (rom_addr_r >= (64*64)) begin
            rom_addr_r <= 12'd0;
        end else if (win1_w || win2_w || win3_w || win4_w || win5_w) begin
            rom_addr_r <= rom_addr_r + 1'b1;
        end
    end

    // -------------------- Center-picture address counter --------------------
    reg  [27:0] splash_ctr_r;
    reg  [27:0] spare_ctr_r;
    reg  [14:0] pic_addr_r;

    wire pic_wrap_w;
    wire pic_x_ok_w, pic_y_ok_w;
    wire pic_en_w;

    assign pic_wrap_w = (pic_addr_r == (PIC_H*PIC_W - 1));
    assign pic_x_ok_w = (x_o > ((640 - PIC_W)/2))  && (x_o < (((640 - PIC_W)/2) + PIC_W + 1));
    assign pic_y_ok_w = (y_o > ((480 - PIC_H)/2))  && (y_o < (((480 - PIC_H)/2) + PIC_H + 1));
    assign pic_en_w   = pic_x_ok_w && pic_y_ok_w;

    always @(posedge pix_clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            pic_addr_r <= 15'd0;
        end else if (pic_wrap_w) begin
            pic_addr_r <= 15'd0;
        end else if (pic_en_w) begin
            pic_addr_r <= pic_addr_r + 1'b1;
        end
    end

    // -------------------- Shape ROMs --------------------
    wire [23:0] img_bar_w, img_0_w, img_7_w, img_diamond_w, img_square_w;

    horizontal_bar u_rom_bar     (.address(rom_addr_r), .clock(pix_clk_i), .q(img_bar_w));
    num_0          u_rom_0       (.address(rom_addr_r), .clock(pix_clk_i), .q(img_0_w));
    num_7          u_rom_7       (.address(rom_addr_r), .clock(pix_clk_i), .q(img_7_w));
    rhombus        u_rom_diamond (.address(rom_addr_r), .clock(pix_clk_i), .q(img_diamond_w));
    square         u_rom_square  (.address(rom_addr_r), .clock(pix_clk_i), .q(img_square_w));

    function [23:0] sel_shape_px;
        input [2:0] sel_i;
        begin
            case (sel_i)
                3'd1: sel_shape_px = img_bar_w;
                3'd2: sel_shape_px = img_0_w;
                3'd3: sel_shape_px = img_7_w;
                3'd4: sel_shape_px = img_diamond_w;
                3'd5: sel_shape_px = img_square_w;
                default: sel_shape_px = C_BLACK;
            endcase
        end
    endfunction

    reg [23:0] slot_px1_r, slot_px2_r, slot_px3_r, slot_px4_r, slot_px5_r;
    always @(*) begin
        slot_px1_r = sel_shape_px(sym1_i);
        slot_px2_r = sel_shape_px(sym2_i);
        slot_px3_r = sel_shape_px(sym3_i);
        slot_px4_r = sel_shape_px(sym4_i);
        slot_px5_r = sel_shape_px(sym5_i);
    end

    function glyph_hit_fn;
        input [127:0] glyph_i;
        input [10:0]  gx0_i;
        input [10:0]  gy0_i;
        input [10:0]  px_i;
        input [10:0]  py_i;
        reg   [10:0]  dx_r;
        reg   [10:0]  dy_r;
        reg   [10:0]  idx_r;
        begin
            if (px_i < gx0_i || px_i >= gx0_i + GLYPH_W || py_i < gy0_i || py_i >= gy0_i + GLYPH_H) begin
                glyph_hit_fn = 1'b0;
            end else begin
                dx_r = px_i - gx0_i;
                dy_r = (gy0_i + GLYPH_H) - py_i;
                idx_r = dy_r*GLYPH_W - (dx_r % GLYPH_W) - 1'b1;
                glyph_hit_fn = glyph_i[idx_r];
            end
        end
    endfunction

    reg [23:0] px_rgb_next_r;

    task automatic draw_small_glyph;
        input [127:0] g_i;
        input [10:0]  bx_i;
        input [10:0]  by_i;
        begin
            if (glyph_hit_fn(g_i, bx_i, by_i, x_o, y_o))
                px_rgb_next_r = C_WHITE;
            else
                px_rgb_next_r = C_BLACK;
        end
    endtask

    task automatic draw_big_word;
        integer k;
        reg [10:0] gx_r;
        begin
            px_rgb_next_r = C_BLACK;
            for (k = 0; k < 5; k = k + 1) begin
                gx_r = BIG_X0 - 1'b1 + (BIGWORD_W/5)*k;

                if ((x_o >= gx_r) &&
                    (x_o <  (BIG_X0 + (BIGWORD_W/5)*(k+1) - 1'b1)) &&
                    (y_o >= BIG_Y0) &&
                    (y_o <  (BIG_Y0 + GLYPH_H))) begin

                    if (big_txt_r[k][(GLYPH_H + BIG_Y0 - y_o)*GLYPH_W - (x_o - gx_r) - 1'b1])
                        px_rgb_next_r = C_WHITE;
                    else
                        px_rgb_next_r = C_BLACK;
                end
            end
        end
    endtask

    task automatic draw_hud_score;
        reg [10:0] cell_w_r;
        begin
            cell_w_r = (HUD_W/11);
            px_rgb_next_r = C_BLACK;

            if      (x_o >= HUD_X0 - 1'b1 && x_o < HUD_X0 + cell_w_r*1  - 1'b1 &&
                     y_o >= HUD_Y0        && y_o < HUD_Y0 + HUD_H)
                draw_small_glyph(font_lut_r[10], HUD_X0-1'b1,               HUD_Y0);

            else if (x_o >= HUD_X0 + cell_w_r*1 - 1'b1 && x_o < HUD_X0 + cell_w_r*2 - 1'b1 &&
                     y_o >= HUD_Y0                    && y_o < HUD_Y0 + HUD_H)
                draw_small_glyph(font_lut_r[11], HUD_X0-1'b1 + cell_w_r*1,  HUD_Y0);

            else if (x_o >= HUD_X0 + cell_w_r*2 - 1'b1 && x_o < HUD_X0 + cell_w_r*3 - 1'b1 &&
                     y_o >= HUD_Y0                    && y_o < HUD_Y0 + HUD_H)
                draw_small_glyph(font_lut_r[12], HUD_X0-1'b1 + cell_w_r*2,  HUD_Y0);

            else if (x_o >= HUD_X0 + cell_w_r*3 - 1'b1 && x_o < HUD_X0 + cell_w_r*4 - 1'b1 &&
                     y_o >= HUD_Y0                    && y_o < HUD_Y0 + HUD_H)
                draw_small_glyph(font_lut_r[13], HUD_X0-1'b1 + cell_w_r*3,  HUD_Y0);

            else if (x_o >= HUD_X0 + cell_w_r*4 - 1'b1 && x_o < HUD_X0 + cell_w_r*5 - 1'b1 &&
                     y_o >= HUD_Y0                    && y_o < HUD_Y0 + HUD_H)
                draw_small_glyph(font_lut_r[14], HUD_X0-1'b1 + cell_w_r*4,  HUD_Y0);

            else if (x_o >= HUD_X0 + cell_w_r*5 - 1'b1 && x_o < HUD_X0 + cell_w_r*6 - 1'b1 &&
                     y_o >= HUD_Y0                    && y_o < HUD_Y0 + HUD_H)
                draw_small_glyph(font_lut_r[15], HUD_X0-1'b1 + cell_w_r*5,  HUD_Y0);

            else if (x_o >= HUD_X0 + cell_w_r*6 - 1'b1 && x_o < HUD_X0 + cell_w_r*7 - 1'b1 &&
                     y_o >= HUD_Y0                    && y_o < HUD_Y0 + HUD_H)
                draw_small_glyph(font_lut_r[16], HUD_X0-1'b1 + cell_w_r*6,  HUD_Y0);

            else if (x_o >= HUD_X0 + cell_w_r*7 - 1'b1 && x_o < HUD_X0 + cell_w_r*8 - 1'b1 &&
                     y_o >= HUD_Y0                    && y_o < HUD_Y0 + HUD_H)
                draw_small_glyph(font_lut_r[d3_w], HUD_X0-1'b1 + cell_w_r*7,  HUD_Y0);

            else if (x_o >= HUD_X0 + cell_w_r*8 - 1'b1 && x_o < HUD_X0 + cell_w_r*9 - 1'b1 &&
                     y_o >= HUD_Y0                    && y_o < HUD_Y0 + HUD_H)
                draw_small_glyph(font_lut_r[d2_w], HUD_X0-1'b1 + cell_w_r*8,  HUD_Y0);

            else if (x_o >= HUD_X0 + cell_w_r*9 - 1'b1 && x_o < HUD_X0 + cell_w_r*10 - 1'b1 &&
                     y_o >= HUD_Y0                    && y_o < HUD_Y0 + HUD_H)
                draw_small_glyph(font_lut_r[d1_w], HUD_X0-1'b1 + cell_w_r*9,  HUD_Y0);

            else if (x_o >= HUD_X0 + cell_w_r*10 - 1'b1 && x_o < HUD_X0 + cell_w_r*11 - 1'b1 &&
                     y_o >= HUD_Y0                     && y_o < HUD_Y0 + HUD_H)
                draw_small_glyph(font_lut_r[d0_w], HUD_X0-1'b1 + cell_w_r*10, HUD_Y0);
        end
    endtask

    always @(*) begin
        px_rgb_next_r = C_BLACK;

        if (state_i == ST_RST) begin
            if (splash_ctr_r < 150_000_000) begin
                px_rgb_next_r = C_BLACK;
            end else begin
                draw_big_word();
            end
        end
        else if ((state_i == ST_RUN) || (state_i == ST_IDLE)) begin
            draw_hud_score();

            if (px_rgb_next_r == C_BLACK) begin
                if      (win1_w) px_rgb_next_r = slot_px1_r;
                else if (win3_w) px_rgb_next_r = slot_px3_r;
                else if (win5_w) px_rgb_next_r = slot_px5_r;
                else             px_rgb_next_r = C_BLACK;
            end
        end
        else if (state_i == ST_END) begin
            draw_hud_score();

            if (px_rgb_next_r == C_BLACK) begin
                if      (win1_w) px_rgb_next_r = slot_px1_r;
                else if (win3_w) px_rgb_next_r = slot_px3_r;
                else if (win5_w) px_rgb_next_r = slot_px5_r;
                else             px_rgb_next_r = C_BLACK;
            end

            if (px_rgb_next_r == C_BLACK) begin
                if ((x_o >= BIG_X0 - 1'b1) && (x_o < BIG_X0 + 192/6*1 - 1'b1) &&
                    (y_o >= BIG_Y0)       && (y_o < BIG_Y0 + GLYPH_H)) begin
                    px_rgb_next_r = big_txt_r[5][(GLYPH_H + BIG_Y0 - y_o)*GLYPH_W - (x_o-(BIG_X0-1'b1)) - 1'b1] ? C_WHITE : C_BLACK;
                end
                else if ((x_o >= BIG_X0 + 192/6*1 - 1'b1) && (x_o < BIG_X0 + 192/6*2 - 1'b1) &&
                         (y_o >= BIG_Y0)                 && (y_o < BIG_Y0 + GLYPH_H)) begin
                    px_rgb_next_r = big_txt_r[6][(GLYPH_H + BIG_Y0 - y_o)*GLYPH_W - (x_o-(BIG_X0-1'b1+192/6*1)) - 1'b1] ? C_WHITE : C_BLACK;
                end
                else if ((x_o >= BIG_X0 + 192/6*2 - 1'b1) && (x_o < BIG_X0 + 192/6*3 - 1'b1) &&
                         (y_o >= BIG_Y0)                 && (y_o < BIG_Y0 + GLYPH_H)) begin
                    px_rgb_next_r = big_txt_r[7][(GLYPH_H + BIG_Y0 - y_o)*GLYPH_W - (x_o-(BIG_X0-1'b1+192/6*2)) - 1'b1] ? C_WHITE : C_BLACK;
                end
                else if ((x_o >= BIG_X0 + 192/6*3 - 1'b1) && (x_o < BIG_X0 + 192/6*4 - 1'b1) &&
                         (y_o >= BIG_Y0)                 && (y_o < BIG_Y0 + GLYPH_H)) begin
                    px_rgb_next_r = big_txt_r[8][(GLYPH_H + BIG_Y0 - y_o)*GLYPH_W - (x_o-(BIG_X0-1'b1+192/6*3)) - 1'b1] ? C_WHITE : C_BLACK;
                end
                else if ((x_o >= BIG_X0 + 192/6*4 - 1'b1) && (x_o < BIG_X0 + 192/6*5 - 1'b1) &&
                         (y_o >= BIG_Y0)                 && (y_o < BIG_Y0 + GLYPH_H)) begin
                    px_rgb_next_r = big_txt_r[9][(GLYPH_H + BIG_Y0 - y_o)*GLYPH_W - (x_o-(BIG_X0-1'b1+192/6*4)) - 1'b1] ? C_WHITE : C_BLACK;
                end
                else if ((x_o >= BIG_X0 + 192/6*4 - 1'b1) && (x_o < BIG_X0 + 192/6*5 - 1'b1) &&
                         (y_o >= BIG_Y0)                 && (y_o < BIG_Y0 + GLYPH_H)) begin
                    px_rgb_next_r = big_txt_r[10][(GLYPH_H + BIG_Y0 - y_o)*GLYPH_W - (x_o-(BIG_X0-1'b1+192/6*4)) - 1'b1] ? C_WHITE : C_BLACK;
                end
            end
        end
        else begin
            px_rgb_next_r = C_BLACK;
        end
    end

    always @(posedge pix_clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rgb_o        <= C_BLACK;
            splash_ctr_r <= 28'd0;
            spare_ctr_r  <= 28'd0;
        end else begin
            if (state_i == ST_RST) begin
                spare_ctr_r <= 28'd0;
                if (splash_ctr_r < 150_000_000)
                    splash_ctr_r <= splash_ctr_r + 1'b1;
            end else begin
                splash_ctr_r <= splash_ctr_r;
                spare_ctr_r  <= spare_ctr_r;
            end

            rgb_o <= px_rgb_next_r;
        end
    end

endmodule



	