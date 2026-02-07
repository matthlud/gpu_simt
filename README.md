# 8-bit Microprocessor

A tiny, synthesizable SIMT GPU implementation in SystemVerilog with simulation support.
(Repo generated with the aid of gen. AI.)

## Dependencies

Install the required tools:

```bash
sudo apt update
sudo apt install iverilog gtkwave                 # Synthesis and simulation
```

## Clone the Repo

```bash
git clone git@github.com:matthlud/gpu_simt.git
```

## Getting Started

### Compile and Run

Simulate the design at the RTL (Register Transfer Level):

```bash
make
```

This compiles and simulates the SystemVerilog design, generating a VCD waveform file.


### View Waveforms

Open the generated VCD waveform in GTKWave:

```bash
make wave
```

## Generate Documentation

## Specification

TODO


## Project Structure

```bash
tiny_gpu_sim/
├── rtl/
│   ├── gpu_isa_pkg.sv      # The package definition TODO
│   └── tiny_gpu_core.sv    # The GPU RTL module
├── tb/
│   └── tiny_gpu_tb.sv      # The Testbench (with VCD dump added)
├── sim/                    # Empty folder for simulation output
├── Makefile                # Automation script
├── .gitignore              # Git ignore file
└── README.md               # Instructions
``
