module ahb_master (
    input wire         HCLK,
    input wire         HRESETn,
    input wire         HREADY,
    input wire         HRESP,
    input wire  [31:0] HRDATA,

    input wire  [31:0] HADDR_IN,
    input wire         HWRITE_IN,
    input wire  [2:0]  HSIZE_IN,
    input wire  [2:0]  HBURST_IN,      // single, incr
    input wire         START_TRANS_IN, // must remain asserted during the whole transaction
    input wire         BUSY_IN,
    input wire         END_TRANS_IN,
    input wire  [31:0] HWDATA_IN,
    
    output reg  [31:0] HADDR,
    output reg         HWRITE,
    output reg  [2:0]  HSIZE,
    output reg  [2:0]  HBURST,
    output reg  [1:0]  HTRANS,
    output reg  [31:0] HWDATA
);

reg [31:0] slave_mem [0:2047];
    
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


localparam IDLE_S       = 2'b00, 
           ADDR_S       = 2'b01, 
           WRITE_DATA_S = 2'b10,
           READ_DATA_S  = 2'b11;


reg [1:0] current_state, next_state;

always @(posedge HCLK or negedge HRESETn) begin
    if(!HRESETn) begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end


always @(posedge HCLK or negedge HRESETn) begin
    if(!HRESETn) begin
        HTRANS <= IDLE;
        HBURST <= SINGLE;
        HWRITE <= 1'd0;
        HSIZE  <= BYTE;
    end
    else if(HREADY) begin
        HBURST <= HBURST_IN;
        HWRITE <= HWRITE_IN;
        HSIZE  <= HSIZE_IN;
    end
end

always @(posedge HCLK or negedge HRESETn) begin
    if(!HRESETn) begin
        HADDR <= 32'd0;
        HTRANS <= IDLE;
    end
    else if(HBURST == SINGLE && HREADY) begin
        HADDR <= HADDR_IN;
        HTRANS <= NONSEQ;
    end   
    else if(BUSY_IN) begin
        HTRANS <= BUSY;
    end
    else if((current_state == WRITE_DATA_S || current_state == READ_DATA_S) && HBURST == INCR && HREADY) begin
        HADDR <= HADDR + (1 << HSIZE);
        HTRANS <= SEQ;
    end
    else if (((current_state == WRITE_DATA_S || current_state == READ_DATA_S) && HBURST == INCR && END_TRANS_IN && START_TRANS_IN)) begin
        HTRANS <= NONSEQ;
    end

end

always @(posedge HCLK or negedge HRESETn) begin
    if(!HRESETn) begin
        HWDATA <= 32'd0;
    end
    else if(HREADY) begin
        HWDATA <= HWDATA_IN;
    end
end

always @(*) begin

    next_state = current_state;
    case(current_state)
        IDLE_S: begin
            // default values
            HADDR  = 32'd0;
            HBURST = SINGLE;
            HWRITE = 1'd0;
            HSIZE  = BYTE;
            HWDATA    = 32'd0;
            HTRANS = IDLE;
            if(START_TRANS_IN) begin
                next_state = ADDR_S;
            end
            else begin
                next_state = IDLE;
            end
        end

        ADDR_S: begin
            HTRANS = NONSEQ; 
            if(HWRITE) begin
                next_state = WRITE_DATA_S;
            end
            else begin
                next_state = READ_DATA_S;
            end
        end
        WRITE_DATA_S: begin
            if(!HREADY) begin
                next_state = WRITE_DATA_S;
            end
            else if(START_TRANS_IN && HWRITE) begin
                next_state = WRITE_DATA_S;
            end
            else if(START_TRANS_IN && !HWRITE) begin
                next_state = READ_DATA_S;
            end
            else if (END_TRANS_IN) begin
                next_state = IDLE_S;
            end
            else begin
                next_state = WRITE_DATA_S;
            end
        end

        READ_DATA_S: begin
            if(!HREADY) begin
                next_state = READ_DATA_S;
            end
            else if(START_TRANS_IN && HWRITE) begin
                next_state = WRITE_DATA_S;
            end
            else if(START_TRANS_IN && !HWRITE) begin
                next_state = READ_DATA_S;
            end
            else if(END_TRANS_IN) begin
                next_state = IDLE_S;
            end
            else begin
                next_state = READ_DATA_S;
            end
        end
        default: begin 
            next_state = current_state;
        end
    endcase
end


endmodule