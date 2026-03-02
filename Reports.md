# Hardware Implementation & Synthesis Reports

This document provides detailed post-synthesis and implementation results for the hardware design projects included in this repository. 

To objectively demonstrate the performance and efficiency of each architecture, the following three core reports, generated via Xilinx Vivado, are attached for each project:
1. **Hardware Utilization:** Resource costs including LUTs, FFs, DSPs, and BRAMs.
2. **Power Consumption:** Highly accurate, **SAIF (Switching Activity Interchange Format)** based power analysis reflecting actual switching activities during inference - the RUN state. The description includes the indication of the specific testbench file.
3. **Timing Report:** Verification of setup/hold time violations at the target clock frequency.
4. **Inference Results & Verification:** To validate the reliability and functional correctness of the designed NPU, a large-scale inference test was conducted using 9,999 images from the MNIST test dataset. The verification process focused on ensuring that the hardware logic maintains bit-level consistency even after implementing area and power optimizations.


---

##  Project 0: Default NPU Architecture

This project features a custom Processing Element (PE) and controller architecture designed to exploit input data sparsity. It inherently blocks unnecessary MAC (Multiply-Accumulate) operations and flip-flop toggling when zero-valued input data is detected.

### 1. Hardware Utilization
<img width="678" height="544" alt="image" src="https://github.com/user-attachments/assets/c33ac844-baee-4c6c-adf7-93e367fe3f2b" />


### 2. Power Consumption (SAIF-based)
<img width="810" height="490" alt="image" src="https://github.com/user-attachments/assets/6a125ef9-7c32-4ec8-869e-bd9dfd693727" />
<img width="814" height="136" alt="image" src="https://github.com/user-attachments/assets/2f7e79be-5bf9-46e3-b3e1-2074a3baa4f0" />

**Description:**
This SAIF-based power report represents the baseline power consumption of the default systolic array architecture **without** the operation-skip feature. 

**Key Observations from the Baseline:**
* **Total On-Chip Power:** Estimated at **0.233 W**, with dynamic power dominating the operational cost (**0.126 W**).
* **Module-Level Breakdown:** As shown in the hierarchical view, the core `systolic` array module is responsible for **0.054 W** of the dynamic power. 

This baseline measurement serves as the reference point to validate the efficiency of the proposed Zero-Skipping architecture, which aims to drastically reduce the dynamic power consumed by the `systolic` module during sparse matrix multiplications.

### 3. Timing Report
<img width="1043" height="268" alt="image" src="https://github.com/user-attachments/assets/b3e32c0a-a780-4046-866b-320fb68145c4" />

**Description:**
This timing summary confirms that the baseline architecture successfully meets all timing constraints at the target clock frequency. 

**Key Metrics:**
* **Worst Negative Slack (WNS):** **+1.318 ns**
* **Worst Hold Slack (WHS):** **+0.119 ns**
* **Result:** All user-specified timing constraints are met.

* The positive setup and hold slacks guarantee that there are no timing violations across the critical paths, ensuring the physical stability and reliability of the hardware design before applying any power-saving modifications.

### 4. Inference Results & Verification

**Quantitative Performance**
* **Total Test Samples:** 9999
* **Correct Predictions:** 8872
* **Inference Accuracy:** 88.73%

---

##  Project 1: Zero-Skip Applied NPU Architecture

---

## Project 2: (To be added)
*(Future projects with advanced architectures will be documented here following the same format.)*
