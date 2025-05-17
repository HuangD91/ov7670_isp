module ov7670_data(
	input				ov7670_pclk				,//输入为摄像头输入时钟pov7670_pclk 25MHz
	input				sys_rst_n			,//系统复位
	input				ov7670_vsync			,//场同步信号
	input				ov7670_href			,//行同步信号
	input	[7:0]		ov7670_data				,//ov7670摄像头数据输入
	input				sys_init_done		,//ov7670摄像头初始化结束标志
	output	reg[15:0]	ov7670_data_out		,//转换成16位RGB565图像数据
	output	reg			ov7670_wr_en	 //16位RGB565图像数据有效标志
	);
	reg			vsync_r			;
	reg			ov7670_href_r			;
	reg	[7:0]	din_r			;
	reg			vsync_r_ff0		;
	reg			vsync_r_ff1		;
	reg			data_start		;
	reg	[3:0]	frame_cnt		;
	reg			frame_vaild		;
	wire		vsync_r_pos		;
	reg			data_en			;
	
	//外部信号打一拍
	always @(posedge ov7670_pclk or negedge sys_rst_n) begin
		if (!sys_rst_n) begin
			vsync_r <= 0;
			ov7670_href_r <= 0;
			din_r <= 8'd0;
		end
		else begin
			vsync_r <= ov7670_vsync;
			ov7670_href_r <= ov7670_href;
			din_r <= ov7670_data;
		end
	end
 
	//场同步信号上升沿检测
	always @(posedge ov7670_pclk or negedge sys_rst_n) begin
		if (!sys_rst_n) begin
			vsync_r_ff0 <= 0;
			vsync_r_ff1 <= 0;
		end
		else begin
			vsync_r_ff0 <= vsync_r;
			vsync_r_ff1 <= vsync_r_ff0;
		end
	end
	assign vsync_r_pos = (vsync_r_ff0 && ~vsync_r_ff1);
	always @(posedge ov7670_pclk or negedge sys_rst_n) begin
		if (!sys_rst_n) begin
			data_start <= 0;
		end
		else if (sys_init_done) begin
			data_start <= 1;
		end
		else begin
			data_start <= data_start;
		end
	end
 
	always @(posedge ov7670_pclk or negedge sys_rst_n) begin
		if (!sys_rst_n) begin
			frame_cnt <= 0;
		end
		else if (data_start && frame_vaild==0 && vsync_r_pos) begin
			frame_cnt <= frame_cnt + 1'b1;
		end
		else begin
			frame_cnt <= frame_cnt;
		end
	end
	always @(posedge ov7670_pclk or negedge sys_rst_n) begin
		if (!sys_rst_n) begin
			frame_vaild <= 0;
		end
		else if (frame_cnt >= 10) begin
			frame_vaild <= 1;
		end
		else begin
			frame_vaild <= frame_vaild;
		end
	end
	always @(posedge ov7670_pclk or negedge sys_rst_n) begin
		if (!sys_rst_n) begin
			data_en <= 0;
		end
		else if (ov7670_href_r && frame_vaild) begin
			data_en <= ~data_en;
		end
		else begin
			data_en <= 0;
		end
	end
	always @(posedge ov7670_pclk or negedge sys_rst_n) begin
		if (!sys_rst_n) begin
			ov7670_wr_en <= 0;
		end
		else if (data_en) begin
			ov7670_wr_en <= 1;
		end
		else begin
			ov7670_wr_en <= 0;
		end
	end
	reg [7:0]high_byte_reg;
	always @(posedge ov7670_pclk or negedge sys_rst_n) begin
		if (!sys_rst_n) begin
			ov7670_data_out <= 16'd0;
		end
		else if (data_en) begin
			ov7670_data_out <= {ov7670_data_out[15:8],din_r};
		end
		else begin
			ov7670_data_out <= {din_r,ov7670_data_out[7:0]};
		end
	end
/*	always @(posedge ov7670_pclk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        ov7670_data_out <= 16'd0;
		  high_byte_reg <= 8'd0;
    end
    else if (data_en) begin
        // 假设第一个字节是高8位，第二个是低8位
        ov7670_data_out <= {high_byte_reg, din_r}; // 使用寄存器暂存高字节
    end
    else begin
        high_byte_reg <= din_r; // 在data_en=0时锁存高字节
    end
end*/
 
endmodule