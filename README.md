# RV32I Pipelined Processor

A from-scratch implementation of a 32-bit RISC-V processor
using SystemVerilog.

## Project Goals

- Understand and implement a complete processor datapath
- Implement the RV32I instruction set
- Build a 5-stage pipeline
- Handle data and control hazards
- Develop a self-checking verification environment
- Integrate the processor into a small SoC

## Architecture

- ISA: RV32I
- Data width: 32-bit
- Pipeline: 5-stage
- HDL: SystemVerilog
- Simulation: Icarus Verilog
- Waveform viewer: Surfer

## Project Structure

- `rtl/` — RTL source code
- `tb/` — testbenches
- `docs/` — design and debugging documentation
- `programs/` — RISC-V test programs
- `waveforms/` — waveform files

## Status

Project initialized.