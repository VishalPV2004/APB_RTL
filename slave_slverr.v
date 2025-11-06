module apb_s_err
(
    input        pclk,
    input        presetn,
    input [31:0] paddr,
    input        psel,
    input        penable,
    input [7:0]  pwdata,
    input        pwrite,
    output reg [7:0] prdata,
    output reg       pready,
    output           pslverr
);

localparam [1:0] idle  = 2'd0;
localparam [1:0] write = 2'd1;
localparam [1:0] read  = 2'd2;

reg [7:0] mem [0:15];

reg [1:0] state, nstate;

wire addr_err, addv_err, data_err, cycle_err;

always @(posedge pclk or negedge presetn)
begin
    if (presetn == 1'b0)
        state <= idle;
    else
        state <= nstate;
end

always @(*)
begin
    case (state)
        idle:
        begin
            prdata = 8'h00;
            pready = 1'b0;
            if (psel == 1'b1 && pwrite == 1'b1)
                nstate = write;
            else if (psel == 1'b1 && pwrite == 1'b0)
                nstate = read;
            else
                nstate = idle;
        end

        write:
        begin
            if (psel == 1'b1 && penable == 1'b1)
            begin
                if (!addr_err && !addv_err && !data_err)
                begin
                    pready = 1'b1;
                    mem[paddr[3:0]] = pwdata;
                    nstate = idle;
                end
                else
                begin
                    nstate = idle;
                    pready = 1'b1;
                end
            end
            else
            begin
                prdata = 8'h00;
                pready = 1'b0;
                nstate = write;
            end
        end

        read:
        begin
            if (psel == 1'b1 && penable == 1'b1)
            begin
                if (!addr_err && !addv_err && !data_err)
                begin
                    pready = 1'b1;
                    prdata = mem[paddr[3:0]];
                    nstate = idle;
                end
                else
                begin
                    pready = 1'b1;
                    prdata = 8'h00;
                    nstate = idle;
                end
            end
            else
            begin
                prdata = 8'h00;
                pready = 1'b0;
                nstate = read;
            end
        end

        default:
        begin
            nstate = idle;
            prdata = 8'h00;
            pready = 1'b0;
        end
    endcase
end

reg av_t;
always @(*)
begin
    if (paddr >= 32'd0)
        av_t = 1'b0;
    else
        av_t = 1'b1;
end

reg dv_t;
always @(*)
begin
    if (pwdata >= 8'd0)
        dv_t = 1'b0;
    else
        dv_t = 1'b1;
end

assign addr_err = ((state == write || state == read) && (paddr > 32'd15)) ? 1'b1 : 1'b0;
assign addv_err = (state == write || state == read) ? av_t : 1'b0;
assign data_err = (state == write || state == read) ? dv_t : 1'b0;
assign cycle_err = ((state == write || state == read) && (penable == 0)) ? 1'b1 : 1'b0;
assign pslverr = (psel == 1'b1 && penable == 1'b1) ? (addv_err || addr_err || data_err) : 1'b0;

endmodule
