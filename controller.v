module controller (
    input clk,
    input rst,
    input [2:0] opcode,
    input is_zero,
    output reg sel,
    output reg rd,
    output reg ld_ir,
    output reg halt,
    output reg inc_pc,
    output reg ld_ac,
    output reg ld_pc,
    output reg wr,
    output reg data_e
);

    parameter INST_ADDR  = 3'b000;
    parameter INST_FETCH = 3'b001;
    parameter INST_LOAD  = 3'b010;
    parameter IDLE       = 3'b011;
    parameter OP_ADDR    = 3'b100;
    parameter OP_FETCH   = 3'b101;
    parameter ALU_OP     = 3'b110;
    parameter STORE      = 3'b111;

    parameter HLT = 3'b000;
    parameter SKZ = 3'b001;
    parameter ADD = 3'b010;
    parameter AND = 3'b011;
    parameter XOR = 3'b100;
    parameter LDA = 3'b101;
    parameter STO = 3'b110;
    parameter JMP = 3'b111;

    reg [2:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= INST_ADDR;
        end else begin
            state <= state + 1'b1;
        end
    end

    always @(state, opcode, is_zero) begin

        case (state)
            INST_ADDR: begin
                sel    = 1'b1;
                rd     = 1'b0;
                ld_ir  = 1'b0;
                halt   = 1'b0;
                inc_pc = 1'b0;
                ld_ac  = 1'b0;
                ld_pc  = 1'b0;
                wr     = 1'b0;
                data_e = 1'b0;
                
            end
            INST_FETCH: begin
                sel    = 1'b1;
                rd     = 1'b1;
                ld_ir  = 1'b0;
                halt   = 1'b0;
                inc_pc = 1'b0;
                ld_ac  = 1'b0;
                ld_pc  = 1'b0;
                wr     = 1'b0;
                data_e = 1'b0;
            end
            INST_LOAD: begin
                sel    = 1'b1;
                rd     = 1'b1;
                ld_ir  = 1'b1;
                halt   = 1'b0;
                inc_pc = 1'b0;
                ld_ac  = 1'b0;
                ld_pc  = 1'b0;
                wr     = 1'b0;
                data_e = 1'b0;
            end
            IDLE: begin
                sel    = 1'b1;
                rd     = 1'b1;
                ld_ir  = 1'b1;
                halt   = 1'b0;
                inc_pc = 1'b0;
                ld_ac  = 1'b0;
                ld_pc  = 1'b0;
                wr     = 1'b0;
                data_e = 1'b0;
            end
            OP_ADDR: begin
                sel    = 1'b0;
                rd     = 1'b0;
                ld_ir  = 1'b0;
                
                if (opcode == HLT) begin
                    halt = 1'b1;
                end else begin
                    halt = 1'b0;
                end
                
                inc_pc = 1'b1;
                ld_ac  = 1'b0;
                ld_pc  = 1'b0;
                wr     = 1'b0;
                data_e = 1'b0;
            end
            OP_FETCH: begin
                sel = 1'b0;
                if (opcode == ADD || opcode == AND || opcode == XOR || opcode == LDA) begin
                    rd = 1'b1;
                end else begin
                    rd = 1'b0;
                end

                ld_ir  = 1'b0;
                halt   = 1'b0;
                inc_pc = 1'b0;
                ld_ac  = 1'b0;
                ld_pc  = 1'b0;
                wr     = 1'b0;
                data_e = 1'b0;
            end
            ALU_OP: begin
                sel = 1'b0;
                if (opcode == ADD || opcode == AND || opcode == XOR || opcode == LDA) begin
                    rd = 1'b1;
                end else begin
                    rd = 1'b0;
                end

                ld_ir  = 1'b0;
                halt   = 1'b0;

                if (opcode == (SKZ && is_zero)) begin
                    inc_pc = 1'b1;
                end else begin
                    inc_pc = 1'b0;
                end
                ld_ac  = 1'b0;


                if (opcode == JMP) begin
                    ld_pc = 1'b1;
                end else begin
                    ld_pc = 1'b0;
                end

                wr     = 1'b0;

                if (opcode == STO) begin
                    data_e = 1'b1;
                end else begin
                    data_e = 1'b0;
                end
            end
            STORE: begin
                sel = 1'b0;
                if (opcode == ADD || opcode == AND || opcode == XOR || opcode == LDA) begin
                    rd    = 1'b1;
                    ld_ac = 1'b1;
                end else begin
                    rd    = 1'b0;
                    ld_ac = 1'b0;
                end

                ld_ir  = 1'b0;
                halt   = 1'b0;
                inc_pc = 1'b0;


                if (opcode == JMP) begin
                    ld_pc = 1'b1;
                end else begin
                    ld_pc = 1'b0;
                end

                if (opcode == STO) begin
                    wr     = 1'b1;
                    data_e = 1'b1;
                end else begin
                    wr     = 1'b0;
                    data_e = 1'b0;
                end
            end
            default: begin
                sel    = 1'b0;
                rd     = 1'b0;
                ld_ir  = 1'b0;
                halt   = 1'b0;
                inc_pc = 1'b0;
                ld_ac  = 1'b0;
                ld_pc  = 1'b0;
                wr     = 1'b0;
                data_e = 1'b0;
            end
        endcase
    end

endmodule
