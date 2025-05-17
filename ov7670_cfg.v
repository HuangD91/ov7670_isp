module ov7670_cfg(
    input        sys_clk,
    input        sys_rst_n,
    input        cfg_end,      //done from sccb 假设cfg_end为外部模块应答信号（单周期脉冲）
    input        cfg_clk,// busy from sccb

    output reg [7:0]  reg_addr,
    output reg [7:0]  reg_data,

    output reg   cfg_done,//init_done
    output reg   cfg_start//start to sccb
    // output wire [23:0] cfg_data
);

    reg [8:0] cfg_cnt;
    reg [1:0] state;

    localparam IDLE  = 2'd0;
    localparam SEND  = 2'd1;
    localparam WAIT  = 2'd2;
    localparam FINISH= 2'd3;


reg [15:0] dout;
// 寄存器配置数据（避免锁存器）
always @(posedge sys_clk) begin
    dout <= 16'h0000; // 默认值
    case(cfg_cnt)
                8'd1:  dout <= 16'h1280;
		        8'd2:  dout <= 16'h1204;
		        8'd3:  dout <= 16'h40d0;
				8'd4:  dout <= 16'h3a04;
				8'd5:  dout <= 16'h3dc8;
				8'd6:  dout <= 16'h1e31;
				8'd7:  dout <= 16'h6b00;
				8'd8:  dout <= 16'h32b6;
				8'd9:  dout <= 16'h1713;
				8'd10: dout <= 16'h1801;
				8'd11: dout <= 16'h1902;
				8'd12: dout <= 16'h1a7a;
				8'd13: dout <= 16'h030a;
				8'd14: dout <= 16'h0c00;
				8'd15: dout <= 16'h3e10;
				8'd16: dout <= 16'h7000;
				8'd17: dout <= 16'h7100;
				8'd18: dout <= 16'h7211;
				8'd19: dout <= 16'h7300;
				8'd20: dout <= 16'ha202;
				8'd21: dout <= 16'h1180;
				8'd22: dout <= 16'h7a20;
				8'd23: dout <= 16'h7b1c;
				8'd24: dout <= 16'h7c28;
				8'd25: dout <= 16'h7d3c;
				8'd26: dout <= 16'h7e55;
				8'd27: dout <= 16'h7f68;
				8'd28: dout <= 16'h8076;
				8'd29: dout <= 16'h8180;
				8'd30: dout <= 16'h8288;
				8'd31: dout <= 16'h838f;
				8'd32: dout <= 16'h8496;
				8'd33: dout <= 16'h85a3;
				8'd34: dout <= 16'h86af;
				8'd35: dout <= 16'h87c4;
				8'd36: dout <= 16'h88d7;
				8'd37: dout <= 16'h89e8;
				8'd38: dout <= 16'h13e0;
				8'd39: dout <= 16'h0010;
				8'd40: dout <= 16'h1000;
				8'd41: dout <= 16'h0d00;
				8'd42: dout <= 16'h1428;
				8'd43: dout <= 16'ha505;
				8'd44: dout <= 16'hab07;
				8'd45: dout <= 16'h2475;
				8'd46: dout <= 16'h2563;
				8'd47: dout <= 16'h26a5;
				8'd48: dout <= 16'h9f78;
				8'd49: dout <= 16'ha068;
				8'd50: dout <= 16'ha103;
				8'd51: dout <= 16'ha6df;
				8'd52: dout <= 16'ha7df;
				8'd53: dout <= 16'ha8f0;
				8'd54: dout <= 16'ha990;
				8'd55: dout <= 16'haa94;
				8'd56: dout <= 16'h13ef;
				8'd57: dout <= 16'h0e61;
				8'd58: dout <= 16'h0f4b;
				8'd59: dout <= 16'h1602;
				8'd60: dout <= 16'h2102;
				8'd61: dout <= 16'h2291;
				8'd62: dout <= 16'h2907;
				8'd63: dout <= 16'h330b;
				8'd64: dout <= 16'h350b;
				8'd65: dout <= 16'h371d;
				8'd66: dout <= 16'h3871;
				8'd67: dout <= 16'h392a;
				8'd68: dout <= 16'h3c78;
				8'd69: dout <= 16'h4d40;
				8'd70: dout <= 16'h4e20;
				8'd71: dout <= 16'h6900;
				8'd72: dout <= 16'h7419;
				8'd73: dout <= 16'h8d4f;
				8'd74: dout <= 16'h8e00;
				8'd75: dout <= 16'h8f00;
				8'd76: dout <= 16'h9000;
				8'd77: dout <= 16'h9100;
				8'd78: dout <= 16'h9200;
				8'd79: dout <= 16'h9600;
				8'd80: dout <= 16'h9a80;
				8'd81: dout <= 16'hb084;
				8'd82: dout <= 16'hb10c;
				8'd83: dout <= 16'hb20e;
				8'd84: dout <= 16'hb382;
				8'd85:  dout <= 16'hb80a;
				8'd86:  dout <= 16'h4314;
				8'd87:  dout <= 16'h44f0;
				8'd88:  dout <= 16'h4534;
				8'd89:  dout <= 16'h4658;
				8'd90:  dout <= 16'h4728;
				8'd91:  dout <= 16'h483a;
				8'd92:  dout <= 16'h5988;
				8'd93:  dout <= 16'h5a88;
				8'd94:  dout <= 16'h5b44;
				8'd95:  dout <= 16'h5c67;
				8'd96:  dout <= 16'h5d49;
				8'd97:  dout <= 16'h5e0e;
				8'd98:  dout <= 16'h6404;
				8'd99:  dout <= 16'h6520;
				8'd100:  dout <= 16'h6605;
				8'd101: dout <= 16'h9404;
				8'd102: dout <= 16'h9508;
				8'd103: dout <= 16'h6c0a;
				8'd104: dout <= 16'h6d55;
				8'd105: dout <= 16'h6e11;
				8'd106: dout <= 16'h6f9f;
				8'd107: dout <= 16'h6a40;
				8'd108: dout <= 16'h0140;
				8'd109: dout <= 16'h0240;
				8'd110: dout <= 16'h13e7;
				8'd111: dout <= 16'h1500;
				8'd112: dout <= 16'h4f80;
				8'd113: dout <= 16'h5080;
				8'd114: dout <= 16'h5100;
				8'd115: dout <= 16'h5222;
				8'd116: dout <= 16'h535e;
				8'd117: dout <= 16'h5480;
				8'd118: dout <= 16'h589e;
				8'd119: dout <= 16'h4108;
				8'd120: dout <= 16'h3f00;
				8'd121: dout <= 16'h7505;
				8'd122: dout <= 16'h76e1;
				8'd123: dout <= 16'h4c00;
				8'd124: dout <= 16'h7701;
				8'd125: dout <= 16'h4b09;
				8'd126: dout <= 16'hc9F0;
				8'd127: dout <= 16'h4138;
				8'd128: dout <= 16'h5640;
				8'd129: dout <= 16'h3411;
				8'd130: dout <= 16'h3b02;
				8'd131: dout <= 16'ha489;
				8'd132: dout <= 16'h9600;
				8'd133: dout <= 16'h9730;
				8'd134: dout <= 16'h9820;
				8'd135: dout <= 16'h9930;
				8'd136: dout <= 16'h9a84;
				8'd137: dout <= 16'h9b29;
				8'd138: dout <= 16'h9c03;
				8'd139: dout <= 16'h9d4c;
				8'd140: dout <= 16'h9e3f;
				8'd141: dout <= 16'h7804; 
				8'd142: dout <= 16'h7901;
				8'd143: dout <= 16'hc8f0;
				8'd144: dout <= 16'h790f;
				8'd145: dout <= 16'hc800;
				8'd146: dout <= 16'h7910;
				8'd147: dout <= 16'hc87e;
				8'd148: dout <= 16'h790a;
				8'd149: dout <= 16'hc880;
				8'd150: dout <= 16'h790b;
				8'd151: dout <= 16'hc801;
				8'd152: dout <= 16'h790c;
				8'd153: dout <= 16'hc80f;
				8'd154: dout <= 16'h790d;
				8'd155: dout <= 16'hc820;
				8'd156: dout <= 16'h7909;
				8'd157: dout <= 16'hc880;
				8'd158: dout <= 16'h7902;
				8'd159: dout <= 16'hc8c0;
				8'd160: dout <= 16'h7903;
				8'd161: dout <= 16'hc840;
				8'd162: dout <= 16'h7905;
				8'd163: dout <= 16'hc830;
				8'd164: dout <= 16'h7926;
				8'd165: dout <= 16'h0903;
				8'd166: dout <= 16'h3b42;
				default:dout <= 16'hffff;
				
    endcase
end
always @(*) begin reg_addr=dout[15:8]; end 
always @(*) begin reg_data=dout[7:0]; end 
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if(!sys_rst_n) begin
            state <= IDLE;
            cfg_cnt <= 0;
            cfg_start <= 0;
            cfg_done <= 0;
        end else begin
            case(state)
                IDLE: begin
                    if(cfg_cnt < 50) begin
                        cfg_start <= 1;
                        state <= SEND;
                    end else begin
                        cfg_done <= 1;
                        state <= FINISH;
                    end
                end
                SEND: begin
                    cfg_start <= 0; // 拉低
                    if(cfg_end)
                        state <= WAIT;
                end
                WAIT: begin
                    if(!cfg_clk) begin // 等待SCCB空闲再发下一个
                        cfg_cnt <= cfg_cnt + 1'b1;
                        state <= IDLE;
                    end
                end
                FINISH: ;
            endcase
        end
    end

endmodule