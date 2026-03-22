module dest_decode (
    input [1:0] dest,
    input wr_en_global,
    output [3:0] wr_en_fifo
);

    assign wr_en_fifo[0] = wr_en_global && (dest == 2'd0);
    assign wr_en_fifo[1] = wr_en_global && (dest == 2'd1);
    assign wr_en_fifo[2] = wr_en_global && (dest == 2'd2);
    assign wr_en_fifo[3] = wr_en_global && (dest == 2'd3);
endmodule
