module ov7670_top(
input ov7670_href,
input ov7670_pclk,
input ov7670_vsync,
input [7:0] ov7670_data,
input sys_rst_n,
input sys_clk,
output ov7670_wr_en,
output [15:0] ov7670_data_out,
output cfg_done,
output sccb_scl,
output sccb_sda



);

wire OvIsCfg;

assign OvIsCfg=cfg_done;



ov7670_data DataUse(
.ov7670_href(ov7670_href),
.ov7670_pclk(ov7670_pclk),
.ov7670_vsync(ov7670_vsync),
.ov7670_data(ov7670_data),

.sys_rst_n(sys_rst_n),
.sys_init_done(OvIsCfg),

.ov7670_wr_en(ov7670_wr_en),
.ov7670_data_out(ov7670_data_out)
);

ov7670_init InitUse(
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .sccb_scl(sccb_scl),
    .sccb_sda(sccb_sda),
    .init_done(cfg_done)

);

endmodule
