module program_counter (
    input clk,
    input rst,
    input ld_pc,
    input inc_pc,
    input [4:0] in_pc,
    output reg [4:0] pc
);

    always @(posedge clk) begin
        if (rst) begin
            pc <= 5'b00000;
        end else if (ld_pc) begin
            pc <= in_pc;
        end else if (inc_pc) begin
            pc <= pc + 1'b1;
        end else begin
            pc <= pc;
        end
    end

endmodule
