# Copilot Instructions for LT_NPU Verilog Project

## Architecture Overview
This is a tiled Neural Processing Unit (NPU) accelerator for Convolutional Neural Networks (CNNs), supporting operations like convolution (conv), max pooling (maxpooling), depthwise convolution (DW), pointwise convolution (PW), global average pooling (GAP), and fully connected (FC) layers.

- **Top-level**: `Core/Core.v` integrates all components with a controller (`Core_Controller.v`) managing FSM states (idle, set_up, processing, ending, finish).
- **Processing Elements**: `Core/PE/PE_v2.v` performs multiply-accumulate (MAC) for conv/FC, shift operations for GAP. Uses signed 16-bit inputs, 32-bit outputs.
- **Address Generation**: AGU modules (`Core/AGU_F/`, `AGU_W/`, `AGU_O/`) handle memory addressing for features, weights, and outputs.
- **Accumulation**: `Core/Accumulator/` accumulates PE results across tiles.
- **Buffers**: Various buffers (`Array_buffer.v`, `W_buffer.v`, etc.) manage data tiling and storage.
- **Data Flow**: Operates on 64-bit tiles with addresses, controlled by mode, padding, ReLU flags.

## Key Patterns & Conventions
- **Versioning**: Components have versions (e.g., `PE_v2.v`, `Accumulator_v1.v`) for iterative improvements.
- **Pipelining**: Use shift registers (SR) for timing delays (e.g., 4-cycle PE pipeline). Always initialize `next_*` variables in `always@(*)` to avoid latches.
- **Modes & Parameters**: Define operation modes as parameters (e.g., `parameter MAC = 0, GAP = 1` in PE). Controllers use case statements for mode-specific logic.
- **Signed Arithmetic**: Fixed-point computations with sign extension (e.g., `{{12{PE_A[15]}}, PE_A, 4'b0}` for shifting).
- **Comments**: Section dividers with `////////// section //////////`.
- **Module Instantiation**: Use named port connections for clarity.

## Development Workflows
- **Simulation**: Testbenches in `Core_sim/` (e.g., `tb_PE.v`) use timescale `1ns/1ps`, clock toggles every 2.5ns (~200MHz). Run with Verilog simulator like ModelSim: `vsim tb_PE`.
- **Testing**: Focus on timing delays, signed overflow, and mode switching. Use `#` delays for stimulus.
- **Debugging**: Check waveforms for pipeline stalls, address calculations, and accumulator overflows.
- **Integration**: Components communicate via enable signals (`en`, `ena`, `enb`) and done flags (`core_done`, `AGU_O_done`).

## Common Pitfalls
- Incomplete mode cases in muxes (e.g., `pass` mode in PE output mux).
- Uninitialized combinational logic causing latches.
- Signed multiplication overflow in PE (16x16 -> 32-bit).
- Tile size mismatches in buffers.