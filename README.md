# AHB-Lite Master Interface Design and Verification

This project includes designing, implementing, and verifying an AHB-Lite master interface in Verilog, done as part of the ADI Digital Design Internship. The master takes simple commands from the user side (address, data, start/end) and drives the AHB-Lite bus. It supports pipelined transfers, SINGLE and INCR bursts, and byte, halfword and word transfers, and it was verified with a directed testbench and a simple slave memory model.

---

## Table of Contents

- [1. Supported Features](#1-supported-features)
- [2. Master Interface](#2-master-interface)
- [3. FSM](#3-fsm)
- [4. Verilog RTL Implementation](#4-verilog-rtl-implementation)
- [5. Testbench & Verification](#5-testbench--verification)

---

## Project Flow

### 1. Supported Features

- **Pipelined operation:** address and data phases overlap, so a new transfer can start while the previous one completes.
- **Burst types:** SINGLE and INCR (undefined length). In INCR bursts the address increments by 2^HSIZE each transfer.
- **Data widths:** byte (8-bit), halfword (16-bit) and word (32-bit).
- **Wait states:** the master holds address, control and data while HREADY is low.
- **BUSY insertion:** asserting `BUSY_IN` makes the next HTRANS BUSY without going back to IDLE.

Not supported: error response, protection control, locked transfers, INCR4/8/16 and wrapping bursts, multi-layer AHB-Lite, and bus widths larger than 32 bits.

### 2. Master Interface

Besides the standard AHB-Lite signals, extra ports were added to act as the master side:

- **`HADDR_IN`**, **`HWRITE_IN`**, **`HSIZE_IN`**, **`HBURST_IN`**, **`HWDATA_IN`** – address, operation (1 write, 0 read), size, burst type and write data coming from the master side.
- **`START_TRANS_IN`** – starts a new transaction and must stay asserted for the whole transaction.
- **`END_TRANS_IN`** – ends the transaction, mainly used to end INCR bursts.
- **`BUSY_IN`** – makes the next HTRANS BUSY.

<img width="638" height="401" alt="interface" src="https://github.com/user-attachments/assets/9621347f-cce9-4969-bb3b-47fd9d32431a" />

### 3. FSM

The master is controlled by a four-state FSM:

- **`IDLE_S`** – default state after reset, HTRANS is IDLE. Moves to `ADDR_S` when `START_TRANS_IN` is asserted.
- **`ADDR_S`** – address phase, HTRANS is NONSEQ. Goes to `WRITE_DATA_S` or `READ_DATA_S` depending on `HWRITE`.
- **`WRITE_DATA_S`** – drives `HWDATA` and keeps everything stable while HREADY is low.
- **`READ_DATA_S`** – waits for HREADY and takes `HRDATA`.

In both data states the address is incremented by 2^HSIZE for INCR bursts, HTRANS stays SEQ until `END_TRANS_IN`, and the FSM returns to `IDLE_S` when it is asserted.

<img width="622" height="455" alt="fsm" src="https://github.com/user-attachments/assets/868f398f-466c-4c6d-b23e-fd5658e41c00" />


### 4. Verilog RTL Implementation

The design is a single module:

- **`ahb_master.v`** – the AHB-Lite master and its FSM
- **`ahb_master_tb.v`** – the testbench with the slave model

### 5. Testbench & Verification

To verify the master:

- A directed testbench was created.
- The slave is emulated with a simple 2KB memory that reads and writes when HREADY is high.
- Test scenarios included:
  * Single write and single read
  * Waited transfers
  * INCR burst write and read
  * Byte write and read
  * Halfword write and read

## Results

All test scenarios behaved as expected in simulation. Below are some of the waveforms:

- ✅ Passed: single write transfer

<img width="1143" height="621" alt="single_write" src="https://github.com/user-attachments/assets/8a4d7197-e3ec-4e29-8b43-78e97242a53f" />

- ✅ Passed: waited transfers

<img width="1143" height="651" alt="waited" src="https://github.com/user-attachments/assets/9a71785c-91c8-4339-b91e-0ea506cbb0b3" />

- ✅ Passed: INCR burst write, with the address incrementing by the transfer size

<img width="1149" height="657" alt="incr_write" src="https://github.com/user-attachments/assets/51574984-842c-4638-9618-c2b1dcdf97b0" />

- ✅ Passed: byte and halfword write and read

<img width="1056" height="1248" alt="byte_halfword" src="https://github.com/user-attachments/assets/a67b325f-40a0-431c-8f3b-3578ff5681b1" />

