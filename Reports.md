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
<img width="50%" alt="image" src="https://github.com/user-attachments/assets/4214a20c-e473-471a-ad47-595598953707" />


### 2. Power Consumption (SAIF-based)
<img width="50%" alt="image" src="https://github.com/user-attachments/assets/2b392401-8223-42a2-9adc-41a32b9c8112" />

<img width="100%" alt="image" src="https://github.com/user-attachments/assets/203dd6ca-4bc1-41bd-a7a1-4b37cae25b5d" />


**Description:**
This SAIF-based power report represents the baseline power consumption of the default systolic array architecture **without** the operation-skip feature. 

**Key Observations from the Baseline:**
* **Total On-Chip Power:** Estimated at **0.240 W**, with dynamic power dominating the operational cost (**0.130 W**).
* **Module-Level Breakdown:** As shown in the hierarchical view, the core `systolic` array module is responsible for **0.056 W** of the dynamic power. 

This baseline measurement serves as the reference point to validate the efficiency of the proposed Zero-Skipping architecture, which aims to drastically reduce the dynamic power consumed by the `systolic` module during sparse matrix multiplications.

### 3. Timing Report
<img width="70%" alt="image" src="https://github.com/user-attachments/assets/6b335be1-f782-483f-80d5-508be7684de1" />

**Description:**
This timing summary confirms that the baseline architecture successfully meets all timing constraints at the target clock frequency. 

**Key Metrics:**
* **Worst Negative Slack (WNS):** **+1.196 ns**
* **Worst Hold Slack (WHS):** **+0.111 ns**
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
