module rgb565_to_rgb888 (
    input wire [15:0] rgb565,    // RGB565 输入
    output reg [23:0] rgb888     // RGB888 输出
);

// 提取 RGB565 分量
wire [4:0] r5 = rgb565[15:11];  // R 分量（5-bit）
wire [5:0] g6 = rgb565[10:5];   // G 分量（6-bit）
wire [4:0] b5 = rgb565[4:0];     // B 分量（5-bit）
wire [7:0] r8 = {r5, 3'b0};
wire [7:0] g8 = {g6, 2'b0}; 
wire [7:0] b8 = {b5, 3'b0};
/*
// 插值计算 R 分量（5-bit → 8-bit）
wire [7:0] r8 = {r5, r5[2:0]};  // 高位复制 + 低位插值

// 插值计算 G 分量（6-bit → 8-bit）
wire [7:0] g8 = {g6, g6[1:0]}; // 高位复制 + 低位插值

// 插值计算 B 分量（5-bit → 8-bit）
wire [7:0] b8 = {b5, b5[2:0]};  // 高位复制 + 低位插值
*/
// 组合输出 RGB888
always @(*) begin
    rgb888 = {r8, g8, b8};
end

endmodule