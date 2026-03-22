module output_block #(
    parameter WIDTH = 8,
    parameter DEPTH = 16,
    parameter ADDR_W = 4
)(
    input clk,
    input rst,
    input [WIDTH-1:0] wr_data,
    input [3:0] wr_en_fifo,
    input [3:0] rd_en_fifo,
    output [WIDTH-1:0] data_out_0,
    output [WIDTH-1:0] data_out_1,
    output [WIDTH-1:0] data_out_2,
    output [WIDTH-1:0] data_out_3,
    output [3:0] full,
    output [3:0] empty
);

    wire [WIDTH-1:0] data_out0, data_out1, data_out2, data_out3;

    fifo_sync #(WIDTH, DEPTH, ADDR_W) fifo0(
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en_fifo[0]),
        .rd_en(rd_en_fifo[0]),
        .data_in(wr_data),
        .data_out(data_out0),
        .full(full[0]),
        .empty(empty[0])
    );

    fifo_sync #(WIDTH, DEPTH, ADDR_W) fifo1(
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en_fifo[1]),
        .rd_en(rd_en_fifo[1]),
        .data_in(wr_data),
        .data_out(data_out1),
        .full(full[1]),
        .empty(empty[1])
    );

    fifo_sync #(WIDTH, DEPTH, ADDR_W) fifo2(
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en_fifo[2]),
        .rd_en(rd_en_fifo[2]),
        .data_in(wr_data),
        .data_out(data_out2),
        .full(full[2]),
        .empty(empty[2])
    );

    fifo_sync #(WIDTH, DEPTH, ADDR_W) fifo3(
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en_fifo[3]),
        .rd_en(rd_en_fifo[3]),
        .data_in(wr_data),
        .data_out(data_out3),
        .full(full[3]),
        .empty(empty[3])
    );

    assign data_out_0 = data_out0;
    assign data_out_1 = data_out1;
    assign data_out_2 = data_out2;
    assign data_out_3 = data_out3;
endmodule
