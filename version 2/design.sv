module axi_lite_master(
    axi_lite_if.master aif
);

typedef enum bit[1:0] { idle= 2'b00, addr_state= 2'b01, data_state = 2'b10, respond_state = 2'b11 } axi_master_state;
axi_master_state state = idle;

always@(posedge aif.clk)begin
    if(!aif.resetn)begin
        aif.awvalid <= 0;
        aif.awaddr <= 0;
        aif.wdata <= 0;
        aif.wvalid <= 0;
        aif.bready <= 0;
        aif.u_write_ack <= 0;
        aif.u_write_err <= 0;

        
        state <= idle;
    end

    else
    begin
        case (state)
            idle:begin
                aif.u_write_ack <= 0;
                aif.bready <= 0;
                if(aif.u_write_valid == 1)begin
                    aif.awaddr <= aif.u_write_addr;
                    aif.wdata <= aif.u_write_data;
                    state <= addr_state;
                    aif.awvalid <= 1;
                    //aif.wvalid <= 1;
                end
                else begin
                    state <= idle;
                    aif.awvalid <= 0;
                end
            end 

            addr_state: begin
                if(aif.awvalid && aif.awready == 1)begin
                    aif.wvalid <= 1;
                    aif.awvalid <= 0;
                    state <= data_state;
                end
                else begin
                state <= addr_state;
                aif.awvalid <= 1;
                end
            end

            data_state: begin
                if(aif.wvalid && aif.wready) begin
                    aif.bready <= 1;
                    aif.wvalid <= 0;
                    state <= respond_state;
                end
                else begin
                state <= data_state;
                aif.wvalid <= 1;
                end
            end

            respond_state: begin
                if(aif.bvalid && aif.bready)begin
                    state <= idle;
                    aif.bready <= 0;
                    aif.u_write_ack <= 1;
                    aif.u_write_err <= aif.bstatus;
                end
                else
                begin
                    state <= respond_state;
                    aif.bready <= 1;
                    
                end
            end
            default: state <= idle; 
        endcase
    end
end

endmodule



interface axi_lite_if;

logic clk, resetn; // global signals

//user inputs for write to master
logic u_write_valid;
logic [31:0] u_write_addr;
logic [31:0] u_write_data;

//user outputs from master for write
logic u_write_ack;
logic [1:0] u_write_err;


//master output signals to slave for write function
logic awvalid;
logic [31:0] awaddr;

logic [31:0] wdata;
logic wvalid;

logic bready;

//master input signals from slave for write function
logic awready;

logic wready;

logic [1:0]bstatus;
logic bvalid;

modport master(
    input clk,
    input resetn,

    input u_write_valid,
    input u_write_addr,
    input u_write_data,

    input awready,
    input wready,
    input bstatus,
    input bvalid,

    output u_write_ack,
    output u_write_err,

    output awvalid,
    output awaddr,

    output wdata,
    output wvalid,

    output bready
);

modport slave(
    input clk,
    input resetn,


    input awvalid,
    input awaddr,

    input wdata,
    input wvalid,

    input bready,

    output awready,
    output wready,
    output bstatus,
    output bvalid


);


endinterface