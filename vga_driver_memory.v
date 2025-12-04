module vga_driver_memory (
input CLOCK_50,

output [6:0] HEX0,
output [6:0] HEX1,
output [6:0] HEX2,
output [6:0] HEX3,

input [3:0] KEY,

output [9:0] LEDR,

input [9:0] SW,

output VGA_BLANK_N,
output reg [7:0] VGA_B,
output VGA_CLK,
output reg [7:0] VGA_G,
output VGA_HS,
output reg [7:0] VGA_R,
output VGA_SYNC_N,
output VGA_VS
);

  // Turn off all displays.
assign HEX0 = 7'h00;
assign HEX1 = 7'h00;
assign HEX2 = 7'h00;
assign HEX3 = 7'h00;

wire active_pixels;
wire [9:0]x;
wire [9:0]y;


wire clk;
wire rst;

assign clk = CLOCK_50;
assign rst = SW[0];

assign LEDR[0] = active_pixels;
assign LEDR[1] = (x < 10'd320);

vga_driver the_vga(
.clk(clk),
.rst(rst),
.vga_clk(VGA_CLK),
.hsync(VGA_HS),
.vsync(VGA_VS),
.active_pixels(active_pixels),
.xPixel(x),
.yPixel(y),
.VGA_BLANK_N(VGA_BLANK_N),
.VGA_SYNC_N(VGA_SYNC_N)
);

// ============ PARAMETERS ======================
localparam integer FRAME_W = 300;
localparam integer FRAME_H = 350;
localparam integer FRAME_THICK = 3;

localparam integer BLOCK_W = 40;
localparam integer BLOCK_H = 15;

localparam integer PADDLE_W = 80;
localparam integer PADDLE_H = 10;
localparam integer PADDLE_MARGIN = 8;
localparam integer MOVE_STEP = 4;

localparam integer BALL_RADIUS = 6;
localparam integer INIT_VX = 3;
localparam integer INIT_VY = 2;

localparam [23:0] COLOR_BG = 24'h000000;
localparam [23:0] COLOR_FRAME = 24'h0000FF;
localparam [23:0] COLOR_BALL = 24'hFF0000;
localparam [23:0] COLOR_PADDLE = 24'hFFFFFF;

localparam [23:0] COLOR_ROW1 = 24'hFFADAD;  
localparam [23:0] COLOR_ROW2 = 24'hFDFFB6;  
localparam [23:0] COLOR_ROW3 = 24'hCAFFBF;  
localparam [23:0] COLOR_ROW4 = 24'h9BF6FF;  
localparam [23:0] COLOR_ROW5 = 24'hBDB2FF;

localparam [23:0] COLOR_GAMEOVER = 24'hFF0000;
localparam [23:0] COLOR_WINNER = 24'h00FF00;

localparam [9:0] MIN_ACTIVE_X = 10'd100;
localparam [9:0] MAX_ACTIVE_X = 10'd539;
localparam [9:0] MIN_ACTIVE_Y = 10'd40;
localparam [9:0] MAX_ACTIVE_Y = 10'd439;

localparam [9:0] FRAME_X_MAX =
    MIN_ACTIVE_X +
    ( (MAX_ACTIVE_X >= (FRAME_W- 10'd3)) *
      (MAX_ACTIVE_X - (FRAME_W - 10'd3)) );

localparam [9:0] FRAME_Y_MAX =
    MIN_ACTIVE_Y +
    ( (MAX_ACTIVE_Y >= (FRAME_H - 10'd3)) *
      (MAX_ACTIVE_Y - (FRAME_H - 10'd3)) );

localparam [9:0] FRAME_X0 = MIN_ACTIVE_X + ((FRAME_X_MAX - MIN_ACTIVE_X) >> 1);
localparam [9:0] FRAME_Y0 = MIN_ACTIVE_Y + ((FRAME_Y_MAX - MIN_ACTIVE_Y) >> 1);

localparam integer BALL_R2 = BALL_RADIUS * BALL_RADIUS;

localparam integer PADDLE_R = (PADDLE_H >> 1);
localparam integer PADDLE_HALF = (PADDLE_W >> 1);
localparam integer PADDLE_RECT_HALF = PADDLE_HALF - PADDLE_R;
localparam integer PADDLE_R2 = PADDLE_R * PADDLE_R;

// ================= STATE ======================
reg [9:0] frame_x, frame_y;
reg [9:0] paddle_x, paddle_y;

reg [12:0] bx, by;
reg [8:0] vx_mag;
reg vx_dir;
reg [8:0] vy_mag;
reg vy_dir;

reg prev_vga_vs;
wire frame_tick = (~prev_vga_vs) & VGA_VS;

wire [11:0] paddle_min_cx = frame_x + FRAME_THICK + PADDLE_HALF;
wire [11:0] paddle_max_cx = frame_x + FRAME_W - FRAME_THICK - PADDLE_HALF;

wire [11:0] inner_min_x = frame_x + FRAME_THICK + BALL_RADIUS;
wire [11:0] inner_max_x = frame_x + FRAME_W - FRAME_THICK - BALL_RADIUS;
wire [11:0] inner_min_y = frame_y + FRAME_THICK + BALL_RADIUS;
wire [11:0] inner_max_y = frame_y + FRAME_H - FRAME_THICK - BALL_RADIUS;

reg game_over;
reg winner;

// ================= BLOCK POSITIONS (ROW 1)======================
localparam integer BLOCK1_X = FRAME_X0 + FRAME_THICK + 30;
localparam integer BLOCK1_Y = FRAME_Y0 + FRAME_THICK + 20;

localparam integer BLOCK2_X = FRAME_X0 + FRAME_THICK + 80;
localparam integer BLOCK2_Y = FRAME_Y0 + FRAME_THICK + 20;

localparam integer BLOCK3_X = FRAME_X0 + FRAME_THICK + 130;
localparam integer BLOCK3_Y = FRAME_Y0 + FRAME_THICK + 20;

localparam integer BLOCK4_X = FRAME_X0 + FRAME_THICK + 180;
localparam integer BLOCK4_Y = FRAME_Y0 + FRAME_THICK + 20;

localparam integer BLOCK5_X = FRAME_X0 + FRAME_THICK + 230;
localparam integer BLOCK5_Y = FRAME_Y0 + FRAME_THICK + 20;

reg block1_active, block2_active, block3_active, block4_active, block5_active;

// ================= BLOCK POSITIONS (ROW 2)======================
localparam integer BLOCK6_X = FRAME_X0 + FRAME_THICK + 30;
localparam integer BLOCK6_Y = FRAME_Y0 + FRAME_THICK + 40;

localparam integer BLOCK7_X = FRAME_X0 + FRAME_THICK + 80;
localparam integer BLOCK7_Y = FRAME_Y0 + FRAME_THICK + 40;

localparam integer BLOCK8_X = FRAME_X0 + FRAME_THICK + 130;
localparam integer BLOCK8_Y = FRAME_Y0 + FRAME_THICK + 40;

localparam integer BLOCK9_X = FRAME_X0 + FRAME_THICK + 180;
localparam integer BLOCK9_Y = FRAME_Y0 + FRAME_THICK + 40;

localparam integer BLOCK10_X = FRAME_X0 + FRAME_THICK + 230;
localparam integer BLOCK10_Y = FRAME_Y0 + FRAME_THICK + 40;

reg block6_active, block7_active, block8_active, block9_active, block10_active;

// ================= BLOCK POSITIONS (ROW 3)======================
localparam integer BLOCK11_X = FRAME_X0 + FRAME_THICK + 30;
localparam integer BLOCK11_Y = FRAME_Y0 + FRAME_THICK + 60;

localparam integer BLOCK12_X = FRAME_X0 + FRAME_THICK + 80;
localparam integer BLOCK12_Y = FRAME_Y0 + FRAME_THICK + 60;

localparam integer BLOCK13_X = FRAME_X0 + FRAME_THICK + 130;
localparam integer BLOCK13_Y = FRAME_Y0 + FRAME_THICK + 60;

localparam integer BLOCK14_X = FRAME_X0 + FRAME_THICK + 180;
localparam integer BLOCK14_Y = FRAME_Y0 + FRAME_THICK + 60;

localparam integer BLOCK15_X = FRAME_X0 + FRAME_THICK + 230;
localparam integer BLOCK15_Y = FRAME_Y0 + FRAME_THICK + 60;

reg block11_active, block12_active, block13_active, block14_active, block15_active;

// ================= BLOCK POSITIONS (ROW 4)======================
localparam integer BLOCK16_X = FRAME_X0 + FRAME_THICK + 30;
localparam integer BLOCK16_Y = FRAME_Y0 + FRAME_THICK + 80;

localparam integer BLOCK17_X = FRAME_X0 + FRAME_THICK + 80;
localparam integer BLOCK17_Y = FRAME_Y0 + FRAME_THICK + 80;

localparam integer BLOCK18_X = FRAME_X0 + FRAME_THICK + 130;
localparam integer BLOCK18_Y = FRAME_Y0 + FRAME_THICK + 80;

localparam integer BLOCK19_X = FRAME_X0 + FRAME_THICK + 180;
localparam integer BLOCK19_Y = FRAME_Y0 + FRAME_THICK + 80;

localparam integer BLOCK20_X = FRAME_X0 + FRAME_THICK + 230;
localparam integer BLOCK20_Y = FRAME_Y0 + FRAME_THICK + 80;

reg block16_active, block17_active, block18_active, block19_active, block20_active;

// ================= BLOCK POSITIONS (ROW 5)======================
localparam integer BLOCK21_X = FRAME_X0 + FRAME_THICK + 30;
localparam integer BLOCK21_Y = FRAME_Y0 + FRAME_THICK + 100;

localparam integer BLOCK22_X = FRAME_X0 + FRAME_THICK + 80;
localparam integer BLOCK22_Y = FRAME_Y0 + FRAME_THICK + 100;

localparam integer BLOCK23_X = FRAME_X0 + FRAME_THICK + 130;
localparam integer BLOCK23_Y = FRAME_Y0 + FRAME_THICK + 100;

localparam integer BLOCK24_X = FRAME_X0 + FRAME_THICK + 180;
localparam integer BLOCK24_Y = FRAME_Y0 + FRAME_THICK + 100;

localparam integer BLOCK25_X = FRAME_X0 + FRAME_THICK + 230;
localparam integer BLOCK25_Y = FRAME_Y0 + FRAME_THICK + 100;

reg block21_active, block22_active, block23_active, block24_active, block25_active;

// ================= GAME PHYSICS ====================
always @(posedge clk or negedge rst) begin
   //integer offset;
	//integer abs_offset;
	//integer temp_offset;

	if (!rst) begin
        frame_x <= FRAME_X0;
        frame_y <= FRAME_Y0;

        paddle_x <= FRAME_X0 + (FRAME_W >> 1);
        paddle_y <= (FRAME_Y0 + FRAME_H - FRAME_THICK) - PADDLE_MARGIN - PADDLE_R;

        bx <= FRAME_X0 + (FRAME_W >> 1);
        by <= FRAME_Y0 + (FRAME_H >> 1);

        vx_mag <= INIT_VX;
        vy_mag <= INIT_VY;
        vx_dir <= 1;
        vy_dir <= 1;

        prev_vga_vs <= 0;
		  
		  game_over <= 1'b0;
		  winner <= 1'b0;

        block1_active <= 1'b1;
        block2_active <= 1'b1;
        block3_active <= 1'b1;
        block4_active <= 1'b1;
		  block5_active <= 1'b1;
        block6_active <= 1'b1;
        block7_active <= 1'b1;
        block8_active <= 1'b1;
        block9_active <= 1'b1;
        block10_active <= 1'b1;
		 block11_active <= 1'b1;
		 block12_active <= 1'b1;
		 block13_active <= 1'b1;
		 block14_active <= 1'b1;
		 block15_active <= 1'b1;
		 block16_active <= 1'b1;
		 block17_active <= 1'b1;
		 block18_active <= 1'b1;
		 block19_active <= 1'b1;
		 block20_active <= 1'b1;
		 block21_active <= 1'b1;
		 block22_active <= 1'b1;
		 block23_active <= 1'b1;
		 block24_active <= 1'b1;
		 block25_active <= 1'b1;

    end else begin
        prev_vga_vs <= VGA_VS;

        if (frame_tick) begin

            // Paddle movement
            if (~KEY[3]) begin
                if (paddle_x > (paddle_min_cx + MOVE_STEP))
                    paddle_x <= paddle_x - MOVE_STEP;
                else
                    paddle_x <= paddle_min_cx[9:0];
            end else if (~KEY[2]) begin
                if (paddle_x < (paddle_max_cx - MOVE_STEP))
                    paddle_x <= paddle_x + MOVE_STEP;
                else
                    paddle_x <= paddle_max_cx[9:0];
            end

            // Ball movement
            if (vx_dir) bx <= bx + vx_mag;
            else bx <= bx - vx_mag;

            if (vy_dir) by <= by + vy_mag;
            else by <= by - vy_mag;

            // Ball bounce walls
            if (bx <= inner_min_x)
                vx_dir <= 1;
            else if (bx >= inner_max_x)
                vx_dir <= 0;

            if (by <= inner_min_y)
               vy_dir <= 1;
            //else if (by >= inner_max_y)
               // vy_dir <= 0;

					
				//   Game Over Logic -lose
            // Detect collision with the bottom inner edge (losing condition)
            if (by >= inner_max_y) begin
                game_over <= 1'b1;
            end
				
				
				// --- Game Over: win condition ---
				winner <= (block1_active  == 1'b0) && 
                  (block2_active  == 1'b0) && 
                  (block3_active  == 1'b0) && 
                  (block4_active  == 1'b0) && 
                  (block5_active  == 1'b0) && 
                  (block6_active  == 1'b0) && 
                  (block7_active  == 1'b0) && 
                  (block8_active  == 1'b0) && 
                  (block9_active  == 1'b0) && 
                  (block10_active == 1'b0) && 
                  (block11_active == 1'b0) && 
                  (block12_active == 1'b0) && 
                  (block13_active == 1'b0) && 
                  (block14_active == 1'b0) && 
                  (block15_active == 1'b0) && 
                  (block16_active == 1'b0) && 
                  (block17_active == 1'b0) && 
                  (block18_active == 1'b0) && 
                  (block19_active == 1'b0) && 
                  (block20_active == 1'b0) && 
                  (block21_active == 1'b0) && 
                  (block22_active == 1'b0) && 
                  (block23_active == 1'b0) && 
                  (block24_active == 1'b0) && 
                  (block25_active == 1'b0);
						
						
            // Paddle collision
            if (by >= (paddle_y - BALL_RADIUS) &&
                bx >= (paddle_x - PADDLE_HALF) &&
                by <= (paddle_y + PADDLE_R) &&
                bx <= (paddle_x + PADDLE_HALF)) begin
                vy_dir <= 0;
                by <= paddle_y - BALL_RADIUS - 1;
            end

				/*if (by >= (paddle_y - BALL_RADIUS) &&
					bx >= (paddle_x - PADDLE_HALF) &&
					by <= (paddle_y + PADDLE_R) &&
					bx <= (paddle_x + PADDLE_HALF)) begin

					// Always bounce upward
					vy_dir <= 0;
					by <= paddle_y - BALL_RADIUS - 1;

					// Compute signed offset from paddle center
					offset = bx - paddle_x;

					// Determine horizontal direction
					if (offset > 0)
					 vx_dir <= 1;
					else
					 vx_dir <= 0;

					// Compute absolute value
					abs_offset = offset;
					if (abs_offset < 0)
					 abs_offset = -abs_offset;

					// Choose angle strength
					if (abs_offset < 6)
					 vx_mag <= 1;
					else if (abs_offset < 12)
					 vx_mag <= 2;
					else if (abs_offset < 18)
					 vx_mag <= 3;
					else if (abs_offset < 26)
					 vx_mag <= 4;
					else if (abs_offset < 34)
					 vx_mag <= 5;
					else
					 vx_mag <= 6;
					end
		*/
				
				
            // Block collisions
            if (block1_active &&
                (bx + BALL_RADIUS >= BLOCK1_X) &&
                (bx - BALL_RADIUS <= BLOCK1_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK1_Y) &&
                (by - BALL_RADIUS <= BLOCK1_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block1_active <= 1'b0;
            end

            if (block2_active &&
                (bx + BALL_RADIUS >= BLOCK2_X) &&
                (bx - BALL_RADIUS <= BLOCK2_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK2_Y) &&
                (by - BALL_RADIUS <= BLOCK2_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block2_active <= 1'b0;
            end

            if (block3_active &&
                (bx + BALL_RADIUS >= BLOCK3_X) &&
                (bx - BALL_RADIUS <= BLOCK3_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK3_Y) &&
                (by - BALL_RADIUS <= BLOCK3_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block3_active <= 1'b0;
            end

            if (block4_active &&
                (bx + BALL_RADIUS >= BLOCK4_X) &&
                (bx - BALL_RADIUS <= BLOCK4_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK4_Y) &&
                (by - BALL_RADIUS <= BLOCK4_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block4_active <= 1'b0;
            end

            if (block5_active &&
                (bx + BALL_RADIUS >= BLOCK5_X) &&
                (bx - BALL_RADIUS <= BLOCK5_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK5_Y) &&
                (by - BALL_RADIUS <= BLOCK5_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block5_active <= 1'b0;
            end

            if (block6_active &&
                (bx + BALL_RADIUS >= BLOCK6_X) &&
                (bx - BALL_RADIUS <= BLOCK6_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK6_Y) &&
                (by - BALL_RADIUS <= BLOCK6_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block6_active <= 1'b0;
            end

            if (block7_active &&
                (bx + BALL_RADIUS >= BLOCK7_X) &&
                (bx - BALL_RADIUS <= BLOCK7_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK7_Y) &&
                (by - BALL_RADIUS <= BLOCK7_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block7_active <= 1'b0;
            end

            if (block8_active &&
                (bx + BALL_RADIUS >= BLOCK8_X) &&
                (bx - BALL_RADIUS <= BLOCK8_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK8_Y) &&
                (by - BALL_RADIUS <= BLOCK8_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block8_active <= 1'b0;
            end

            if (block9_active &&
                (bx + BALL_RADIUS >= BLOCK9_X) &&
                (bx - BALL_RADIUS <= BLOCK9_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK9_Y) &&
                (by - BALL_RADIUS <= BLOCK9_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block9_active <= 1'b0;
            end

            if (block10_active &&
                (bx + BALL_RADIUS >= BLOCK10_X) &&
                (bx - BALL_RADIUS <= BLOCK10_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK10_Y) &&
                (by - BALL_RADIUS <= BLOCK10_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block10_active <= 1'b0;
            end

            if (block11_active &&
                (bx + BALL_RADIUS >= BLOCK11_X) &&
                (bx - BALL_RADIUS <= BLOCK11_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK11_Y) &&
                (by - BALL_RADIUS <= BLOCK11_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block11_active <= 1'b0;
            end

            if (block12_active &&
                (bx + BALL_RADIUS >= BLOCK12_X) &&
                (bx - BALL_RADIUS <= BLOCK12_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK12_Y) &&
                (by - BALL_RADIUS <= BLOCK12_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block12_active <= 1'b0;
            end

            if (block13_active &&
                (bx + BALL_RADIUS >= BLOCK13_X) &&
                (bx - BALL_RADIUS <= BLOCK13_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK13_Y) &&
                (by - BALL_RADIUS <= BLOCK13_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block13_active <= 1'b0;
            end

            if (block14_active &&
                (bx + BALL_RADIUS >= BLOCK14_X) &&
                (bx - BALL_RADIUS <= BLOCK14_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK14_Y) &&
                (by - BALL_RADIUS <= BLOCK14_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block14_active <= 1'b0;
            end

            if (block15_active &&
                (bx + BALL_RADIUS >= BLOCK15_X) &&
                (bx - BALL_RADIUS <= BLOCK15_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK15_Y) &&
                (by - BALL_RADIUS <= BLOCK15_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block15_active <= 1'b0;
            end

            if (block16_active &&
                (bx + BALL_RADIUS >= BLOCK16_X) &&
                (bx - BALL_RADIUS <= BLOCK16_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK16_Y) &&
                (by - BALL_RADIUS <= BLOCK16_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block16_active <= 1'b0;
            end

            if (block17_active &&
                (bx + BALL_RADIUS >= BLOCK17_X) &&
                (bx - BALL_RADIUS <= BLOCK17_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK17_Y) &&
                (by - BALL_RADIUS <= BLOCK17_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block17_active <= 1'b0;
            end

            if (block18_active &&
                (bx + BALL_RADIUS >= BLOCK18_X) &&
                (bx - BALL_RADIUS <= BLOCK18_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK18_Y) &&
                (by - BALL_RADIUS <= BLOCK18_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block18_active <= 1'b0;
            end

				if (block19_active &&
                (bx + BALL_RADIUS >= BLOCK19_X) &&
                (bx - BALL_RADIUS <= BLOCK19_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK19_Y) &&
                (by - BALL_RADIUS <= BLOCK19_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block19_active <= 1'b0;
            end

            if (block20_active &&
                (bx + BALL_RADIUS >= BLOCK20_X) &&
                (bx - BALL_RADIUS <= BLOCK20_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK20_Y) &&
                (by - BALL_RADIUS <= BLOCK20_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block20_active <= 1'b0;
            end
				if (block21_active &&
                (bx + BALL_RADIUS >= BLOCK21_X) &&
                (bx - BALL_RADIUS <= BLOCK21_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK21_Y) &&
                (by - BALL_RADIUS <= BLOCK21_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block21_active <= 1'b0;
            end

            if (block22_active && 
					 (bx + BALL_RADIUS >= BLOCK22_X) && 
					 (bx - BALL_RADIUS <= BLOCK22_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK22_Y) && 
					 (by - BALL_RADIUS <= BLOCK22_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block22_active <= 1'b0;
            end

            if (block23_active &&
                (bx + BALL_RADIUS >= BLOCK23_X) &&
                (bx - BALL_RADIUS <= BLOCK23_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK23_Y) &&
                (by - BALL_RADIUS <= BLOCK23_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block23_active <= 1'b0;
            end

				if (block24_active &&
                (bx + BALL_RADIUS >= BLOCK24_X) &&
                (bx - BALL_RADIUS <= BLOCK24_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK24_Y) &&
                (by - BALL_RADIUS <= BLOCK24_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block24_active <= 1'b0;
            end

            if (block25_active &&
                (bx + BALL_RADIUS >= BLOCK25_X) &&
                (bx - BALL_RADIUS <= BLOCK25_X + BLOCK_W) &&
                (by + BALL_RADIUS >= BLOCK25_Y) &&
                (by - BALL_RADIUS <= BLOCK25_Y + BLOCK_H)) begin
                vy_dir <= ~vy_dir;
                block25_active <= 1'b0;
            end
        end
    end
end

// ================= RENDERING ====================
reg [23:0] vga_color;

reg [14:0] cx, cy, dx, dy, adx, ady;
reg [23:0] ex;
reg [31:0] dist2;

reg in_block1, in_block2, in_block3, in_block4, in_block5, in_block6, in_block7, in_block8, in_block9, in_block10,
in_block11, in_block12, in_block13, in_block14, in_block15, in_block16, in_block17, in_block18, in_block19, in_block20, in_block21, in_block22, in_block23, in_block24, in_block25;

always @(*) begin
    // Block 1
    if ((x >= BLOCK1_X) && (x < BLOCK1_X + BLOCK_W) && (y >= BLOCK1_Y) && (y < BLOCK1_Y + BLOCK_H))
        in_block1 = 1'b1;
		else
        in_block1 = 1'b0;

    // Block 2
    if ((x >= BLOCK2_X) && (x < BLOCK2_X + BLOCK_W) && (y >= BLOCK2_Y) && (y < BLOCK2_Y + BLOCK_H))
        in_block2 = 1'b1;
    else
        in_block2 = 1'b0;

    // Block 3
    if ((x >= BLOCK3_X) && (x < BLOCK3_X + BLOCK_W) && (y >= BLOCK3_Y) && (y < BLOCK3_Y + BLOCK_H))
        in_block3 = 1'b1;
    else
        in_block3 = 1'b0;

    // Block 4
    if ((x >= BLOCK4_X) && (x < BLOCK4_X + BLOCK_W) && (y >= BLOCK4_Y) && (y < BLOCK4_Y + BLOCK_H))
        in_block4 = 1'b1;
    else
        in_block4 = 1'b0;
 
    // Block 5
    if ((x >= BLOCK5_X) && (x < BLOCK5_X + BLOCK_W) && (y >= BLOCK5_Y) && (y < BLOCK5_Y + BLOCK_H))
        in_block5 = 1'b1;
    else
        in_block5 = 1'b0;
 
    // Block 6
	if ((x >= BLOCK6_X) && (x < BLOCK6_X + BLOCK_W) &&  (y >= BLOCK6_Y) && (y < BLOCK6_Y + BLOCK_H))
        in_block6 = 1'b1;
    else
        in_block6 = 1'b0;
 
    // Block 7
	if ((x >= BLOCK7_X) && (x < BLOCK7_X + BLOCK_W) && (y >= BLOCK7_Y) && (y < BLOCK7_Y + BLOCK_H))
        in_block7 = 1'b1;
    else
        in_block7 = 1'b0;
 
    // Block 8
	if ((x >= BLOCK8_X) && (x < BLOCK8_X + BLOCK_W) && (y >= BLOCK8_Y) && (y < BLOCK8_Y + BLOCK_H))
        in_block8 = 1'b1;
    else
        in_block8 = 1'b0;
 
    // Block 9
	if ((x >= BLOCK9_X) && (x < BLOCK9_X + BLOCK_W) && (y >= BLOCK9_Y) && (y < BLOCK9_Y + BLOCK_H))
        in_block9 = 1'b1;
    else
        in_block9 = 1'b0;
 
    // Block 10
	if ((x >= BLOCK10_X) && (x < BLOCK10_X + BLOCK_W) && (y >= BLOCK10_Y) && (y < BLOCK10_Y + BLOCK_H))
        in_block10 = 1'b1;
    else
        in_block10 = 1'b0;
 
    // Block 11
	if ((x >= BLOCK11_X) && (x < BLOCK11_X + BLOCK_W) && (y >= BLOCK11_Y) && (y < BLOCK11_Y + BLOCK_H))
        in_block11 = 1'b1;
    else
        in_block11 = 1'b0;
 
    // Block 12
	if ((x >= BLOCK12_X) && (x < BLOCK12_X + BLOCK_W) &&  (y >= BLOCK12_Y) && (y < BLOCK12_Y + BLOCK_H))
        in_block12 = 1'b1;
    else
        in_block12 = 1'b0;
 
    // Block 13
	if ((x >= BLOCK13_X) && (x < BLOCK13_X + BLOCK_W) && (y >= BLOCK13_Y) && (y < BLOCK13_Y + BLOCK_H))
        in_block13 = 1'b1;
    else
        in_block13 = 1'b0;

	// Block 14
	if ((x >= BLOCK14_X) && (x < BLOCK14_X + BLOCK_W) && (y >= BLOCK14_Y) && (y < BLOCK14_Y + BLOCK_H))
        in_block14 = 1'b1;
    else
        in_block14 = 1'b0;
 
    // Block 15
	if ((x >= BLOCK15_X) && (x < BLOCK15_X + BLOCK_W) &&  (y >= BLOCK15_Y) && (y < BLOCK15_Y + BLOCK_H))
        in_block15 = 1'b1;
    else
        in_block15 = 1'b0;
 
    // Block 16
	if ((x >= BLOCK16_X) && (x < BLOCK16_X + BLOCK_W) &&  (y >= BLOCK16_Y) && (y < BLOCK16_Y + BLOCK_H))
        in_block16 = 1'b1;
    else
        in_block16 = 1'b0;
 
    // Block 17
	if ((x >= BLOCK17_X) && (x < BLOCK17_X + BLOCK_W) && (y >= BLOCK17_Y) && (y < BLOCK17_Y + BLOCK_H))
        in_block17 = 1'b1;
    else
        in_block17 = 1'b0;

	// Block 18
	if ((x >= BLOCK18_X) && (x < BLOCK18_X + BLOCK_W) &&  (y >= BLOCK18_Y) && (y < BLOCK18_Y + BLOCK_H))
        in_block18 = 1'b1;
    else
        in_block18 = 1'b0;
 
    // Block 19
	if ((x >= BLOCK19_X) && (x < BLOCK19_X + BLOCK_W) &&  (y >= BLOCK19_Y) && (y < BLOCK19_Y + BLOCK_H))
        in_block19 = 1'b1;
    else
        in_block19 = 1'b0;
 
    // Block 20
	if ((x >= BLOCK20_X) && (x < BLOCK20_X + BLOCK_W) &&   (y >= BLOCK20_Y) && (y < BLOCK20_Y + BLOCK_H))
        in_block20 = 1'b1;
    else
        in_block20 = 1'b0;

    // Block 21
	if ((x >= BLOCK21_X) && (x < BLOCK21_X + BLOCK_W) && (y >= BLOCK21_Y) && (y < BLOCK21_Y + BLOCK_H))
        in_block21 = 1'b1;
    else
        in_block21 = 1'b0;
 
    // Block 22
	if ((x >= BLOCK22_X) && (x < BLOCK22_X + BLOCK_W) && (y >= BLOCK22_Y) && (y < BLOCK22_Y + BLOCK_H))
        in_block22 = 1'b1;
    else
        in_block22 = 1'b0;

	// Block 23
	if ((x >= BLOCK23_X) && (x < BLOCK23_X + BLOCK_W) &&(y >= BLOCK23_Y) && (y < BLOCK23_Y + BLOCK_H))
        in_block23 = 1'b1;
    else
        in_block23 = 1'b0;
 
    // Block 24
	if ((x >= BLOCK24_X) && (x < BLOCK24_X + BLOCK_W) && (y >= BLOCK24_Y) && (y < BLOCK24_Y + BLOCK_H))
        in_block24 = 1'b1;
    else
        in_block24 = 1'b0;
 
    // Block 25
	if ((x >= BLOCK25_X) && (x < BLOCK25_X + BLOCK_W) && (y >= BLOCK25_Y) && (y < BLOCK25_Y + BLOCK_H))
        in_block25 = 1'b1;
    else
        in_block25 = 1'b0;
end

always @(*) begin
    vga_color = COLOR_BG;

    cx = paddle_x;
    cy = paddle_y;

	 if (game_over) begin
        vga_color = COLOR_GAMEOVER;
    end 
	 else if (winner) begin
			vga_color = COLOR_WINNER;
	 end 
	 
	 else if (active_pixels) begin
    // If not game over, proceed with normal drawing

        if ((x >= frame_x) && (x < frame_x + FRAME_W) &&
            (y >= frame_y) && (y < frame_y + FRAME_H)) begin

            if ((x < frame_x + FRAME_THICK) ||
                (x >= frame_x + FRAME_W - FRAME_THICK) ||
                (y < frame_y + FRAME_THICK) ||
                (y >= frame_y + FRAME_H - FRAME_THICK)) begin
                vga_color = COLOR_FRAME;
            end
            else begin
                // BALL
                if ((x >= bx - BALL_RADIUS) && (x <= bx + BALL_RADIUS) &&
                    (y >= by - BALL_RADIUS) && (y <= by + BALL_RADIUS)) begin

                    if (x >= bx) dx = x - bx; else dx = bx - x;
                    if (y >= by) dy = y - by; else dy = by - y;

                    dist2 = dx*dx + dy*dy;
                    if (dist2 <= BALL_R2)
                        vga_color = COLOR_BALL;
                end

                // PADDLE
                if ((x >= paddle_x - PADDLE_HALF) && (x <= paddle_x + PADDLE_HALF) &&
                    (y >= paddle_y - PADDLE_R) && (y <= paddle_y + PADDLE_R)) begin

                    if (x >= cx) dx = x - cx; else dx = cx - x;
                    if (y >= cy) dy = y - cy; else dy = cy - y;

                    adx = dx;
                    ady = dy;

                    if ((adx <= PADDLE_RECT_HALF) && (ady <= PADDLE_R))
                        vga_color = COLOR_PADDLE;
                    else if (adx > PADDLE_RECT_HALF) begin
                        ex = adx - PADDLE_RECT_HALF;
                        dist2 = ex*ex + ady*ady;
                        if (dist2 <= PADDLE_R2)
                            vga_color = COLOR_PADDLE;
                    end
                end

                // BLOCKS
// Row 1 blocks (1–5)
if (in_block1  && block1_active ) vga_color = COLOR_ROW1;
else if (in_block2  && block2_active) vga_color = COLOR_ROW1;
else if (in_block3  && block3_active) vga_color = COLOR_ROW1;
else if (in_block4  && block4_active) vga_color = COLOR_ROW1;
else if (in_block5  && block5_active) vga_color = COLOR_ROW1;

// Row 2 blocks (6–10)
else if (in_block6  && block6_active) vga_color = COLOR_ROW2;
else if (in_block7  && block7_active) vga_color = COLOR_ROW2;
else if (in_block8  && block8_active) vga_color = COLOR_ROW2;
else if (in_block9  && block9_active) vga_color = COLOR_ROW2;
else if (in_block10 && block10_active) vga_color = COLOR_ROW2;

// Row 3 blocks (11–15)
else if (in_block11 && block11_active) vga_color = COLOR_ROW3;
else if (in_block12 && block12_active) vga_color = COLOR_ROW3;
else if (in_block13 && block13_active) vga_color = COLOR_ROW3;
else if (in_block14 && block14_active) vga_color = COLOR_ROW3;
else if (in_block15 && block15_active) vga_color = COLOR_ROW3;

// Row 4 blocks (16–20)
else if (in_block16 && block16_active) vga_color = COLOR_ROW4;
else if (in_block17 && block17_active) vga_color = COLOR_ROW4;
else if (in_block18 && block18_active) vga_color = COLOR_ROW4;
else if (in_block19 && block19_active) vga_color = COLOR_ROW4;
else if (in_block20 && block20_active) vga_color = COLOR_ROW4;

// Row 5 blocks (21-25)
else if (in_block21 && block21_active) vga_color = COLOR_ROW5;
else if (in_block22 && block22_active) vga_color = COLOR_ROW5;
else if (in_block23 && block23_active) vga_color = COLOR_ROW5;
else if (in_block24 && block24_active) vga_color = COLOR_ROW5;
else if (in_block25 && block25_active) vga_color = COLOR_ROW5;
            end
        end
    end
end

// VGA OUTPUTS
always @(*) begin
    {VGA_R, VGA_G, VGA_B} = vga_color;
end

endmodule