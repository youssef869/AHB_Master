`timescale 1ns/1ps
module ahb_master_tb ();

localparam CLK_PERIOD = 10;

reg         HCLK_tb;
reg         HRESETn_tb;
reg         HREADY_tb;
reg         HRESP_tb;
reg  [31:0] HRDATA_tb;

reg  [31:0] HADDR_IN_tb;
reg         HWRITE_IN_tb;
reg  [2:0]  HSIZE_IN_tb;
reg  [2:0]  HBURST_IN_tb; 
reg         START_TRANS_IN_tb;
reg         BUSY_IN_tb;
reg         END_TRANS_IN_tb;
reg  [31:0] HWDATA_IN_tb;
    
wire [31:0] HADDR_tb;
wire        HWRITE_tb;
wire [2:0]  HSIZE_tb;
wire [2:0]  HBURST_tb;
wire [1:0]  HTRANS_tb;
wire [31:0] HWDATA_tb;



ahb_master DUT(
.HCLK(HCLK_tb),
.HRESETn(HRESETn_tb),
.HREADY(HREADY_tb),
.HRESP(HRESP_tb),
.HRDATA(HRDATA_tb),
.HADDR_IN(HADDR_IN_tb),
.HWRITE_IN(HWRITE_IN_tb),
.HSIZE_IN(HSIZE_IN_tb),
.HBURST_IN(HBURST_IN_tb), 
.START_TRANS_IN(START_TRANS_IN_tb), 
.BUSY_IN(BUSY_IN_tb),
.END_TRANS_IN(END_TRANS_IN_tb),
.HWDATA_IN(HWDATA_IN_tb),
.HADDR(HADDR_tb),
.HWRITE(HWRITE_tb),
.HSIZE(HSIZE_tb),
.HBURST(HBURST_tb),
.HTRANS(HTRANS_tb),
.HWDATA(HWDATA_tb)
);


localparam IDLE   = 2'b00,
           BUSY   = 2'b01,
           NONSEQ = 2'b10,
           SEQ    = 2'b11;

localparam SINGLE = 3'b000,
           INCR   = 3'b001;


localparam BYTE     = 3'b000,
           HALFWORD = 3'b001,
           WORD     = 3'b010;


localparam OKAY  = 1'b0,
           ERROR = 1'b1;


reg [7:0] slave_mem [0:2047]; // 2KB words of memory representing the slave

always @(posedge HCLK_tb) begin
    if(HWRITE_tb && HREADY_tb) begin
        if(HSIZE_tb == WORD) begin
            {slave_mem[HADDR_tb[10:0] + 3], slave_mem[HADDR_tb[10:0] + 2], slave_mem[HADDR_tb[10:0] + 1],slave_mem[HADDR_tb[10:0]]} <= HWDATA_tb;
        end
        else if(HSIZE_tb == HALFWORD) begin
            {slave_mem[HADDR_tb[10:0] + 1],slave_mem[HADDR_tb[10:0]]} <= HWDATA_tb;
        end
        else if(HSIZE_tb == BYTE) begin
            slave_mem[HADDR_tb[10:0]] <= HWDATA_tb;
        end
    end
    else if(!HWRITE_tb && HREADY_tb) begin
        if(HSIZE_tb == WORD) begin
            HRDATA_tb <= {slave_mem[HADDR_tb[10:0] + 3], slave_mem[HADDR_tb[10:0] + 2], slave_mem[HADDR_tb[10:0] + 1],slave_mem[HADDR_tb[10:0]]};
        end
        else if(HSIZE_tb == HALFWORD) begin
            HRDATA_tb <= {slave_mem[HADDR_tb[10:0] + 1],slave_mem[HADDR_tb[10:0]]};
        end
        else if(HSIZE_tb == BYTE) begin
            HRDATA_tb <= slave_mem[HADDR_tb[10:0]];
        end
    end
end

initial begin
    HCLK_tb = 1'b0;
    forever #(CLK_PERIOD/2.0) HCLK_tb = ~HCLK_tb;
end


initial begin
    HRESETn_tb = 1'b1;
    HADDR_IN_tb = 'd0;
    // HRDATA_tb = 'd0;
    BUSY_IN_tb = 1'b0;
    START_TRANS_IN_tb = 1'b1;
    END_TRANS_IN_tb = 1'b0;
    #CLK_PERIOD;
    HRESETn_tb = 1'b0;
    #(2*CLK_PERIOD);
    HRESETn_tb = 1'b1;

    @(negedge HCLK_tb);
    HWRITE_IN_tb = 1'd1;
    HADDR_IN_tb = 'd100;
    HSIZE_IN_tb = WORD;
    HBURST_IN_tb = SINGLE;
    HWDATA_IN_tb = 'h44_55_66_77;
    HREADY_tb = 1'd1;
    HRESP_tb = OKAY;
    repeat(2) @(negedge HCLK_tb);
    START_TRANS_IN_tb = 1'b1;
    HWRITE_IN_tb = 1'b0;
    HADDR_IN_tb = 'd100;
    HSIZE_IN_tb = WORD;
    HBURST_IN_tb = SINGLE;
    HWDATA_IN_tb = 'h99_11_22_33;
    HREADY_tb = 1'd1;
    HRESP_tb = OKAY;
    repeat(2) @(negedge HCLK_tb);

    END_TRANS_IN_tb   = 1'b1;
    START_TRANS_IN_tb = 1'b1;
    HWRITE_IN_tb = 1'd1;
    HADDR_IN_tb = 'd120;
    HSIZE_IN_tb = WORD;
    HBURST_IN_tb = SINGLE;
    HWDATA_IN_tb = 'h12_34_56_01;
    HREADY_tb = 1'd1;
    HRESP_tb = OKAY;
    repeat(2) @(negedge HCLK_tb);
    HWRITE_IN_tb = 1'd0;
    // HRDATA_tb = 'd55;
    HREADY_tb = 1'd0;
    repeat(2) @(negedge HCLK_tb);
    HREADY_tb = 1'd1;
    repeat(2) @(negedge HCLK_tb);
    END_TRANS_IN_tb = 1'b1;
    START_TRANS_IN_tb = 1'b0;
    @(negedge HCLK_tb);
    HWRITE_IN_tb = 1'b1;
    START_TRANS_IN_tb = 1'b1;
    HADDR_IN_tb = 'd300;
    HSIZE_IN_tb = WORD;
    HBURST_IN_tb = INCR;
    HWDATA_IN_tb = 'h66_23_47_95;
    HREADY_tb = 1'd1;
    HRESP_tb = OKAY;
    @(negedge HCLK_tb);
    HWDATA_IN_tb = 'h99_FE_AB_CD;
    @(negedge HCLK_tb);
    HWDATA_IN_tb = 'h99_FE_AB_CD;
    @(negedge HCLK_tb);
    HWDATA_IN_tb = 'h99_FE_AB_CD;
    @(negedge HCLK_tb);
    HWDATA_IN_tb = 'h99_FE_AB_CD;
    @(negedge HCLK_tb);
    HWDATA_IN_tb = 'h99_FE_AB_CD;
    repeat(3) @(negedge HCLK_tb);
    END_TRANS_IN_tb   = 1'b1;
    START_TRANS_IN_tb = 1'b0;



    @(negedge HCLK_tb);
    START_TRANS_IN_tb = 1'b1;
    HWRITE_IN_tb = 1'b0;
    HADDR_IN_tb = 'd300;
    HSIZE_IN_tb = WORD;
    HBURST_IN_tb = INCR;
    HWDATA_IN_tb = 'hAB_DE_AD_FF;
    HREADY_tb = 1'd1;
    HRESP_tb = OKAY;
    repeat(5) @(negedge HCLK_tb);
    repeat(3) @(negedge HCLK_tb);


    @(negedge HCLK_tb);
    HWRITE_IN_tb = 1'd1;
    HADDR_IN_tb = 'd100;
    HSIZE_IN_tb = BYTE;
    HBURST_IN_tb = SINGLE;
    HWDATA_IN_tb = 'h78;
    HREADY_tb = 1'd1;
    HRESP_tb = OKAY;
    repeat(2) @(negedge HCLK_tb);
    START_TRANS_IN_tb = 1'b1;
    HWRITE_IN_tb = 1'b0;
    HADDR_IN_tb = 'd100;
    HSIZE_IN_tb = WORD;
    HBURST_IN_tb = SINGLE;
    HREADY_tb = 1'd1;
    HRESP_tb = OKAY;
    repeat(2) @(negedge HCLK_tb);


    @(negedge HCLK_tb);
    HWRITE_IN_tb = 1'd1;
    HADDR_IN_tb = 'd100;
    HSIZE_IN_tb = HALFWORD;
    HBURST_IN_tb = SINGLE;
    HWDATA_IN_tb = 'h56_78;
    HREADY_tb = 1'd1;
    HRESP_tb = OKAY;
    repeat(2) @(negedge HCLK_tb);
    START_TRANS_IN_tb = 1'b1;
    HWRITE_IN_tb = 1'b0;
    HADDR_IN_tb = 'd100;
    HSIZE_IN_tb = HALFWORD;
    HBURST_IN_tb = SINGLE;
    HREADY_tb = 1'd1;
    repeat(2) @(negedge HCLK_tb);
    $stop;

end
    
endmodule