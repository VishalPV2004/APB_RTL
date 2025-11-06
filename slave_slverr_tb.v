module tb_s;
reg pclk = 0, presetn = 1, psel = 0, penable = 0, pwrite = 1;
reg [31:0] paddr = 0;
reg [7:0] pwdata = 0;
wire pslverr;
wire [7:0] prdata;
wire pready;

apb_s_err dut (
    .pclk(pclk),
    .presetn(presetn),
    .paddr(paddr),
    .psel(psel),
    .penable(penable),
    .pwdata(pwdata),
    .pwrite(pwrite),
    .prdata(prdata),
    .pready(pready),
    .pslverr(pslverr)
);

always #10 pclk = ~pclk;

initial begin
    presetn = 0;
    repeat (5) @(posedge pclk);
    presetn = 1;

    // valid write
    for (integer i = 0; i < 5; i = i + 1)
    begin
        @(posedge pclk);
        paddr = $urandom_range(0, 15);
        pwrite = 1;
        pwdata = $urandom;
        psel = 1;
        penable = 0;
        @(posedge pclk);
        penable = 1;
        @(posedge pclk);
        psel = 0;
        penable = 0;
    end

    // valid read
    for (integer i = 0; i < 5; i = i + 1)
    begin
        @(posedge pclk);
        pwrite = 0;
        paddr = $urandom_range(0, 15);
        pwdata = $urandom;
        psel = 1;
        penable = 0;
        @(posedge pclk);
        penable = 1;
        @(posedge pclk);
        psel = 0;
        penable = 0;
    end

    // invalid address range during write
    for (integer i = 0; i < 5; i = i + 1)
    begin
        @(posedge pclk);
        paddr = $urandom_range(16, 255);
        pwrite = 1;
        pwdata = $urandom;
        psel = 1;
        penable = 0;
        @(posedge pclk);
        penable = 1;
        @(posedge pclk);
        psel = 0;
        penable = 0;
    end

    // invalid address range during read
    for (integer i = 0; i < 5; i = i + 1)
    begin
        @(posedge pclk);
        paddr = $urandom_range(16, 255);
        pwrite = 0;
        pwdata = $urandom;
        psel = 1;
        penable = 0;
        @(posedge pclk);
        penable = 1;
        @(posedge pclk);
        psel = 0;
        penable = 0;
    end

    // invalid address values
    @(posedge pclk);
    pwrite = 1;
    paddr = 32'bxx00;
    pwdata = $urandom;
    psel = 1;
    penable = 0;
    @(posedge pclk);
    penable = 1;
    @(posedge pclk);
    psel = 0;
    penable = 0;

    // invalid data values
    @(posedge pclk);
    pwrite = 1;
    paddr = 2;
    pwdata = 8'b0110_1xxx;
    psel = 1;
    penable = 0;
    @(posedge pclk);
    penable = 1;
    @(posedge pclk);
    psel = 0;
    penable = 0;
end

initial begin
    #1420;
    $finish;
end
endmodule
