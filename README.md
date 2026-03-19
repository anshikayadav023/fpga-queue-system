# FPGA-Based Queue Management System

> A fully synchronous, FSM-controlled token dispenser implemented in VHDL on the Intel DE10-Lite FPGA.

---

## Overview

This project implements a **Smart Queue Token Dispenser** using a **Moore Finite State Machine (FSM)** in VHDL.
It models real-world queue systems (e.g., ship cargo, service queues) with strict **event-driven control**.

The design emphasizes **event gating, state-dependent logic, and reliable hardware interfacing**, ensuring accurate and deterministic queue behavior.

* Arrival (token) increments **only once per valid input**
* Departure (service) is allowed **only if a prior arrival exists**
* Fully hardware-based (no processor or software dependency)

---

## Key Features

### FSM-Based Control

Moore FSM with 5 states:
IDLE → ISSUE_TOKEN → WAIT_FOR_SERVICE → NEXT_CALL → RESET

### Event-Gated Queue Logic

* Prevents duplicate token entries
* Ensures valid queue progression
* Enforces strict arrival-before-departure behavior

### Reliable Input Handling

* Debouncing using shift register + clock divider
* Two-stage synchronizers for metastability protection
* Clean, single-cycle input pulses

### Real-Time Hardware Interface

* Push-buttons (`KEY0`, `KEY1`) for control
* 4× seven-segment displays (00–99 range)
* LED indicators:

  * `LEDR0` → Busy
  * `LEDR1` → Ready

### Fully Synchronous Design

* Operates at 50 MHz
* No combinational feedback loops
* Glitch-free and stable outputs

---

## System Architecture

The system is divided into three main modules:

* **FSM Controller** — manages state transitions and control signals
* **Input Processing & Counters** — handles debouncing, synchronization, and queue logic
* **Display Logic** — converts binary values to BCD and drives seven-segment displays

---

## Top-Level Module

* `queue_system_top.vhd` — integrates FSM, input processing, counters, and display logic

---

## Technical Specifications

| Parameter       | Value           |
| --------------- | --------------- |
| FPGA Board      | Intel DE10-Lite |
| Language        | VHDL            |
| Clock Frequency | 50 MHz          |
| Token Range     | 00–99           |

---

## Project Structure

```
fpga-queue-system/
├── src/            # VHDL source files
├── testbench/      # Testbench files
├── constraints/    # Pin assignments (.qsf)
├── README.md
└── .gitignore
```

---
## Project Demo

A video demonstration of the FPGA-based queue system:

[Watch Demo](https://youtu.be/S81xoo1Tysg)

This demo showcases:

* Real-time token generation
* State transitions
* Display updates on FPGA hardware
## 📋 FSM State Table

The detailed state transition table used for designing the Moore FSM is available below:

[View State Table](docs/state_table.pdf)

This table defines:

* Present states
* Input conditions
* Next-state transitions
* Output behavior

It serves as the foundation for implementing deterministic FSM control logic.


## Verification

* FSM state transitions validated
* Counter behavior (increment, gating, wraparound) verified
* Debouncing and input handling tested
* Simulation performed using ModelSim / QuestaSim

---

## How to Run

1. Open **Intel Quartus Prime**
2. Create a new project
3. Add all `.vhd` files from `src/`
4. Set `queue_system_top.vhd` as top-level entity
5. Apply `.qsf` file from `constraints/`
6. Compile and program the FPGA

---

## Applications

* Queue systems (banks, hospitals, service centers)
* Ship/cargo handling systems
* Embedded control systems
* FPGA-based digital design projects

---

## Author

**Anshika Yadav**

---
