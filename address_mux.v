module address_mux #(parameter WIDTH = 5) (
    input [WIDTH-1:0] inst_addr,
    input [WIDTH-1:0] op_addr,
    input sel,
    output [WIDTH-1:0] addr
);

    // sel = 1 for instruction address, sel = 0 for operand address
    assign addr = sel ? inst_addr : op_addr;

endmodule
