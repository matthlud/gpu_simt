// Simple ISA Definitions
package gpu_isa_pkg;
    typedef enum logic [3:0] {
        NOP   = 4'b0000,
        ADD   = 4'b0001, // R[rd] = R[rs1] + R[rs2]
        SUB   = 4'b0010, // R[rd] = R[rs1] - R[rs2]
        MOV   = 4'b0011, // R[rd] = imm
        LDR   = 4'b0100, // Load from memory
        STR   = 4'b0101, // Store to memory
        BEQ   = 4'b0110, // Branch if equal (updates mask)
        JMP   = 4'b0111  // Unconditional Jump
    } opcode_t;

    typedef struct packed {
        opcode_t        opcode;
        logic [3:0]     rd;
        logic [3:0]     rs1;
        logic [3:0]     rs2;
        logic [15:0]    imm; // Immediate value or branch target
    } instruction_t;
endpackage
