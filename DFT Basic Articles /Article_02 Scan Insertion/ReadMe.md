# Scan Insertion — DFT Basics: Article #2

> **Series:** DFT (Design for Testability) Basics  
> **Topic:** Scan Insertion — converting flip-flops into scan flops and stitching them into scan chains  
> **Original article by:** [Vidisha's Substack](https://rvidisharoopchand.substack.com/p/scan-insertion)

---

## Table of Contents

1. [Background and Context](#1-background-and-context)
2. [What is Scan Insertion?](#2-what-is-scan-insertion)
   - [Normal Flop vs Scan Flop](#normal-flop-vs-scan-flop)
   - [Scan Chain](#scan-chain)
3. [Scan Chain Operation — Three Phases](#3-scan-chain-operation--three-phases)
   - [Phase 1: Scan-In (Shift-In)](#phase-1-scan-in-shift-in)
   - [Phase 2: Scan-Capture](#phase-2-scan-capture)
   - [Phase 3: Scan-Out (Measure SO)](#phase-3-scan-out-measure-so)
4. [Worked Example — Step-by-Step](#4-worked-example--step-by-step)
   - [Setup](#setup)
   - [First Shift Phase — Loading P1 (011)](#first-shift-phase--loading-p1-011)
   - [Capture Phase — P1 Captured](#capture-phase--p1-captured)
   - [Second Shift Phase — Shifting Out P1 Response & Loading P2 (101)](#second-shift-phase--shifting-out-p1-response--loading-p2-101)
   - [Summary Table](#summary-table)
5. [Significance of the Measure-SO Phase](#5-significance-of-the-measure-so-phase)
6. [Defect Detection — Full Illustration](#6-defect-detection--full-illustration)
7. [ATPG and ATE — The Bigger Picture](#7-atpg-and-ate--the-bigger-picture)
8. [Diagnostics After Failure](#8-diagnostics-after-failure)
9. [Key Takeaways](#9-key-takeaways)
10. [Quick Reference — Terminology](#10-quick-reference--terminology)

---

## 1. Background and Context

In modern VLSI design, **ensuring chip quality after manufacturing** is as important as designing the chip itself. No matter how carefully a chip is designed, the manufacturing process can introduce physical defects — broken wires, shorts between signals, transistors stuck at a fixed logic value, etc.

**Design for Testability (DFT)** is a set of techniques applied during the design phase so that the manufactured chip can be efficiently tested. Without DFT, the internal state of millions of flip-flops deep inside a chip would be completely inaccessible from the outside pins — making it practically impossible to locate defects.

**Scan Insertion** is the most fundamental and widely used DFT technique. It gives test engineers a "back door" into every flip-flop in the design.

---

## 2. What is Scan Insertion?

> **Scan Insertion** is the process of replacing all regular flip-flops in a design with **scan flip-flops (scan flops)**, and then connecting those scan flops end-to-end to form one or more **scan chains**.

A scan chain essentially turns a large collection of independent flip-flops into a giant **shift register** that can be controlled and observed from the chip's external pins.

---

### Normal Flop vs Scan Flop

| Feature | Normal Flip-Flop | Scan Flip-Flop |
|---|---|---|
| Data input | `D` (functional data) | `D` (functional) + `SI` (scan input) |
| Selection | Always captures functional data | `SE` (Scan Enable) selects between `D` and `SI` |
| Extra pins | None | `SI` (Scan In), `SE` (Scan Enable), `SO`/`Q` (Scan Out) |
| Behavior in normal mode | Captures functional data on clock edge | Same as normal flop |
| Behavior in scan mode | N/A | Captures value from previous flop's output (`SI`) |

The internal structure of a scan flop adds a **2:1 multiplexer** at the data input:

```
                  ┌──────────────────────────┐
Functional D ─────┤0                         │
                  │   MUX  ──► D  ┌──────┐   │
Scan Input SI ────┤1        (FF)  │  Q   ├───┼──► Scan Out / Q
                  │               └──────┘   │
Scan Enable SE ───┤sel                       │
                  └──────────────────────────┘
```

- When `SE = 0` (functional/mission mode): the flop captures normal functional data from `D`.  
- When `SE = 1` (scan/shift mode): the flop captures the serial scan data from `SI` (i.e., the `Q` output of the previous flop in the chain).

---

### Scan Chain

Once all flops are converted to scan flops, they are **stitched together serially**:

```
SI (Scan Input) ──► [Scan Flop F1] ──► [Scan Flop F2] ──► [Scan Flop F3] ──► SO (Scan Output)
                          │                   │                   │
                       (combo               (combo             (combo
                        logic)               logic)             logic)
```

- The `SO` (Scan Out) of F1 feeds the `SI` (Scan In) of F2, and so on.
- The chain has a single **scan input pin** at one end and a single **scan output pin** at the other.
- In a real chip with millions of flops, the EDA tool splits the flops into **multiple scan chains** (e.g., 100–2000 chains) to keep the shift time manageable.

---

## 3. Scan Chain Operation — Three Phases

Scan chain testing is performed in three distinct phases, repeated for every test pattern:

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│  PHASE 1    │────►│   PHASE 2    │────►│   PHASE 3    │
│  Scan-In    │     │   Capture    │     │   Scan-Out   │
│ (Shift-In)  │     │              │     │ (Measure SO) │
└─────────────┘     └──────────────┘     └──────────────┘
  N clock pulses      1 clock pulse        N clock pulses
  (N = # flops)                            (N = # flops)
```

> **Rule:** Number of clock pulses in shift phase = Number of flops in the scan chain  
> Number of clock pulses in capture phase = **1**

---

### Phase 1: Scan-In (Shift-In)

- `SE` (Scan Enable) is asserted HIGH → scan mode is active.
- The test pattern (input vector) is **serially shifted into** the scan chain, one bit per clock.
- Data flows: SI pin → F1 → F2 → F3 → ... → Fn → SO pin (like a shift register).
- After `N` clock pulses, every flop in the chain holds one bit of the test pattern.
- This sets up the **initial state** of all flip-flops for the test.

---

### Phase 2: Scan-Capture

- `SE` is de-asserted LOW → functional mode is active for exactly **one clock pulse**.
- The **combinational logic** between flip-flops is exercised: outputs of the combo logic are computed based on the values loaded in Phase 1.
- The result is **captured** (latched) into the flip-flops on the single capture clock edge.
- This is the actual **test stimulus applied to the combinational logic** — the heart of testing.

> The capture phase is critical: any manufacturing defect in the combinational logic will cause a wrong value to be captured here.

---

### Phase 3: Scan-Out (Measure SO)

- `SE` is asserted HIGH again → scan mode.
- The captured values are **serially shifted out** through the SO pin, one bit per clock.
- The ATE (Automatic Test Equipment) **compares** the shifted-out bits against the **expected output** (pre-computed by the ATPG tool during pattern generation).
- If actual output == expected output → **PASS** (no defect detected by this pattern).
- If actual output ≠ expected output → **FAIL** (chip has a manufacturing defect).

> Note: Phase 2 (capture) and Phase 3 (shift-out) are often **overlapped** — the shift-out of the current pattern's response happens simultaneously with the shift-in of the next pattern. This saves test time.

---

## 4. Worked Example — Step-by-Step

### Setup

Consider a scan chain with **3 flops**: F1, F2, F3 connected in series, with combinational logic between them.

```
SI ──► [F1] ──►(combo)──► [F2] ──►(combo)──► [F3] ──► SO
```

Two test patterns:
- **P1:** `011`  (loaded first)
- **P2:** `101`  (loaded second)

The bit order follows: first bit in = leftmost bit = goes deepest into the chain (ends up in F3 after all shifts).

---

### First Shift Phase — Loading P1 (011)

The 3-bit pattern `011` is shifted into the chain over 3 clock pulses:

| Clock Pulse | SI bit applied | F1 | F2 | F3 |
|---|---|---|---|---|
| Start (before shift) | — | X | X | X |
| Pulse 1 | 0 | 0 | X | X |
| Pulse 2 | 1 | 1 | 0 | X |
| Pulse 3 | 1 | 1 | 1 | 0 |

After 3 clock pulses: **F1=1, F2=1, F3=0** (P1 = `011` fully loaded).

> The first bit shifted in (0) travels all the way to F3. The last bit shifted in (1) stays in F1.

---

### Capture Phase — P1 Captured

- SE goes LOW, one clock pulse is applied.
- The combo logic processes the current values in F1, F2.
- The **output of combo logic driven by F1** is captured into F2.
- The **output of combo logic driven by F2** is captured into F3.
- F1 captures its own functional input (or retains, depending on design).

Suppose the combo logic result gives: F2 captures `0`, F3 captures `1`.

After capture: **F1=1, F2=0, F3=1** (the test response of P1 is now stored).

---

### Second Shift Phase — Shifting Out P1 Response & Loading P2 (101)

SE goes HIGH again. Now the **captured response of P1** shifts out while **P2 shifts in** simultaneously. This takes 3 clock pulses:

| Clock Pulse | SI bit (P2) | F1 | F2 | F3 | SO (bit shifted out) |
|---|---|---|---|---|---|
| Start | — | 1 | 0 | 1 | — |
| Pulse 1 | 1 | 1 | 1 | 0 | 1 (F3's old value) |
| Pulse 2 | 0 | 0 | 1 | 1 | 0 (F2's old value) |
| Pulse 3 | 1 | 1 | 0 | 1 | 1 (F1's old value) |

The 3 bits shifted out at SO = `1`, `0`, `1` → this is the **scan-out signature** for P1's response, compared against ATPG-expected output.

After the 3rd pulse, P2 (`101`) is fully loaded → ready for the next capture pulse.

---

### Summary Table

| Phase | SE | Clock Pulses | Action |
|---|---|---|---|
| Shift-In (P1) | HIGH | N (= 3) | Serial load of test pattern P1 |
| Capture (P1) | LOW | 1 | Combo logic exercised, response captured |
| Shift-Out (P1) + Shift-In (P2) | HIGH | N (= 3) | P1 response shifted out; P2 loaded simultaneously |
| Capture (P2) | LOW | 1 | Combo logic exercised with P2 |
| Shift-Out (P2) | HIGH | N (= 3) | P2 response shifted out and compared |

---

## 5. Significance of the Measure-SO Phase

The shift-out phase is where **defect detection actually happens**:

- The ATPG tool, during test pattern generation (pre-manufacturing), computes the **expected scan-out sequence** for a fault-free chip.
- This expected sequence is stored in the ATE.
- After manufacturing, the ATE applies the patterns to the physical chip and reads the SO.
- **Any mismatch** between actual SO and expected SO indicates that a manufacturing defect exists in the chip.

For the example in the article, the expected SO sequence is written as:

```
SO = X X X 0 1 X
```

where `X` means "don't care" (that bit position is not sensitized to any fault by this pattern, so its value is irrelevant for pass/fail).

---

## 6. Defect Detection — Full Illustration

Suppose a **manufacturing defect** is introduced in the combinational logic — for example, a wire stuck at logic `1` (stuck-at-1 fault) between the combo block and F2's input.

Without the defect: combo logic output → F2 captures `0` (correct).  
With the defect (stuck-at-1): F2 forcibly captures `1` (wrong).

When this wrong value propagates through subsequent shift-outs and reaches the SO pin, the ATE measures a bit that differs from the expected value:

```
Expected SO:  X X X 0 1 X
Actual SO:    X X X 1 1 X   ← bit position 4 is WRONG (0 → 1 mismatch)
```

Result: **ATE FAIL** → the chip is flagged as defective and rejected.

The failure log generated by the ATE contains:
- Which scan chain failed
- Which bit position(s) mismatched
- The cycle number of the failure

This log is used by the **diagnostics tool** to pinpoint the exact location of the defect (see Section 8).

---

## 7. ATPG and ATE — The Bigger Picture

Understanding where scan insertion fits in the overall chip lifecycle:

```
Design Phase (Pre-Manufacturing)
─────────────────────────────────────────────────
 RTL Design
     │
     ▼
 Synthesis (Logic Synthesis)
     │
     ▼
 Scan Insertion ◄──── DFT step: flops → scan flops, chains stitched
     │
     ▼
 ATPG (Automatic Test Pattern Generation)
     │   → Generates test patterns: {input sequence, expected output}
     │   → Patterns simulate defects (fault models: stuck-at, transition, etc.)
     ▼
 Place & Route → Tapeout → Fabrication

Manufacturing Phase
─────────────────────────────────────────────────
 Wafer fabrication
     │
     ▼
 Die singulation & packaging

Post-Manufacturing Test Phase
─────────────────────────────────────────────────
 ATE (Automatic Test Equipment)
     │   → Applies ATPG-generated input sequences to the chip
     │   → Reads scan-out from the chip
     │   → Compares actual output vs expected output
     ▼
 PASS → Chip ships to customer
 FAIL → Chip rejected (or sent to diagnostics)
```

Key distinction:
- **Scan Insertion + ATPG** happen **before manufacturing** (design/verification phase).
- **ATE testing** happens **after manufacturing** on every physical chip produced.

---

## 8. Diagnostics After Failure

When a chip fails on the ATE, the manufacturing defect needs to be located — this is important for:
- **Yield improvement**: understanding what defects are common helps fix the process.
- **Failure analysis**: physical inspection of the defect site.

The **diagnostics tool** takes three inputs:

```
 Verilog netlist (post-scan-insertion)
         +
 ATPG test patterns (the same patterns used on ATE)
         +
 ATE failure log (which pattern, which chain, which bit failed)
         │
         ▼
 Diagnostics Tool
         │
         ▼
 Candidate defect list: "Stuck-at-1 fault on net XYZ between instance U47/Z and U93/A"
```

This is possible because during ATPG, patterns are generated using **fault simulation** — the tool knows which faults each pattern is designed to detect and which scan-out bits they affect. Matching the failure log against this fault-simulation data narrows down the physical location of the defect.

> Fault simulation and fault models (stuck-at, transition delay, bridging, etc.) are covered in detail in the ATPG topic of this series.

---

## 9. Key Takeaways

- **Scan insertion** converts every flip-flop in the design into a scan flop and connects them in serial chains, making internal state fully controllable and observable from outside the chip.

- A **scan flop** differs from a normal flop by adding a multiplexer at its data input, controlled by a Scan Enable (`SE`) signal. When `SE=1`, it acts as a shift register stage.

- **Scan chain operation** has three phases:
  1. **Scan-In**: serial shift of test pattern into all flops (N clock pulses).
  2. **Capture**: single clock pulse — combo logic is exercised, response captured in flops.
  3. **Scan-Out**: serial shift of captured response out via SO pin, compared to expected.

- **Overlap of Scan-Out and next Scan-In** is used in practice to save test time.

- **ATPG** generates the test patterns pre-manufacturing; **ATE** applies them post-manufacturing.

- Any **mismatch** between actual scan-out and expected scan-out indicates a manufacturing defect → chip is rejected.

- The **ATE failure log**, combined with ATPG patterns and the netlist, enables the diagnostics tool to pinpoint the defect's physical location.

---

## 10. Quick Reference — Terminology

| Term | Full Form / Meaning |
|---|---|
| DFT | Design for Testability |
| Scan Flop | A flip-flop with an additional scan MUX input for shift-register operation |
| SI | Scan In — serial input to the scan chain |
| SO | Scan Out — serial output of the scan chain |
| SE | Scan Enable — selects scan mode (1) vs functional mode (0) |
| Scan Chain | Serial connection of scan flops forming a shift register |
| ATPG | Automatic Test Pattern Generation — EDA tool that creates test vectors |
| ATE | Automatic Test Equipment — hardware tester used post-manufacturing |
| Capture Pulse | The single functional clock used to exercise combo logic during scan test |
| Fault Simulation | Simulation with injected faults to determine which patterns detect which defects |
| Stuck-at Fault | A fault model where a net is permanently stuck at logic 0 or 1 |
| Test Coverage | Percentage of faults detectable by the generated test patterns |
| Scan Compression | Advanced DFT technique to reduce test time by compressing many chains |

---

> **Next in the series:** *Why is scan insertion necessary? — The need for scan insertion and how it enables easier testing.*

---

*Content based on: [Scan Insertion — Vidisha's Substack](https://rvidisharoopchand.substack.com/p/scan-insertion) with additional explanations.*
