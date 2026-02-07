# Tools
IVERILOG = iverilog
VVP      = vvp
GTKWAVE  = gtkwave

# Flags
# -g2012: Enables SystemVerilog 2012 standard
# -Wall:  Enables all warnings
FLAGS    = -g2012 -Wall

# Directories
RTL_DIR  = rtl
TB_DIR   = tb
SIM_DIR  = sim

# Files (Order matters! Package must be first)
SRC      = $(RTL_DIR)/gpu_isa_pkg.sv \
           $(RTL_DIR)/tiny_gpu_core.sv \
           $(TB_DIR)/tiny_gpu_tb.sv

# Output Targets
TARGET   = $(SIM_DIR)/gpu_sim.out
DUMP     = $(SIM_DIR)/waveform.vcd

# --- Rules ---

# Default target: Compile and Run
all: compile run

# 1. Compile the Verilog into a vvp assembly file
compile:
	@mkdir -p $(SIM_DIR)
	@echo "Compiling SystemVerilog sources..."
	$(IVERILOG) $(FLAGS) -o $(TARGET) $(SRC)
	@echo "Compilation successful."

# 2. Run the simulation
run:
	@echo "Running Simulation..."
	$(VVP) $(TARGET)

# 3. View Waveforms (requires GTKWave)
wave:
	@echo "Opening Waveforms..."
	$(GTKWAVE) $(DUMP) &

# Clean build artifacts
clean:
	rm -rf $(SIM_DIR)

.PHONY: all compile run wave clean
