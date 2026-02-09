`timescale 1ns/1ps

module tiny_gpu_tb;
    import gpu_isa_pkg::*; // Import ISA definitions

    // Parameters
    localparam int NUM_THREADS = 4;
    localparam int DATA_WIDTH = 16;

    // Signals
    logic                   clk;
    logic                   rst_n;
    instruction_t           instr_in;
    logic [DATA_WIDTH-1:0]  mem_rdata [NUM_THREADS];
    logic [DATA_WIDTH-1:0]  mem_addr  [NUM_THREADS];
    logic [DATA_WIDTH-1:0]  mem_wdata [NUM_THREADS];
    logic                   mem_we    [NUM_THREADS];
    logic [15:0]            pc_out;

    // Instantiate the GPU Core (Device Under Test)
    tiny_gpu_core #(
        .NUM_THREADS(NUM_THREADS),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .instr_in(instr_in),
        .mem_rdata(mem_rdata),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_we(mem_we),
        .pc_out(pc_out)
    );

    // --- 1. Clock Generation ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // --- 2. "Magic" Memory ---
    // In a real GPU, this is complex DRAM. Here, we simulate unique data
    // for each thread to verify they are distinct.
    // If thread T asks for data, give it (Thread_ID + 10).
    genvar t;
    generate
        for (t = 0; t < NUM_THREADS; t++) begin : gen_mem
            // Simple combinational return: Data = Thread_ID + 10
            // E.g., Thread 0 gets 10, Thread 3 gets 13.
            assign mem_rdata[t] = t + 10;
        end
    endgenerate

    // --- 3. Instruction Memory (The Program) ---
    // This block acts as the Fetch Unit.
    always_comb begin
        // Defaults
        instr_in.opcode = NOP;
        instr_in.rd     = 0;
        instr_in.rs1    = 0;
        instr_in.rs2    = 0;
        instr_in.imm    = 0;

        case (pc_out)
            // ---------------------------------------------------------
            // STEP 1: Initialization
            // ---------------------------------------------------------
            // PC 0: Load unique IDs from memory into R1.
            // R1 will become: T0=10, T1=11, T2=12, T3=13
            16'd0: begin
                instr_in.opcode = LDR;
                instr_in.rs1    = 0; // Use R0 (initially 0) as address
                instr_in.rd     = 1; // Destination R1
            end

            // PC 1: Load Immediate 11 into R2.
            // All threads will have R2 = 11.
            16'd1: begin
                instr_in.opcode = MOV;
                instr_in.rd     = 2;
                instr_in.imm    = 16'd11;
            end

            // ---------------------------------------------------------
            // STEP 2: Divergence (The cool part)
            // ---------------------------------------------------------
            // PC 2: BEQ R1, R2.
            // Check: Is R1 == 11?
            // T0 (10 == 11?) -> False -> Mask OFF
            // T1 (11 == 11?) -> True  -> Mask ON
            // T2 (12 == 11?) -> False -> Mask OFF
            // T3 (13 == 11?) -> False -> Mask OFF
            16'd2: begin
                instr_in.opcode = BEQ;
                instr_in.rs1    = 1;
                instr_in.rs2    = 2;
                instr_in.imm    = 16'd3; // Branch target (next instruction)
            end

            // ---------------------------------------------------------
            // STEP 3: Masked Execution
            // ---------------------------------------------------------
            // PC 3: ADD R3 = R1 + R2
            // Only active threads (Thread 1) should write to R3.
            // Others should stay 0.
            16'd3: begin
                instr_in.opcode = ADD;
                instr_in.rd     = 3;
                instr_in.rs1    = 1;
                instr_in.rs2    = 2;
            end

            // ---------------------------------------------------------
            // STEP 4: Re-convergence
            // ---------------------------------------------------------
            // PC 4: JMP to finish (Resets mask)
            16'd4: begin
                instr_in.opcode = JMP;
                instr_in.imm    = 16'd5;
            end

            // PC 5: End of simulation
            16'd5: instr_in.opcode = NOP;

            default: instr_in.opcode = NOP;
        endcase
    end

    // --- 4. Reporting & Verification ---
    initial begin
        // --- WAVEFORM DUMPING (ADD THIS) ---
        $dumpfile("sim/waveform.vcd"); // File path matches Makefile
        $dumpvars(0, tiny_gpu_tb);     // Dump all signals in this module
        // ------------------

        // Reset sequence
        rst_n = 0;
        @(posedge clk);
        @(posedge clk);
        rst_n = 1;

        $display("-------------------------------------------------------------");
        $display("GPU Core Simulation Start");
        $display("Goal: Thread 1 has value 11. Only Thread 1 should survive the check.");
        $display("-------------------------------------------------------------");

        // Run for a fixed number of cycles
        repeat (10) @(posedge clk) begin
            #1; // Wait for logic to settle after clock edge

            $display("PC: %0d | Op: %s | Mask: %b",
                pc_out, get_opcode_str(instr_in.opcode), dut.exec_mask);

            // Print Registers R1 (Data) and R3 (Result) for all threads
            $write("   R1(Data):  ");
            for (int i = 0; i < $size(dut.reg_file); i++) begin
                $write("[%0d]:%0d  ", i, dut.reg_file[i][1]);
            end
            $write("\n");

            $write("   R2(int):  ");
            for (int i = 0; i < $size(dut.reg_file); i++) begin
                $write("[%0d]:%0d  ", i, dut.reg_file[i][2]);
            end
            $write("\n");

            $write("   R3(Rslt):  ");
            for (int i = 0; i < $size(dut.reg_file); i++) begin
                $write("[%0d]:%0d  ", i, dut.reg_file[i][3]);
            end
            $write("\n");

            $display("-------------------------------------------------------------");
        end
        $finish;
    end

    // Helper function to print enum strings
    function string get_opcode_str(opcode_t op);
        case(op)
            NOP: return "NOP";
            ADD: return "ADD";
            SUB: return "SUB";
            MOV: return "MOV";
            LDR: return "LDR";
            STR: return "STR";
            BEQ: return "BEQ";
            JMP: return "JMP";
            default: return "???";
        endcase
    endfunction

endmodule
