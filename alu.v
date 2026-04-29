module alu (
    input [2:0] opcode,
    input [7:0] inA,
    input [7:0] inB,
    output reg [7:0] out,
    output is_zero
);

    parameter HLT = 3'b000;
    parameter SKZ = 3'b001;
    parameter ADD = 3'b010;
    parameter AND = 3'b011;
    parameter XOR = 3'b100;
    parameter LDA = 3'b101;
    parameter STO = 3'b110;
    parameter JMP = 3'b111;

    assign is_zero = (inA == 8'b00000000) ? 1'b1 : 1'b0;

    always @(opcode, inA, inB) begin
        case (opcode)
            HLT: out = inA;
            SKZ: out = inA;
            ADD: out = inA + inB;
            AND: out = inA & inB;
            XOR: out = inA ^ inB;
            LDA: out = inB;
            STO: out = inA;
            JMP: out = inA;
            default: out = inA;
        endcase
    end

endmodule
