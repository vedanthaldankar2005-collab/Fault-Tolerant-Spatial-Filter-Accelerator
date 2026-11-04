Fault-Tolerant 3×3 Spatial Filter Accelerator

Project Overview

Design and ASIC Implementation of a Fault-Tolerant 3×3 Spatial Filter Accelerator Using Triple Modular Redundancy (TMR), Register Parity, and Residue-Based Error Detection.

This project focuses on developing a safety-aware hardware accelerator for digital image processing with fault detection and recovery mechanisms.

Key Features

- 3×3 spatial image filtering
- Sobel-X edge detection
- AXI4-Lite interface
- Triple Modular Redundancy (TMR)
- Register parity checking
- Modulo-31 residue-based error detection
- Python-based golden reference model
- SystemVerilog functional verification

Technologies and Tools

- Verilog / SystemVerilog
- Python
- Icarus Verilog
- GTKWave
- Yosys
- Sky130 PDK
- KLayout

Hardware Architecture

The accelerator includes:

1. AXI4-Lite register interface
2. Window generation module
3. Multiply-Accumulate (MAC) unit
4. Spatial filter processing unit
5. TMR-based fault-tolerance module
6. Error detection and recovery logic

Verification

The design is verified using SystemVerilog testbenches and a Python golden reference model.

ASIC Implementation

RTL synthesis is performed using Yosys with the Sky130 PDK toolchain.

Research Contribution

The project explores the integration of spatial image filtering with hardware-level fault tolerance using TMR, register parity, and residue-based error detection.

Research Publication

Paper: Design and ASIC Implementation of a Fault-Tolerant 3×3 Spatial Filter Accelerator Using TMR, Register Parity, and Residue-Based Error Detection.

Conference: ONCON26

Status: Accepted for presentation; final manuscript and publication process pending.

Author

Vedant K. Haldankar

Electronics and Communication Engineering
Jain College of Engineering, Belagavi, India

Disclaimer

This repository contains the project implementation and supporting documentation. Refer to the individual source files for implementation details.