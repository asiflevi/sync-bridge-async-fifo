# Sync Bridge with Asynchronous FIFO (SystemVerilog)

This repository contains a SystemVerilog implementation of a
clock-domain crossing (CDC) synchronization bridge using an
asynchronous FIFO.

## Features
- Asynchronous FIFO
- Gray-coded read and write pointers
- Multi-flop synchronizers
- Request extension logic
- Independent read/write clock domains
- Multiple verification testbenches

## Files
### RTL
- async_fifo.sv
- sync_bridge.sv
- wr_ptr_gray.sv
- rd_ptr_gray.sv
- bin2gray.sv
- gray2bin.sv
- dff_sync.sv
- req_extension.sv

### Testbenches
- sync_bridge_tb.sv
- tb_async_fifo_simple.sv
- tb_gray_conv.sv
- tb_ptr_simple.sv

## Verification
The design was verified using multiple dedicated testbenches:
- Unit-level testing for Gray conversion
- Pointer logic testing
- Full asynchronous FIFO testing
- End-to-end sync bridge verification

Simulation performed using ModelSim / QuestaSim.

## Author
Asif Levi  
Electrical Engineering — Hebrew University of Jerusalem
