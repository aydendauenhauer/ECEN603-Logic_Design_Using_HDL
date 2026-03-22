module router_top (
    input clk,
    input rst,
    input packet_valid,
    input [7:0] data_in,
    input [3:0] rd_en,
    output [7:0] data_out_0,
    output [7:0] data_out_1,
    output [7:0] data_out_2,
    output [7:0] data_out_3,
    output [3:0] full,
    output [3:0] empty,
    output busy,
    output error,
    output packet_done
);

    wire load_header;
    wire load_parity;
    wire clr_all;
    wire clr_parity;
    wire parity_acc_en;
    wire wr_en_global;
    wire [7:0] parity_byte;
    wire [7:0] parity_calc;
    wire [1:0] dest;
    wire [5:0] length;
    wire [3:0] wr_en_fifo;

    reg selected_fifo_full;

    packet_register packet_register0(
        .clk(clk),
        .rst(rst),
        .load_header(load_header),
        .load_parity(load_parity),
        .clr_all(clr_all),
        .clr_parity(clr_parity),
        .parity_acc_en(parity_acc_en),
        .data_in(data_in),
        .parity_byte(parity_byte),
        .parity_calc(parity_calc),
        .dest(dest),
        .length(length)
    );

    router_fsm router_fsm0(
        .clk(clk),
        .rst(rst),
        .packet_valid(packet_valid),
        .length(length),
        .parity_calc(parity_calc),
        .parity_byte(parity_byte),
        .fifo_full(selected_fifo_full),
        .load_header(load_header),
        .load_parity(load_parity),
        .clr_all(clr_all),
        .clr_parity(clr_parity),
        .parity_acc_en(parity_acc_en),
        .wr_en_global(wr_en_global),
        .busy(busy),
        .error(error),
        .done(packet_done)
    );

    dest_decode dest_decode0(
        .dest(dest),
        .wr_en_global(wr_en_global),
        .wr_en_fifo(wr_en_fifo)
    );

    output_block #(8, 16, 4) output_block0(
        .clk(clk),
        .rst(rst),
        .wr_data(data_in),
        .wr_en_fifo(wr_en_fifo),
        .rd_en_fifo(rd_en),
        .data_out_0(data_out_0),
        .data_out_1(data_out_1),
        .data_out_2(data_out_2),
        .data_out_3(data_out_3),
        .full(full),
        .empty(empty)
    );

    always @(*) begin
        case (dest)
            2'd0: selected_fifo_full = full[0];
            2'd1: selected_fifo_full = full[1];
            2'd2: selected_fifo_full = full[2];
            2'd3: selected_fifo_full = full[3];
            default: selected_fifo_full = 1'b1;
        endcase
    end
endmodule
