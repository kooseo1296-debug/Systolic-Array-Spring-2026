# Systolic-Array-Spring-2026
Low-Power AI Accelerator with Operation-Skipping Logic and Logarithmic Number System

## Project Overview
This project aims to design and implement a highly power-efficient Systolic Array-based NPU in Verilog. The core objective is to minimize dynamic power consumption during the Matrix Multiplication operation by exploiting data sparsity.

## Motivation & Background
Modern AI/Deep Learning models exhibit high degrees of sparsity in their weights and activations. Traditional NPU architectures waste significant dynamic power by computing redundant operations (i.e., 0 * X = 0). This project addresses this redundancy by implementing a hardware-level zero-skipping mechanism to reduce unnecessary switching activities.

## Tech Stack
* Hardware Description Language: Verilog HDL
* Synthesis & Power Analysis: AMD Vivado

## System Specifications
| Parameter | Value | Description |
| :--- | :--- | :--- |
| **Clock Frequency** | 100 MHz | Target operating frequency for synthesis |
| **Systolic Array Size** | 8-by-8 | N-by-N spatial architecture dimension |
| **Data Width** | 8-bit | Bit width for input activation and weights; this also stands for Input/Weight SRAM's data width |
| **Accumulator Width** | 32-bit | Bit-width for MAC accumulation results; this also stands for Psum SRAM's data width |
| **BRAM depth** | 4096/1024 | Block RAM depth of Input/Weight SRAM(4096) and Psum SRAM(1024) |
| **Target Device** | Xilinx Zynq-7000 | Target FPGA part used in Vivado |

### Matrix Tiling Parameters
To efficiently map large AI workloads onto the hardware, the controller dynamically manages the loop bounds using the following tiling dimensions:

* **`IC` (Input Channel):** The depth of the input feature map or activation matrix.
* **`OC` (Output Channel):** The number of filters or the depth of the output feature map.
* **`S` (Spatial / Sequence Dimension):** The flattened spatial size (H x W) for vision workloads, or the sequence length for time-series/transformer workloads.

This parameterized approach ensures that the fixed-size `N x N` systolic array can execute matrix multiplications of arbitrary scales seamlessly.

## Control Logic & Instruction Execution Flow

The overall operation of the NPU is orchestrated by a central Finite State Machine (FSM) (`systolic_ctrl.v`). It operates as an instruction-driven controller, decoding 32-bit instructions to manage matrix tiling parameters, on-chip SRAM buffering, and the dual-phase execution of the Systolic Array.

### FSM States & Execution Phases
The controller execution flow is divided into four main states:
<img width="60%" alt="image" src="https://github.com/user-attachments/assets/e17b4ac5-d2db-4b31-a30f-45f54e1d8c39" />

1. **`IDLE` (State 00: Configuration & Writeback)**
   * **Parameter Configuration:** Decodes instructions to set architectural matrix tiling parameters (`SC`, `IC`, `OC`) and SRAM base addresses (`Offset`).
   * **Writeback:** Safely drains the accumulated partial sums (`Psum`) from the on-chip `PsumSRAM` to the external interface.
   
2. **`LDINPUT` & `LDWEIGHT` (State 01 & 10: SRAM Buffering)**
   * Fetches input activations and weight matrices from the instruction stream and buffers them into the dedicated on-chip **Input SRAM** and **Weight SRAM**. 
   * This structure decouples external memory bandwidth bottlenecks from the high-speed internal systolic computation.

3. **`RUN` (State 11: Dual-Phase Compute)**
   The core execution state is further divided into two sub-phases (`RunState` toggling) to establish a true Weight-Stationary dataflow:
   * **Phase 0 (Weight Load Mode):** Pauses input streaming and dynamically loads the weights from the `WeightSRAM` into the internal PE registers row-by-row.
   * **Phase 1 (Input Load & Compute):** * Streams input activations from the `InputSRAM` into the $N \times N$ array with appropriate valid-signal skewing.


## Hardware Architectures
### 1. Conventional
<p> <img width="70%" alt="image" src="https://github.com/user-attachments/assets/b9194636-8e2a-4dca-87e1-f2ad00fcc7bd" />
 <img width="25%" alt="image" src="https://github.com/user-attachments/assets/d4d7f7d3-4cda-476f-8777-058b8527476e" /> </p>

* **Boundary Masking:** The conventional Top-Level Architecture employs a `ZeroMask` module strictly for boundary handling. It forces out-of-bound input data to zero when the matrix dimension does not perfectly align with the array size (e.g., masking the 8th row if `IC = 7`).
* **Redundant Computation:** Consequently, the conventional PE indiscriminately executes MAC operations regardless of the actual input values. Continuously computing $0 \times W$ forces the internal combinational logic and flip-flops to toggle, resulting in a massive waste of dynamic power.

### 2. Zero-Skip Applied
<img width="70%" alt="image" src="https://github.com/user-attachments/assets/5e10781b-46e0-4129-a96a-254f78d0fcdb" /> <img width="50%" alt="image" src="https://github.com/user-attachments/assets/ed0af0dc-c1ee-4959-95a5-28d3509b69fe" />

To resolve the severe power inefficiency of the conventional design, we propose a Zero-Skipping architecture equipped with hardware-level sparsity detection and operand isolation.

* **Top-Level Pre-Detection:** A dedicated `Zero Detect [7:0]` module is integrated before the systolic array. It evaluates the incoming activations and generates a `ZeroFlag` for each row in advance. This centralized detection eliminates the need for redundant, power-hungry comparators inside every single PE.
* **Operand Isolation (Data Gating):** Inside the PE, the `Do_Compute` signal controls the input registers (FFs). If a zero input is flagged (`ZeroFlag_In == 1`), invalid data is detected (`Valid_P_In == 0`), or the weight is zero (`W == 0`), the registers are disabled. This completely freezes the MAC datapath, preventing any unnecessary toggling.
* **Datapath Bypassing:** When the computation is skipped, a `2-to-1 MUX` actively bypasses the MAC unit, forwarding the previous partial sum (`PSUM_In`) directly to the output (`PSUM_Out`).

## Future Work & To-Do List

This project is actively being developed to achieve a complete End-to-End AI inference demonstration.

- [ ] **RTL Controller Upgrade for Scalability:** - Expand internal parameter registers (e.g., `IC`, `Offset`) from 8-bit to 16-bit to support large-scale matrix dimensions (e.g., $IC = 784$ for flattened images).
  - Implement decoding logic for `_WH` (upper-bit) instructions to handle parameters exceeding the 8-bit ISA limit.
- [ ] **HW/SW Co-Design Environment:** - Develop a Python-based testing framework for model training, 8-bit quantization, and testbench vector generation.
  - Implement host-side post-processing logic (Bias addition, ReLU activation, and Re-quantization) between neural network layers.
- [ ] **End-to-End MNIST Inference:** - Successfully map and execute a Multi-Layer Perceptron (MLP) on the Zero-Skipping NPU.
  - Verify the final inference accuracy through Vivado behavioral simulation.
- [ ] **Further Power Optimization (Optional):** - Explore advanced power reduction techniques, such as Clock Gating, to complement the current Data Gating mechanism.
