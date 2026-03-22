module fifo_sync #(
    parameter WIDTH = 8,
    parameter DEPTH = 16,
    parameter ADDR_W = 4
)(
    input clk,
    input rst,
    input wr_en,
    input rd_en,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out,
    output full,
    output empty
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_W-1:0] wr_ptr;
    reg [ADDR_W-1:0] rd_ptr;
    reg [ADDR_W:0] count;

    wire wr_ok;
    wire rd_ok;

    assign wr_ok = wr_en && !full;
    assign rd_ok = rd_en && !empty;

    assign full = (count == DEPTH);
    assign empty = (count == 0);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            wr_ptr <= {ADDR_W{1'b0}};
            rd_ptr <= {ADDR_W{1'b0}};
            count <= {(ADDR_W+1){1'b0}};
            data_out <= {WIDTH{1'b0}};
        end
        else begin
            case ({wr_ok, rd_ok})
                2'b10: begin
                    mem[wr_ptr] <= data_in;
                    wr_ptr <= wr_ptr + 1'b1;
                    count <= count + 1'b1;
                end

                2'b01: begin
                    data_out <= mem[rd_ptr];
                    rd_ptr <= rd_ptr + 1'b1;
                    count <= count - 1'b1;
                end

                2'b11: begin
                    mem[wr_ptr] <= data_in;
                    wr_ptr <= wr_ptr + 1'b1;
                    data_out <= mem[rd_ptr];
                    rd_ptr <= rd_ptr + 1'b1;
                end

                default: begin
                end
            endcase
        end
    end
endmodule
