module vga_driver_memory	(
  	//////////// ADC //////////
	//output		          		ADC_CONVST,
	//output		          		ADC_DIN,
	//input 		          		ADC_DOUT,
	//output		          		ADC_SCLK,

	//////////// Audio //////////
	//input 		          		AUD_ADCDAT,
	//inout 		          		AUD_ADCLRCK,
	//inout 		          		AUD_BCLK,
	//output		          		AUD_DACDAT,
	//inout 		          		AUD_DACLRCK,
	//output		          		AUD_XCK,

	//////////// CLOCK //////////
	//input 		          		CLOCK2_50,
	//input 		          		CLOCK3_50,
	//input 		          		CLOCK4_50,
	input 		          		CLOCK_50,

	//////////// SDRAM //////////
	//output		    [12:0]		DRAM_ADDR,
	//output		     [1:0]		DRAM_BA,
	//output		          		DRAM_CAS_N,
	//output		          		DRAM_CKE,
	//output		          		DRAM_CLK,
	//output		          		DRAM_CS_N,
	//inout 		    [15:0]		DRAM_DQ,
	//output		          		DRAM_LDQM,
	//output		          		DRAM_RAS_N,
	//output		          		DRAM_UDQM,
	//output		          		DRAM_WE_N,

	//////////// I2C for Audio and Video-In //////////
	//output		          		FPGA_I2C_SCLK,
	//inout 		          		FPGA_I2C_SDAT,

	//////////// SEG7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,
	//output		     [6:0]		HEX4,
	//output		     [6:0]		HEX5,

	//////////// IR //////////
	//input 		          		IRDA_RXD,
	//output		          		IRDA_TXD,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// PS2 //////////
	//inout 		          		PS2_CLK,
	//inout 		          		PS2_CLK2,
	//inout 		          		PS2_DAT,
	//inout 		          		PS2_DAT2,

	//////////// SW //////////
	input 		     [9:0]		SW,

	//////////// Video-In //////////
	//input 		          		TD_CLK27,
	//input 		     [7:0]		TD_DATA,
	//input 		          		TD_HS,
	//output		          		TD_RESET_N,
	//input 		          		TD_VS,

	//////////// VGA //////////
	output		          		VGA_BLANK_N,
	output reg	     [7:0]		VGA_B,
	output		          		VGA_CLK,
	output reg	     [7:0]		VGA_G,
	output		          		VGA_HS,
	output reg	     [7:0]		VGA_R,
	output		          		VGA_SYNC_N,
	output		          		VGA_VS

	//////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
	//inout 		    [35:0]		GPIO_0,

	//////////// GPIO_1, GPIO_1 connect to GPIO Default //////////
	//inout 		    [35:0]		GPIO_1

);

  // Turn off all displays.
	assign	HEX0		=	7'h00;
	assign	HEX1		=	7'h00;
	assign	HEX2		=	7'h00;
	assign	HEX3		=	7'h00;

wire active_pixels; // is on when we're in the active draw space

wire [9:0]x; // current x
wire [9:0]y; // current y - 10 bits = 1024 ... a little bit more than we need

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


// ===== Parameters =====
localparam integer FRAME_W     = 275;   
localparam integer FRAME_H     = 350;   
localparam integer FRAME_THICK = 3;    

localparam integer PADDLE_W    = 96;    
localparam integer PADDLE_H    = 20;    
localparam integer PADDLE_MARGIN = 8;   
localparam integer MOVE_STEP   = 4;     

localparam integer BALL_RADIUS = 8;    
localparam integer INIT_VX     = 3;    
localparam integer INIT_VY     = 2;     

localparam [23:0] COLOR_BG    = 24'h000000; 
localparam [23:0] COLOR_FRAME = 24'h0000FF; 
localparam [23:0] COLOR_BALL  = 24'hFFFFFF; 
localparam [23:0] COLOR_PADDLE= 24'hFFFFFF;

localparam [9:0] MIN_ACTIVE_X = 10'd100;
localparam [9:0] MAX_ACTIVE_X = 10'd539;
localparam [9:0] MIN_ACTIVE_Y = 10'd40;
localparam [9:0] MAX_ACTIVE_Y = 10'd439;

localparam [9:0] FRAME_X_MAX =
    MIN_ACTIVE_X +
    ( (MAX_ACTIVE_X >= (FRAME_W- 10'd1)) *
      (MAX_ACTIVE_X - (FRAME_W - 10'd1)) );

localparam [9:0] FRAME_Y_MAX =
    MIN_ACTIVE_Y +
    ( (MAX_ACTIVE_Y >= (FRAME_H - 10'd1)) *
      (MAX_ACTIVE_Y - (FRAME_H - 10'd1)) );

localparam [9:0] FRAME_X0 = MIN_ACTIVE_X + ((FRAME_X_MAX - MIN_ACTIVE_X) >> 1);
localparam [9:0] FRAME_Y0 = MIN_ACTIVE_Y + ((FRAME_Y_MAX - MIN_ACTIVE_Y) >> 1);

localparam integer BALL_R2 = BALL_RADIUS * BALL_RADIUS;

localparam integer PADDLE_R = (PADDLE_H >> 1);            // semicircle radius
localparam integer PADDLE_HALF = (PADDLE_W >> 1);
localparam integer PADDLE_RECT_HALF = PADDLE_HALF - PADDLE_R; // half-length of the rectangular middle section
localparam integer PADDLE_R2 = PADDLE_R * PADDLE_R;


 // ===== State =====
 reg [9:0] frame_x;
 reg [9:0] frame_y;
 
 reg [9:0] paddle_x;
 reg [9:0] paddle_y;

 reg [12:0] bx;
 reg [12:0] by;

 reg [8:0] vx_mag;
 reg vx_dir;   
 reg [8:0] vy_mag;
 reg vy_dir;  
 reg [13:0] next_y;

 reg prev_vga_vs;
 wire frame_tick = (~prev_vga_vs) & VGA_VS;

 wire [11:0] paddle_min_cx = frame_x + FRAME_THICK + PADDLE_HALF;
 wire [11:0] paddle_max_cx = frame_x + FRAME_W - FRAME_THICK - PADDLE_HALF;
 
 wire [11:0] inner_min_x = frame_x + FRAME_THICK + BALL_RADIUS;
 wire [11:0] inner_max_x = frame_x + FRAME_W - FRAME_THICK - BALL_RADIUS;
 wire [11:0] inner_min_y = frame_y + FRAME_THICK + BALL_RADIUS;
 wire [11:0] inner_max_y = frame_y + FRAME_H - FRAME_THICK - BALL_RADIUS;

 wire [11:0] inner_top    = frame_y + FRAME_THICK;
 wire [11:0] inner_bottom = frame_y + FRAME_H - FRAME_THICK;
 
 // ===== Physics =====
 always @(posedge clk or negedge rst) begin
	if (rst == 1'b0) begin
		frame_x <= FRAME_X0;
		frame_y <= FRAME_Y0;

		paddle_x <= FRAME_X0 + (FRAME_W >> 1);
		paddle_y <= (FRAME_Y0 + FRAME_H - FRAME_THICK) - PADDLE_MARGIN - PADDLE_R;

		prev_vga_vs <= 1'b0;
	end
	else begin
		prev_vga_vs <= VGA_VS;

		if (frame_tick) begin
			if (~KEY[3]) begin // LEFT
				if (paddle_x > (paddle_min_cx + MOVE_STEP))
					paddle_x <= paddle_x - MOVE_STEP;
				else
					paddle_x <= paddle_min_cx[9:0];
			end
			else if (~KEY[2]) begin // RIGHT
				if (paddle_x < (paddle_max_cx - MOVE_STEP))
					paddle_x <= paddle_x + MOVE_STEP;
				else
					paddle_x <= paddle_max_cx[9:0];
			end
		end
	end
end

 // ===== Rendering =====
reg [23:0] vga_color;

reg [14:0] cx;     
reg [14:0] cy;     
reg [14:0] dx;
reg [14:0] dy;
reg [14:0] adx;
reg [14:0] ady;
reg [23:0] ex;     
reg [31:0] dist2;

always @(*) begin
    vga_color = COLOR_BG;

    cx = paddle_x;
    cy = paddle_y;

    if (active_pixels) begin
        if ((x >= frame_x) && (x < frame_x + FRAME_W) &&
            (y >= frame_y) && (y < frame_y + FRAME_H)) begin

            if ((x < frame_x + FRAME_THICK) ||
                (x >= frame_x + FRAME_W - FRAME_THICK) ||
                (y < frame_y + FRAME_THICK) ||
                (y >= frame_y + FRAME_H - FRAME_THICK)) begin
                vga_color = COLOR_FRAME;
            end
            else begin
                if ((x >= paddle_x - PADDLE_HALF) && (x <= paddle_x + PADDLE_HALF) &&
                    (y >= paddle_y - PADDLE_R) && (y <= paddle_y + PADDLE_R)) begin

                    if (x >= cx) 
							dx = x - cx;
                    else        
							dx = cx - x;

                    if (y >= cy) 
							dy = y - cy;
                    else         
							dy = cy - y;

                    adx = dx;
                    ady = dy;

                    if ((adx <= PADDLE_RECT_HALF) && (ady <= PADDLE_R)) begin
                        vga_color = COLOR_PADDLE;
                    end
                    else begin
                        if (adx > PADDLE_RECT_HALF) begin
                            ex = adx - PADDLE_RECT_HALF;
                            dist2 = ex*ex + ady*ady;
                            if (dist2 <= PADDLE_R2) 
										vga_color = COLOR_PADDLE;
                            else                     
										vga_color = COLOR_BG;
                        end
                        else begin
                            vga_color = COLOR_BG;
                        end
                    end
                end
                else begin
                    vga_color = COLOR_BG;
                end
            end
        end
        else begin
            vga_color = COLOR_BG;
        end
    end
    else begin
        vga_color = COLOR_BG;
    end
end

 always @(*) begin
	  {VGA_R, VGA_G, VGA_B} = vga_color;
 end

endmodule