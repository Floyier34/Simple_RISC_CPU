module risc_cpu (
    input clk,
    input rst,
    output halt
);

    wire [4:0] pc_out;
    wire [4:0] addr_mux_out;
    wire [7:0] ir_out;
    wire [7:0] ac_out;
    wire [7:0] alu_out;
    wire [7:0] mem_data;
    
    wire sel;
    wire rd;
    wire wr;
    wire ld_ir;
    wire ld_ac;
    wire ld_pc;
    wire inc_pc;
    wire data_e;
    wire is_zero;

    assign mem_data = data_e ? ac_out : 8'bzzzzzzzz;

    program_counter pc_inst (
        .clk(clk),
        .rst(rst),
        .ld_pc(ld_pc),
        .inc_pc(inc_pc),
        .in_pc(ir_out[4:0]),
        .pc(pc_out)
    );

    address_mux #(.WIDTH(5)) addr_mux_inst (
        .inst_addr(pc_out),
        .op_addr(ir_out[4:0]),
        .sel(sel),
        .addr(addr_mux_out)
    );

    memory mem_inst (
        .clk(clk),
        .rd(rd),
        .wr(wr),
        .addr(addr_mux_out),
        .data(mem_data)
    );

    register #(.WIDTH(8)) ir_inst (
        .clk(clk),
        .rst(rst),
        .ld(ld_ir),
        .data_in(mem_data),
        .data_out(ir_out)
    );

    register #(.WIDTH(8)) ac_inst (
        .clk(clk),
        .rst(rst),
        .ld(ld_ac),
        .data_in(alu_out),
        .data_out(ac_out)
    );

    alu alu_inst (
        .opcode(ir_out[7:5]),
        .inA(ac_out),
        .inB(mem_data),
        .out(alu_out),
        .is_zero(is_zero)
    );

    controller ctrl_inst (
        .clk(clk),
        .rst(rst),
        .opcode(ir_out[7:5]),
        .is_zero(is_zero),
        .sel(sel),
        .rd(rd),
        .ld_ir(ld_ir),
        .halt(halt),
        .inc_pc(inc_pc),
        .ld_ac(ld_ac),
        .ld_pc(ld_pc),
        .wr(wr),
        .data_e(data_e)
    );

endmodule
