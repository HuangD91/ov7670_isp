module ov7670_sccb(
    input               sys_clk         ,//系统时钟50MHz
    input               sys_rst_n       ,//系统复位
    input               cfg_start       ,//发送使能
    // input       [23:0]  cfg_data_wr     ,
        input      [7:0]   reg_addr,     // 8位寄存器地址
    input      [7:0]   reg_data,     // 8位寄存器数据
    output  reg         cfg_end         ,//done_完成信号为1周期脉冲发送结束标志
    output  reg         cfg_clk         ,//busy_发送状态，忙为0，不忙为1
    output reg         ack_error,    // ACK错误标志
    output  reg         sccb_scl        ,//输出时钟线
    inout               sccb_sda        //输出数据线

    );
    
        // 参数
    parameter DEVICE_ID = 8'h42;     // OV7670写地址
    parameter CLK_DIV = 250;         // 50MHz/250 = 200kHz, 实际SCL为100kHz（一个周期2*250）

    // 状态机

    parameter IDLE=4'b0000;       // 空闲
    parameter START=4'b0001;      // 起始
    parameter DEV_ADDR=4'b0010;   // 设备地址
    parameter DEV_ACK=4'b0011;    // 设备地址ACK
    parameter REG_ADDR=4'b0100;   // 寄存器地址
    parameter REG_ACK=4'b0101;    // 寄存器地址ACK
    parameter REG_DATA=4'b0110;   // 数据
    parameter DATA_ACK=4'b0111;   // 数据ACK
    parameter STOP_1=4'b1000;     // 停止第一步
    parameter STOP_2=4'b1001;    // 停止第二步
    parameter DONE=4'b1010 ;       // 结束

 reg [3:0] state, next_state;

    // SCL分频
    reg [7:0] clk_cnt;
    reg scl_r;
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            clk_cnt <= 0;
            scl_r <= 1;
        end else if (cfg_clk) begin
            if (clk_cnt == CLK_DIV-1) begin
                clk_cnt <= 0;
                scl_r <= ~scl_r;
            end else begin
                clk_cnt <= clk_cnt + 1'b1;
            end
        end else begin
            clk_cnt <= 0;
            scl_r <= 1;
        end
    end
    assign scl = scl_r;

    // SDA方向与数据
    reg sda_out_en;
    reg sda_out;
    assign sccb_sda = sda_out_en ? sda_out : 1'bz;
    wire sda_in = sccb_sda;

    // 数据缓存
    reg [7:0] send_buf;
    reg [3:0] bit_cnt;

    // 状态机主流程
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            state     <= IDLE;
            cfg_clk      <= 0;
            cfg_end      <= 0;
            ack_error <= 0;
            sda_out_en<= 1;
            sda_out   <= 1;
            send_buf  <= 8'd0;
            bit_cnt   <= 4'd0;
        end else begin
            cfg_end <= 0; // 单周期脉冲
            case (state)
                IDLE: begin
                    cfg_clk <= 0;
                    sda_out_en <= 1;
                    sda_out <= 1;
                    if (cfg_start) begin
                        cfg_clk <= 1;
                        state <= START;
                    end
                end
                START: begin
                    // 起始条件：SDA下降沿时SCL为高
                    sda_out_en <= 1;
                    sda_out <= 1;
                    if (scl_r && clk_cnt == 0) begin
                        sda_out <= 0;
                        state <= DEV_ADDR;
                        send_buf <= DEVICE_ID;
                        bit_cnt <= 7;
                    end
                end
                DEV_ADDR: begin
                    // 发送设备地址
                    if (!scl_r && clk_cnt == 0) begin
                        sda_out <= send_buf[bit_cnt];
                        if (bit_cnt == 0)
                            state <= DEV_ACK;
                        else
                            bit_cnt <= bit_cnt - 1'b1;
                    end
                end
                DEV_ACK: begin
                    // 释放SDA，采ACK
                    if (!scl_r && clk_cnt == 0) sda_out_en <= 0;
                    if (scl_r && clk_cnt == 0) begin
                        ack_error <= sda_in;
                        sda_out_en <= 1;
                        state <= REG_ADDR;
                        send_buf <= reg_addr;
                        bit_cnt <= 7;
                    end
                end
                REG_ADDR: begin
                    // 发送寄存器地址
                    if (!scl_r && clk_cnt == 0) begin
                        sda_out <= send_buf[bit_cnt];
                        if (bit_cnt == 0)
                            state <= REG_ACK;
                        else
                            bit_cnt <= bit_cnt - 1'b1;
                    end
                end
                REG_ACK: begin
                    if (!scl_r && clk_cnt == 0) sda_out_en <= 0;
                    if (scl_r && clk_cnt == 0) begin
                        ack_error <= ack_error | sda_in;
                        sda_out_en <= 1;
                        state <= REG_DATA;
                        send_buf <= reg_data;
                        bit_cnt <= 7;
                    end
                end
                REG_DATA: begin
                    // 发送寄存器数据
                    if (!scl_r && clk_cnt == 0) begin
                        sda_out <= send_buf[bit_cnt];
                        if (bit_cnt == 0)
                            state <= DATA_ACK;
                        else
                            bit_cnt <= bit_cnt - 1'b1;
                    end
                end
                DATA_ACK: begin
                    if (!scl_r && clk_cnt == 0) sda_out_en <= 0;
                    if (scl_r && clk_cnt == 0) begin
                        ack_error <= ack_error | sda_in;
                        sda_out_en <= 1;
                        state <= STOP_1;
                    end
                end
                STOP_1: begin
                    // 停止条件：SDA上升沿时SCL为高
                    sda_out_en <= 1;
                    sda_out <= 0;
                    if (scl_r && clk_cnt == 0)
                        state <= STOP_2;
                end
                STOP_2: begin
                    sda_out_en <= 1;
                    sda_out <= 1;
                    state <= DONE;
                end
                DONE: begin
                    cfg_end <= 1;
                    cfg_clk <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule