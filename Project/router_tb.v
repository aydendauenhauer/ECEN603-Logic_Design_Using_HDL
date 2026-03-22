module router_tb;
    reg clk;
    reg rst;
    reg packet_valid;
    reg [7:0] data_in;
    reg [3:0] rd_en;
    wire [7:0] data_out_0;
    wire [7:0] data_out_1;
    wire [7:0] data_out_2;
    wire [7:0] data_out_3;
    wire [3:0] full;
    wire [3:0] empty;
    wire busy;
    wire error;
    wire packet_done;

    router_top dut(clk, rst, packet_valid, data_in, rd_en, data_out_0, data_out_1,
                   data_out_2, data_out_3, full, empty, busy, error, packet_done);

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task do_reset;
        begin
            rst = 1'b0;
            packet_valid = 1'b0;
            data_in = 8'd0;
            rd_en = 4'b0000;
            #20;
            rst = 1'b1;
        end
    endtask

    task send_byte;
        input [7:0] b;
        begin
            @(negedge clk);
            packet_valid = 1'b1;
            data_in   = b;
        end
    endtask

    task end_stream;
        begin
            @(negedge clk);
            packet_valid = 1'b0;
            data_in   = 8'd0;
        end
    endtask

    task send_packet;
        input [1:0] dest;
        input [5:0] len;
        input [7:0] p0;
        input [7:0] p1;
        input [7:0] p2;
        input [7:0] p3;
        reg [7:0] header;
        reg [7:0] parity;
        begin
            header = {dest, len};
            parity = header;
            send_byte(header);

            if (len > 0) begin
                send_byte(p0);
                parity = parity ^ p0;
            end
            if (len > 1) begin
                send_byte(p1);
                parity = parity ^ p1;
            end
            if (len > 2) begin
                send_byte(p2);
                parity = parity ^ p2;
            end
            if (len > 3) begin
                send_byte(p3);
                parity = parity ^ p3;
            end

            @(negedge clk);  // extra gap cycle
            packet_valid = 1'b0;
            data_in = 8'd0;

            send_byte(parity);
            end_stream;
        end
    endtask

    task send_bad_parity_packet;
        input [1:0] dest;
        input [5:0] len;
        input [7:0] p0;
        input [7:0] p1;
        reg [7:0] header;
        reg [7:0] bad_parity;

        begin
            header = {dest, len};
            bad_parity = 8'h00;
            send_byte(header);

            if (len > 0) send_byte(p0);
            if (len > 1) send_byte(p1);

            send_byte(bad_parity);
            end_stream;
        end
    endtask

    task read_port;
        input [1:0] port;
        begin
            @(posedge clk);
            case (port)
                2'd0: rd_en <= 4'b0001;
                2'd1: rd_en <= 4'b0010;
                2'd2: rd_en <= 4'b0100;
                2'd3: rd_en <= 4'b1000;
            endcase

            @(posedge clk);
            #1;
            case (port)
                2'd0: $display("Read port 0 -> %02h @ %0t", data_out_0, $time);
                2'd1: $display("Read port 1 -> %02h @ %0t", data_out_1, $time);
                2'd2: $display("Read port 2 -> %02h @ %0t", data_out_2, $time);
                2'd3: $display("Read port 3 -> %02h @ %0t", data_out_3, $time);
            endcase
            rd_en <= 4'b0000;
        end
    endtask

    initial begin
        $monitor("rst=%0b packet_valid=%0b data_in=%02h busy=%0b error=%0b done=%0b full=%b empty=%b data_out0=%02h data_out1=%02h data_out2=%02h data_out3=%02h @ %t", rst, packet_valid, data_in, busy, error, packet_done, full, empty, data_out_0, data_out_1, data_out_2, data_out_3, $time);
/*    $monitor("rst=%0b packet_valid=%0b data_in=%02h state=%0d header_byte=%02h dest=%0d len=%0d parity_calc=%02h parity_byte=%02h wr_en=%0b wr_fifo=%b full=%b empty=%b err=%0b done=%0b @ %t",
             rst,
             packet_valid,
             data_in,
             dut.router_fsm0.state,
             dut.header_byte,
             dut.dest,
             dut.length,
             dut.parity_calc,
             dut.parity_byte,
             dut.wr_en_global,
             dut.wr_en_fifo,
             full,
             empty,
             error,
             packet_done,
             $time);

$monitor("T=%0t state=%0d din=%02h hdr=%02h rem=%0d pcalc=%02h pbyte=%02h wr=%0b",
         $time,
         dut.router_fsm0.state,
         data_in,
         dut.header_byte,
         dut.router_fsm0.payload_rem,
         dut.parity_calc,
         dut.parity_byte,
         dut.wr_en_global);*/
    end


    integer i;
    initial begin
        do_reset;

        $display("Send a good packet to port 0");
        send_packet(2'd0, 6'd2, 8'hAA, 8'h55, 8'h00, 8'h00);
        repeat (6) @(posedge clk);
        read_port(2'd0);
        read_port(2'd0);
        repeat (6) @(posedge clk);

        $display("Send a good packet to port 2");
        send_packet(2'd2, 6'd3, 8'h11, 8'h22, 8'h33, 8'h00);
        repeat (8) @(posedge clk);
        read_port(2'd2);
        read_port(2'd2);
        read_port(2'd2);

        repeat (4) @(posedge clk);

        $display("Send a bad packet to port 1");
        send_bad_parity_packet(2'd1, 6'd2, 8'hDE, 8'hAD);
        repeat (6) @(posedge clk);

        $display("Fill FIFO 3 with several small packets");
        for (i = 0; i < 6; i = i + 1) begin
            send_packet(2'd3, 6'd2, i, i+8'h10, 8'h00, 8'h00);
            repeat (3) @(posedge clk);
        end

        repeat (20) @(posedge clk);

        $finish;
    end
endmodule
