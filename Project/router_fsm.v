module router_fsm (
    input clk,
    input rst,
    input packet_valid,
    input [5:0] length,
    input [7:0] parity_calc,
    input [7:0] parity_byte,
    input fifo_full,
    output reg load_header,
    output reg load_parity,
    output reg clr_all,
    output reg clr_parity,
    output reg parity_acc_en,
    output reg wr_en_global,
    output reg busy,
    output reg error,
    output reg done
);

    reg [3:0] state, next_state;
    reg [5:0] payload_rem;

    localparam S_IDLE = 4'd0,
               S_HEADER = 4'd1,
               S_PAYLOAD = 4'd2,
               S_WAIT_FIFO = 4'd3,
               S_PARITY_WAIT = 4'd4,
               S_PARITY = 4'd5,
               S_CHECK = 4'd6,
               S_DONE = 4'd7,
               S_ERROR = 4'd8;

    always @(posedge clk or negedge rst) begin
        if (!rst)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            payload_rem <= 6'd0;
        end
        else begin
            case (state)
                S_IDLE: begin
                    if (packet_valid)
                        payload_rem <= 6'd0;
                end

                S_HEADER: begin
                    if (length == 0)
                        payload_rem <= 6'd0;
                    else if (!fifo_full)
                        payload_rem <= length - 1'b1;
                    else
                        payload_rem <= length;
                end

                S_PAYLOAD: begin
                    if (!fifo_full && (payload_rem != 0))
                        payload_rem <= payload_rem - 1'b1;
                end

                default: begin
                    payload_rem <= payload_rem;
                end
            endcase
        end
    end

    always @(*) begin
        next_state = state;

        case (state)
            S_IDLE: begin
                if (packet_valid)
                    next_state = S_HEADER;
            end

            S_HEADER: begin
                if (length == 0)
                    next_state = S_PARITY_WAIT;
                else if (fifo_full)
                    next_state = S_WAIT_FIFO;
                else if (length == 1)
                    next_state = S_PARITY_WAIT;
                else
                    next_state = S_PAYLOAD;
            end

            S_PAYLOAD: begin
                if (fifo_full)
                    next_state = S_WAIT_FIFO;
                else if (payload_rem == 6'd1)
                    next_state = S_PARITY_WAIT;
            end

            S_WAIT_FIFO: begin
                if (!fifo_full) begin
                    if (payload_rem == 0)
                        next_state = S_PARITY;
                    else
                        next_state = S_PAYLOAD;
                end
            end

            S_PARITY_WAIT: begin
                next_state = S_PARITY;
            end

            S_PARITY: begin
                next_state = S_CHECK;
            end

            S_CHECK: begin
                if (parity_calc == parity_byte)
                    next_state = S_DONE;
                else
                    next_state = S_ERROR;
            end

            S_DONE: begin
                next_state = S_IDLE;
            end

            S_ERROR: begin
                next_state = S_IDLE;
            end

            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

    always @(*) begin
        load_header = 1'b0;
        load_parity = 1'b0;
        clr_all = 1'b0;
        clr_parity = 1'b0;
        parity_acc_en = 1'b0;
        wr_en_global = 1'b0;
        busy = 1'b1;
        error = 1'b0;
        done = 1'b0;

        case (state)
            S_IDLE: begin
                busy = 1'b0;
                if (packet_valid) begin
                    load_header = 1'b1;
                    clr_parity = 1'b1;
                end
                else begin
                    clr_all = 1'b1;
                    clr_parity = 1'b1;
                end
            end

            S_HEADER: begin
                if (length != 0 && !fifo_full) begin
                    parity_acc_en = 1'b1;
                    wr_en_global = 1'b1;
                end
            end

            S_PAYLOAD: begin
                parity_acc_en = !fifo_full;
                wr_en_global = !fifo_full;
            end

            S_PARITY: begin
                load_parity = 1'b1;
            end

            S_DONE: begin
                busy = 1'b0;
                done = 1'b1;
            end

            S_ERROR: begin
                busy = 1'b0;
                error = 1'b1;
            end
        endcase
    end
endmodule
