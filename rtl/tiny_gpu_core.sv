`default_nettype none

module tiny_gpu_core
    import gpu_isa_pkg::*;
#(
    parameter int NUM_THREADS = 4, // "Warp size"
    parameter int DATA_WIDTH = 16
) (
    input  wire logic                   clk,
    input  wire logic                   rst_n,
    input  wire instruction_t           instr_in,     // Instruction from Fetch Unit
    input  wire logic [DATA_WIDTH-1:0]  mem_rdata [NUM_THREADS], // Data from Memory
    output logic  [DATA_WIDTH-1:0]      mem_addr  [NUM_THREADS], // Address to Memory
    output logic  [DATA_WIDTH-1:0]      mem_wdata [NUM_THREADS], // Data to Memory
    output logic                        mem_we    [NUM_THREADS], // Write Enable
    output logic  [15:0]                pc_out        // Current PC (for Fetch Unit)
);

    // --- Registers ---
    // 2D Array: [Thread ID][Register ID]
    // Each thread has its own set of 16 registers
    logic [DATA_WIDTH-1:0] reg_file [NUM_THREADS][16];

    // Execution Mask: Determines which threads are active
    // In a real GPU, this is handled by a sophisticated stack for nested branches.
    logic [NUM_THREADS-1:0] exec_mask;

    logic [15:0] pc;

    // --- Execution Logic ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= '0;
            exec_mask <= '1; // All threads active

            // Reset registers (optional, normally huge register files aren't reset)
            for (int t = 0; t < NUM_THREADS; t++) begin
                for (int r = 0; r < 16; r++) begin
                    reg_file[t][r] <= '0;
                end
                mem_we[t] <= 0;
            end
        end else begin
            // Default Memory Signals
            for (int t = 0; t < NUM_THREADS; t++) mem_we[t] <= 0;

            case (instr_in.opcode)
                ADD: begin
                    for (int t = 0; t < NUM_THREADS; t++) begin
                        if (exec_mask[t]) begin
                            reg_file[t][instr_in.rd] <= reg_file[t][instr_in.rs1] + reg_file[t][instr_in.rs2];
                        end
                    end
                    pc <= pc + 1;
                end

                SUB: begin
                    for (int t = 0; t < NUM_THREADS; t++) begin
                        if (exec_mask[t]) begin
                            reg_file[t][instr_in.rd] <= reg_file[t][instr_in.rs1] - reg_file[t][instr_in.rs2];
                        end
                    end
                    pc <= pc + 1;
                end

                MOV: begin
                    for (int t = 0; t < NUM_THREADS; t++) begin
                        if (exec_mask[t]) begin
                            reg_file[t][instr_in.rd] <= instr_in.imm[DATA_WIDTH-1:0];
                        end
                    end
                    pc <= pc + 1;
                end

                // Memory Load (Gather)
                LDR: begin
                    for (int t = 0; t < NUM_THREADS; t++) begin
                        if (exec_mask[t]) begin
                           // 1. Output the address (for debug/real memory)
                           mem_addr[t] <= reg_file[t][instr_in.rs1];
                           // 2. CAPTURE THE DATA (This was missing!)
                           // Since the TB memory is constant/combinational, we can read it now.
                           reg_file[t][instr_in.rd] <= mem_rdata[t];
                        end
                    end
                    pc <= pc + 1;
                end

                // Memory Store (Scatter)
                STR: begin
                    for (int t = 0; t < NUM_THREADS; t++) begin
                        if (exec_mask[t]) begin
                            mem_addr[t]  <= reg_file[t][instr_in.rs1]; // Address
                            mem_wdata[t] <= reg_file[t][instr_in.rs2]; // Data
                            mem_we[t]    <= 1'b1;
                        end
                    end
                    pc <= pc + 1;
                end

                // Divergent Branching (The "GPU" Magic)
                BEQ: begin
                    // If rs1 == rs2, update the mask to disable threads that FAILED the check
                    // A real GPU pushes the current mask to a stack to restore it later (re-convergence).
                    for (int t = 0; t < NUM_THREADS; t++) begin
                        if (exec_mask[t]) begin
                            if (reg_file[t][instr_in.rs1] != reg_file[t][instr_in.rs2]) begin
                                exec_mask[t] <= 0; // Disable this thread
                            end
                        end
                    end
                    // We don't jump PC here in SIMT usually; we step through and mask off.
                    // But for simple loops, if ALL threads agree, we jump.
                    // This is a simplification.
                    pc <= instr_in.imm;
                end

                // Re-enable all threads (Convergence point)
                JMP: begin
                    exec_mask <= '1;
                    pc <= instr_in.imm;
                end

                default: pc <= pc + 1;
            endcase
        end
    end

    assign pc_out = pc;

endmodule
