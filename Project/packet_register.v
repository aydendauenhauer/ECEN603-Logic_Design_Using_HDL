module packet_register (
    input clk,
    input rst,
    input load_header,
    input load_parity,
    input clr_all,
    input clr_parity,
    input parity_acc_en,
    input [7:0] data_in,
    output reg [7:0] parity_byte,
    output reg [7:0] parity_calc,
    output [1:0] dest,
    output [5:0] length
);

    reg [7:0] header_byte;

    assign dest = header_byte[7:6];
    assign length = header_byte[5:0];

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            header_byte <= 8'd0;
            parity_byte <= 8'd0;
            parity_calc <= 8'd0;
        end
        else begin
            if (clr_all) begin
                header_byte <= 8'd0;
                parity_byte <= 8'd0;
                parity_calc <= 8'd0;
            end
            else begin
                if (clr_parity)
                    parity_calc <= 8'd0;

                if (load_header) begin
                    header_byte <= data_in;
                    parity_calc <= data_in;
                end
                else if (parity_acc_en) begin
                    parity_calc <= parity_calc ^ data_in;
                end

                if (load_parity)
                    parity_byte <= data_in;
            end
        end
    end
endmodule
