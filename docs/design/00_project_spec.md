# RV32I Pipelined Processor — Project Specification

## 1. Objective

The objective of this project is to design and implement a
32-bit RISC-V processor from scratch using SystemVerilog.

The project will begin with a simple functional processor and
progressively evolve into a 5-stage pipelined processor and,
eventually, a small SoC.

The implementation and documentation will record the design,
verification, debugging, and architectural decisions made
throughout the project.

---

## 2. Target Architecture

| Item | Specification |
|------|---------------|
| ISA | RISC-V RV32I |
| Data width | 32 bits |
| Register count | 32 |
| Pipeline | 5 stages |
| HDL | SystemVerilog |
| Simulation | Icarus Verilog |
| Waveform viewer | Surfer |

### Pipeline stages

1. IF — Instruction Fetch
2. ID — Instruction Decode
3. EX — Execute
4. MEM — Memory Access
5. WB — Write Back

---

## 3. Development Strategy

The processor will be developed incrementally.

### Phase 1 — Basic Components

- ALU
- Register File
- Immediate Generator
- Instruction Decoder
- Program Counter

### Phase 2 — Single-Cycle Processor

- Datapath
- Control Unit
- Instruction Memory
- Data Memory
- RV32I instruction execution

### Phase 3 — Pipelined Processor

- IF/ID pipeline register
- ID/EX pipeline register
- EX/MEM pipeline register
- MEM/WB pipeline register

### Phase 4 — Hazard Handling

- Data forwarding
- Load-use stalls
- Pipeline flushing
- Control hazards

### Phase 5 — Verification

- Unit tests
- Integration tests
- Directed instruction sequences
- Randomized testing
- Waveform-based debugging
- Assertions where appropriate

### Phase 6 — SoC Integration

Potential components:

- SRAM
- ROM
- UART
- GPIO
- Timer
- Memory-mapped I/O

---

## 4. Initial Instruction Set

The first implementation will support a small subset of RV32I:

### R-type

- ADD
- SUB
- AND
- OR
- XOR

### I-type

- ADDI
- LW

### S-type

- SW

### B-type

- BEQ

### J-type

- JAL

The supported instruction set may be expanded after the
initial processor becomes functional.

---

## 5. Verification Philosophy

Each module should have its own testbench before being
integrated into the processor.

The project will use self-checking testbenches rather than
relying only on manual waveform inspection.

Important bugs and debugging processes will be documented
instead of being removed from the project history.

---

## 6. Project Milestones

- [ ] Project setup
- [ ] ALU
- [ ] Register File
- [ ] Immediate Generator
- [ ] Instruction Decoder
- [ ] Single-Cycle CPU
- [ ] First RV32I program
- [ ] 5-stage Pipeline
- [ ] Forwarding
- [ ] Hazard Detection
- [ ] Branch Handling
- [ ] Comprehensive Verification
- [ ] SoC Integration
- [ ] Run C Program
- [ ] Final Documentation

---

## 7. Design Principle

The processor will be implemented from first principles.

The main objective is not only to produce a working CPU,
but to understand and document why each architectural
component is required and how the components interact.
