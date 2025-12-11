module start_screen(
    input  [9:0] x,
    input  [9:0] y,
    input        show,
    input        clk,
    output reg [23:0] vga_color
);

    // Colors
    localparam COLOR_BG = 24'h0353a4; // Blue
    localparam COLOR_FG = 24'hFFFFFF; // White

    // VGA resolution
    localparam SCREEN_W = 640;
    localparam SCREEN_H = 480;

    // BREAKOUT title
    localparam SCALE0 = 3;
    localparam LW0 = 8;
    localparam LH0 = 8;
    localparam SP0 = 2;
    localparam NL0 = 8;

    localparam BREAKOUT_W = NL0*(LW0*SCALE0) + (NL0-1)*(SP0*SCALE0);
    localparam BREAKOUT_H = LH0*SCALE0;
    localparam BREAKOUT_X = (SCREEN_W - BREAKOUT_W)/2;
    localparam BREAKOUT_Y = SCREEN_H/4;

    // Letters
    localparam [7:0] B0 = "B";
    localparam [7:0] B1 = "R";
    localparam [7:0] B2 = "E";
    localparam [7:0] B3 = "A";
    localparam [7:0] B4 = "K";
    localparam [7:0] B5 = "O";
    localparam [7:0] B6 = "U";
    localparam [7:0] B7 = "T";

    wire [7:0] BK0,BK1,BK2,BK3,BK4,BK5,BK6,BK7;
    reg  [2:0] row0;

    title f0(.clk(clk), .ascii(B0), .row(row0), .pixels(BK0));
    title f1(.clk(clk), .ascii(B1), .row(row0), .pixels(BK1));
    title f2(.clk(clk), .ascii(B2), .row(row0), .pixels(BK2));
    title f3(.clk(clk), .ascii(B3), .row(row0), .pixels(BK3));
    title f4(.clk(clk), .ascii(B4), .row(row0), .pixels(BK4));
    title f5(.clk(clk), .ascii(B5), .row(row0), .pixels(BK5));
    title f6(.clk(clk), .ascii(B6), .row(row0), .pixels(BK6));
    title f7(.clk(clk), .ascii(B7), .row(row0), .pixels(BK7));

    // Control lines 
    localparam SCALE1 = 1;
    localparam LW1 = 8;
    localparam LH1 = 8;
    localparam SP1 = 1;

    localparam [8*14-1:0] LINE1 = "START : KEY 1";
    localparam [8*14-1:0] LINE2 = "LEFT  : KEY 2";
    localparam [8*14-1:0] LINE3 = "RIGHT : KEY 3";
    localparam [8*12-1:0] LINE4 = "PAUSE : SW 1";

    localparam LINE1_LEN = 14;
    localparam LINE2_LEN = 14;
    localparam LINE3_LEN = 14;
    localparam LINE4_LEN = 12;

    // Compute max width to center horizontally
    localparam MAX_W = (LINE1_LEN>LINE2_LEN?LINE1_LEN:LINE2_LEN)>LINE3_LEN?((LINE1_LEN>LINE2_LEN?LINE1_LEN:LINE2_LEN)):LINE3_LEN;
    localparam SMALL_W = MAX_W*LW1 + (MAX_W-1)*SP1;
    localparam LINE_X  = (SCREEN_W - SMALL_W)/2;

    // Vertical stacking
    localparam LINE_Y0 = BREAKOUT_Y + BREAKOUT_H + 50;
    localparam LINE_Y1 = LINE_Y0 + LH1 + 10;
    localparam LINE_Y2 = LINE_Y1 + LH1 + 10;
    localparam LINE_Y3 = LINE_Y2 + LH1 + 10;

    // Pixel wires per line
    wire [7:0] L1_px,L2_px,L3_px,L4_px;
    reg [2:0] row1;
    reg [7:0] ascii_L1, ascii_L2, ascii_L3, ascii_L4;

    title tL1(.clk(clk), .ascii(ascii_L1), .row(row1), .pixels(L1_px));
    title tL2(.clk(clk), .ascii(ascii_L2), .row(row1), .pixels(L2_px));
    title tL3(.clk(clk), .ascii(ascii_L3), .row(row1), .pixels(L3_px));
    title tL4(.clk(clk), .ascii(ascii_L4), .row(row1), .pixels(L4_px));
    
    // Char index register
    reg [4:0] char_index; // 0–31 characters


    always @(*) begin
        vga_color = COLOR_BG;

        // BREAKOUT
        if (show && y >= BREAKOUT_Y && y < BREAKOUT_Y + BREAKOUT_H) begin
            row0 = (y - BREAKOUT_Y) / SCALE0;

            if (x >= BREAKOUT_X && x < BREAKOUT_X + LW0*SCALE0 && BK0[7 - ((x - BREAKOUT_X)/SCALE0)])
                vga_color = COLOR_FG;
            else if (x >= BREAKOUT_X + 1*(LW0*SCALE0+SP0*SCALE0) &&
                     x < BREAKOUT_X + 1*(LW0*SCALE0+SP0*SCALE0) + LW0*SCALE0 &&
                     BK1[7 - ((x - BREAKOUT_X - 1*(LW0*SCALE0+SP0*SCALE0))/SCALE0)])
                vga_color = COLOR_FG;
            else if (x >= BREAKOUT_X + 2*(LW0*SCALE0+SP0*SCALE0) &&
                     x < BREAKOUT_X + 2*(LW0*SCALE0+SP0*SCALE0) + LW0*SCALE0 &&
                     BK2[7 - ((x - BREAKOUT_X - 2*(LW0*SCALE0+SP0*SCALE0))/SCALE0)])
                vga_color = COLOR_FG;
            else if (x >= BREAKOUT_X + 3*(LW0*SCALE0+SP0*SCALE0) &&
                     x < BREAKOUT_X + 3*(LW0*SCALE0+SP0*SCALE0) + LW0*SCALE0 &&
                     BK3[7 - ((x - BREAKOUT_X - 3*(LW0*SCALE0+SP0*SCALE0))/SCALE0)])
                vga_color = COLOR_FG;
            else if (x >= BREAKOUT_X + 4*(LW0*SCALE0+SP0*SCALE0) &&
                     x < BREAKOUT_X + 4*(LW0*SCALE0+SP0*SCALE0) + LW0*SCALE0 &&
                     BK4[7 - ((x - BREAKOUT_X - 4*(LW0*SCALE0+SP0*SCALE0))/SCALE0)])
                vga_color = COLOR_FG;
            else if (x >= BREAKOUT_X + 5*(LW0*SCALE0+SP0*SCALE0) &&
                     x < BREAKOUT_X + 5*(LW0*SCALE0+SP0*SCALE0) + LW0*SCALE0 &&
                     BK5[7 - ((x - BREAKOUT_X - 5*(LW0*SCALE0+SP0*SCALE0))/SCALE0)])
                vga_color = COLOR_FG;
            else if (x >= BREAKOUT_X + 6*(LW0*SCALE0+SP0*SCALE0) &&
                     x < BREAKOUT_X + 6*(LW0*SCALE0+SP0*SCALE0) + LW0*SCALE0 &&
                     BK6[7 - ((x - BREAKOUT_X - 6*(LW0*SCALE0+SP0*SCALE0))/SCALE0)])
                vga_color = COLOR_FG;
            else if (x >= BREAKOUT_X + 7*(LW0*SCALE0+SP0*SCALE0) &&
                     x < BREAKOUT_X + 7*(LW0*SCALE0+SP0*SCALE0) + LW0*SCALE0 &&
                     BK7[7 - ((x - BREAKOUT_X - 7*(LW0*SCALE0+SP0*SCALE0))/SCALE0)])
                vga_color = COLOR_FG;
        end

        
        // SMALL CONTROL LINES 
        // LINE 1
        if (show && y >= LINE_Y0 && y < LINE_Y0 + LH1) begin
            row1 = y - LINE_Y0;
            char_index = (x - LINE_X) / (LW1 + SP1);
            if (char_index < LINE1_LEN) begin
                ascii_L1 = LINE1[8*(LINE1_LEN - char_index)-1 -: 8];
                if (x >= LINE_X + char_index*(LW1+SP1) && x < LINE_X + char_index*(LW1+SP1) + LW1 &&
                    L1_px[7 - (x - (LINE_X + char_index*(LW1+SP1)))])
                    vga_color = COLOR_FG;
            end
        end

        // LINE 2
        else if (show && y >= LINE_Y1 && y < LINE_Y1 + LH1) begin
            row1 = y - LINE_Y1;
            char_index = (x - LINE_X) / (LW1 + SP1);
            if (char_index < LINE2_LEN) begin
                ascii_L2 = LINE2[8*(LINE2_LEN - char_index)-1 -: 8];
                if (x >= LINE_X + char_index*(LW1+SP1) && x < LINE_X + char_index*(LW1+SP1) + LW1 &&
                    L2_px[7 - (x - (LINE_X + char_index*(LW1+SP1)))])
                    vga_color = COLOR_FG;
            end
        end

        // LINE 3
        else if (show && y >= LINE_Y2 && y < LINE_Y2 + LH1) begin
            row1 = y - LINE_Y2;
            char_index = (x - LINE_X) / (LW1 + SP1);
            if (char_index < LINE3_LEN) begin
                ascii_L3 = LINE3[8*(LINE3_LEN - char_index)-1 -: 8];
                if (x >= LINE_X + char_index*(LW1+SP1) && x < LINE_X + char_index*(LW1+SP1) + LW1 &&
                    L3_px[7 - (x - (LINE_X + char_index*(LW1+SP1)))])
                    vga_color = COLOR_FG;
            end
        end

        // LINE 4
		 else if (show && y >= LINE_Y3 && y < LINE_Y3 + LH1) begin
			row1 = y - LINE_Y3;
			char_index = (x - (LINE_X + LW1 + SP1)) / (LW1 + SP1); // shift right 1 char
			if (char_index < LINE4_LEN) begin
				ascii_L4 = LINE4[8*(LINE4_LEN - char_index)-1 -: 8];
					if (x >= LINE_X + (LW1 + SP1) + char_index*(LW1+SP1) && 
						x <  LINE_X + (LW1 + SP1) + char_index*(LW1+SP1) + LW1 &&
						L4_px[7 - (x - (LINE_X + (LW1 + SP1) + char_index*(LW1+SP1)))] )
						vga_color = COLOR_FG;
    end
end

    end
endmodule
