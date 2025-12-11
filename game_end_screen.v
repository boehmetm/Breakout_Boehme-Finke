module game_end_screen(
    input  [9:0] x,
    input  [9:0] y,
    input        show,
    input        clk,
    output reg [23:0] vga_color
);

    // Colors
    localparam COLOR_BG = 24'hef233c; //background
    localparam COLOR_FG = 24'hFFFFFF; // White text

    // VGA resolution
    localparam SCREEN_W = 640;
    localparam SCREEN_H = 480;

    // PLAY AGAIN? title 
    localparam SCALE0 = 3;
    localparam LW0 = 8;
    localparam LH0 = 8;
    localparam SP0 = 2;
    localparam TITLE_LEN = 11;

    localparam [8*TITLE_LEN-1:0] TITLE = "PLAY AGAIN?";
    localparam TITLE_W = TITLE_LEN*(LW0*SCALE0) + (TITLE_LEN-1)*(SP0*SCALE0);
    localparam TITLE_H = LH0*SCALE0;
    localparam TITLE_X = (SCREEN_W - TITLE_W)/2;
    localparam TITLE_Y = SCREEN_H/3;

    reg [2:0] row0;
    reg [7:0] ascii_title;
    wire [7:0] title_px;

    title t0(.clk(clk), .ascii(ascii_title), .row(row0), .pixels(title_px));

    // PRESS KEY 1 
    localparam SCALE1 = 1;
    localparam LW1 = 8;
    localparam LH1 = 8;
    localparam SP1 = 1;
    localparam LINE1_LEN = 11;
    localparam [8*LINE1_LEN-1:0] LINE1 = "PRESS KEY O";

    localparam LINE1_W = LINE1_LEN*(LW1 + SP1) - SP1;
    localparam LINE1_X = (SCREEN_W - LINE1_W)/2;
    localparam LINE1_Y = TITLE_Y + TITLE_H + 50;

    reg [2:0] row1;
    reg [7:0] ascii_L1;
    wire [7:0] L1_px;

    title tL1(.clk(clk), .ascii(ascii_L1), .row(row1), .pixels(L1_px));
	 
    reg [4:0] char_index;
	 
    always @(*) begin
        vga_color = COLOR_BG;
     
        //PLAY AGAIN? title
        if (show && y >= TITLE_Y && y < TITLE_Y + TITLE_H) begin
            row0 = (y - TITLE_Y)/SCALE0;
            char_index = (x - TITLE_X) / (LW0*SCALE0 + SP0*SCALE0);
            if (char_index < TITLE_LEN) begin
                ascii_title = TITLE[8*(TITLE_LEN-1-char_index) +: 8];
                if (x >= TITLE_X + char_index*(LW0*SCALE0 + SP0*SCALE0) &&
                    x < TITLE_X + char_index*(LW0*SCALE0 + SP0*SCALE0) + LW0*SCALE0) begin
                    if (title_px[7 - ((x - (TITLE_X + char_index*(LW0*SCALE0 + SP0*SCALE0)))/SCALE0)])
                        vga_color = COLOR_FG;
                end
            end
        end

        //PRESS KEY 1
        if (show && y >= LINE1_Y && y < LINE1_Y + LH1) begin
            row1 = y - LINE1_Y;
            char_index = (x - LINE1_X) / (LW1 + SP1);
            if (char_index < LINE1_LEN) begin
                ascii_L1 = LINE1[8*(LINE1_LEN-1-char_index) +: 8];
                if (x >= LINE1_X + char_index*(LW1 + SP1) &&
                    x < LINE1_X + char_index*(LW1 + SP1) + LW1) begin
                    if (L1_px[7 - (x - (LINE1_X + char_index*(LW1 + SP1)))])
                        vga_color = COLOR_FG;
                end
            end
        end
    end

endmodule
