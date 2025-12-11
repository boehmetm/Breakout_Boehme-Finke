module win_screen(
    input  [9:0] x,
    input  [9:0] y,
    input        show,
    input        clk,
    output reg [23:0] vga_color
);

    
    // Colors
    localparam COLOR_BG = 24'h3FA34D; // Green background
    localparam COLOR_FG = 24'hFFFFFF; // White text/smiley

    // VGA resolution
    localparam SCREEN_W = 640;
    localparam SCREEN_H = 480;

    // YOU WIN! title 
    localparam SCALE0 = 3;
    localparam LW0 = 8;
    localparam LH0 = 8;
    localparam SP0 = 2;
    localparam NL0 = 8; // max letters in line

    localparam WIN_TEXT_W = 7*(LW0*SCALE0) + 6*(SP0*SCALE0);
    localparam WIN_TEXT_H = LH0*SCALE0;
    localparam WIN_TEXT_X = (SCREEN_W - WIN_TEXT_W)/2;
    localparam WIN_TEXT_Y = SCREEN_H/3;

    // Letters
    localparam [7:0] W0 = "Y";
    localparam [7:0] W1 = "O";
    localparam [7:0] W2 = "U";
    localparam [7:0] W3 = " ";
    localparam [7:0] W4 = "W";
    localparam [7:0] W5 = "I";
    localparam [7:0] W6 = "N";
    localparam [7:0] W7 = "!";

    wire [7:0] WX0, WX1, WX2, WX4, WX5, WX6, WX7; // skip space
    reg  [2:0] row0;

    title t0(.clk(clk), .ascii(W0), .row(row0), .pixels(WX0));
    title t1(.clk(clk), .ascii(W1), .row(row0), .pixels(WX1));
    title t2(.clk(clk), .ascii(W2), .row(row0), .pixels(WX2));
    title t4(.clk(clk), .ascii(W4), .row(row0), .pixels(WX4));
    title t5(.clk(clk), .ascii(W5), .row(row0), .pixels(WX5));
    title t6(.clk(clk), .ascii(W6), .row(row0), .pixels(WX6));
    title t7(.clk(clk), .ascii(W7), .row(row0), .pixels(WX7));

    // Smiley face (8x8)
    localparam SCALE_SMILEY = 6;
    localparam SMILEY0 = 8'b00111100;
    localparam SMILEY1 = 8'b01000010;
    localparam SMILEY2 = 8'b10100101;
    localparam SMILEY3 = 8'b10000001;
    localparam SMILEY4 = 8'b10100101;
    localparam SMILEY5 = 8'b10011001;
    localparam SMILEY6 = 8'b01000010;
    localparam SMILEY7 = 8'b00111100;

    reg [7:0] smiley_row;
    reg [2:0] row_smile;

    always @(*) begin
        case(row_smile)
            0: smiley_row = SMILEY0;
            1: smiley_row = SMILEY1;
            2: smiley_row = SMILEY2;
            3: smiley_row = SMILEY3;
            4: smiley_row = SMILEY4;
            5: smiley_row = SMILEY5;
            6: smiley_row = SMILEY6;
            7: smiley_row = SMILEY7;
            default: smiley_row = 8'b0;
        endcase
    end

    // Smiley position
    localparam SMILEY_X = (SCREEN_W - 8*SCALE_SMILEY)/2;
    localparam SMILEY_Y = WIN_TEXT_Y + WIN_TEXT_H + 40;

    // Main drawing logic
    always @(*) begin
        vga_color = COLOR_BG;

        // YOU WIN! title
        if (show && y >= WIN_TEXT_Y && y < WIN_TEXT_Y + WIN_TEXT_H) begin
            row0 = (y - WIN_TEXT_Y)/SCALE0;

            // Each letter
            if (x >= WIN_TEXT_X && x < WIN_TEXT_X + LW0*SCALE0 && WX0[7 - ((x - WIN_TEXT_X)/SCALE0)])
                vga_color = COLOR_FG;
            else if (x >= WIN_TEXT_X + 1*(LW0*SCALE0+SP0*SCALE0) &&
                     x < WIN_TEXT_X + 1*(LW0*SCALE0+SP0*SCALE0) + LW0*SCALE0 &&
                     WX1[7 - ((x - WIN_TEXT_X - 1*(LW0*SCALE0+SP0*SCALE0))/SCALE0)])
                vga_color = COLOR_FG;
            else if (x >= WIN_TEXT_X + 2*(LW0*SCALE0+SP0*SCALE0) &&
                     x < WIN_TEXT_X + 2*(LW0*SCALE0+SP0*SCALE0) + LW0*SCALE0 &&
                     WX2[7 - ((x - WIN_TEXT_X - 2*(LW0*SCALE0+SP0*SCALE0))/SCALE0)])
                vga_color = COLOR_FG;
            else if (x >= WIN_TEXT_X + 4*(LW0*SCALE0+SP0*SCALE0) &&
                     x < WIN_TEXT_X + 4*(LW0*SCALE0+SP0*SCALE0) + LW0*SCALE0 &&
                     WX4[7 - ((x - WIN_TEXT_X - 4*(LW0*SCALE0+SP0*SCALE0))/SCALE0)])
                vga_color = COLOR_FG;
            else if (x >= WIN_TEXT_X + 5*(LW0*SCALE0+SP0*SCALE0) &&
                     x < WIN_TEXT_X + 5*(LW0*SCALE0+SP0*SCALE0) + LW0*SCALE0 &&
                     WX5[7 - ((x - WIN_TEXT_X - 5*(LW0*SCALE0+SP0*SCALE0))/SCALE0)])
                vga_color = COLOR_FG;
            else if (x >= WIN_TEXT_X + 6*(LW0*SCALE0+SP0*SCALE0) &&
                     x < WIN_TEXT_X + 6*(LW0*SCALE0+SP0*SCALE0) + LW0*SCALE0 &&
                     WX6[7 - ((x - WIN_TEXT_X - 6*(LW0*SCALE0+SP0*SCALE0))/SCALE0)])
                vga_color = COLOR_FG;
            else if (x >= WIN_TEXT_X + 7*(LW0*SCALE0+SP0*SCALE0) &&
                     x < WIN_TEXT_X + 7*(LW0*SCALE0+SP0*SCALE0) + LW0*SCALE0 &&
                     WX7[7 - ((x - WIN_TEXT_X - 7*(LW0*SCALE0+SP0*SCALE0))/SCALE0)])
                vga_color = COLOR_FG;
        end

        // Smiley
        if (show && y >= SMILEY_Y && y < SMILEY_Y + 8*SCALE_SMILEY &&
            x >= SMILEY_X && x < SMILEY_X + 8*SCALE_SMILEY) begin
            row_smile = (y - SMILEY_Y)/SCALE_SMILEY;
            if (smiley_row[7 - ((x - SMILEY_X)/SCALE_SMILEY)])
                vga_color = COLOR_FG;
        end
    end
endmodule
