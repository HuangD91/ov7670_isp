module ov7670_init(
	input			sys_clk		,//50MHz
	input			sys_rst_n	,
	output			sccb_scl		,
	inout			sccb_sda		,
	output			init_done
	);
	
	localparam device_id = 8'b0100_0010;
 
	wire			cfg_start	;//start
	wire	[7:0]	addr	;
	wire	[7:0]	value	;
	// wire [23:0] cfg_data_wr;
	wire			cfg_end	;//done
	wire			cfg_clk	;//busy
	// wire			cfg_done	;//init_done
	wire            ack_error;
 

 
//	assign init_done = cfg_done;
 
	reg [17:0]	cnt_3ms;//上电等待3ms电平稳定后再初始化寄存器
	always @(posedge sys_clk or negedge sys_rst_n)begin
		if(!sys_rst_n)begin
			cnt_3ms <= 0;
		end
		else if(cnt_3ms<=18'd150000)begin
			cnt_3ms <= cnt_3ms + 1'd1;
		end
	end
 
	reg ov7670_cfg_enable;
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        ov7670_cfg_enable <= 1'b0;
    else if (cnt_3ms == 18'd150000-1)
        ov7670_cfg_enable <= 1'b1;
end
	ov7670_sccb inst_ov7670_sccb (
		.sys_clk     (sys_clk),
		.sys_rst_n   (sys_rst_n),
		.cfg_start (ov7670_cfg_enable ? cfg_start : 1'b0),
		.reg_addr(addr),
        .reg_data(value),
		.cfg_end    (cfg_end),
		.cfg_clk   (cfg_clk),
		.ack_error(ack_error),
		.sccb_scl    (sccb_scl),
		.sccb_sda     (sccb_sda)
	);
 
	ov7670_cfg inst_ov7670_cfg
		(
			.sys_clk       (sys_clk),
			.sys_rst_n     (sys_rst_n),
			.reg_addr(addr),
         .reg_data(value),
			.cfg_end (cfg_end),
			.cfg_done	   (init_done),
			.cfg_start  (cfg_start)

		);
 
endmodule