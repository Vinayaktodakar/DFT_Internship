# Command Explanations

## 1. ```read_hdl <file_name_and_path>```

### ***Purpose***

Reads the Verilog/SystemVerilog RTL design into Cadence Genus.

### ***What Happens***

- Imports the HDL source code.
- Checks syntax correctness.
- Creates an internal representation of the RTL design.

### ***Input***

- Verilog RTL file (`counter.v`)

### ***Output***

- RTL design loaded into memory.

---

## 2. ```read_libs <library_path>```

### ***Purpose***

Loads the standard cell technology library into Cadence Genus.

### ***What Happens***

- Reads timing information of standard cells.
- Reads area and power information.
- Makes synthesis aware of available hardware gates.

### ***Input***

- Technology library file (`slow.lib`)

### ***Output***

- Standard cell database loaded into memory.

---

## 3. ```elaborate```

### ***Purpose***

Builds the complete RTL design hierarchy.

### ***What Happens***

- Resolves module connections.
- Expands hierarchy.
- Checks unresolved references.
- Creates RTL netlist representation.

### ***Input***

- Loaded RTL design files.

### ***Output***

- Elaborated design database.

---

## 4. ```read_sdc <sdc_file_path>```

### ***Purpose***

Reads Synopsys Design Constraint (SDC) file.

### ***What Happens***

- Applies clock constraints.
- Applies input/output delays.
- Defines timing requirements.

### ***Input***

- SDC constraint file (`Counter_sdc.sdc`)

### ***Output***

- Timing constraints loaded into design.

---

## 5. ```syn_generic```

### ***Purpose***

Performs generic synthesis optimization.

### ***What Happens***

- Converts RTL into generic Boolean logic.
- Removes redundant logic.
- Optimizes logic structure.

### ***Input***

- Elaborated RTL design.

### ***Output***

- Technology-independent optimized netlist.

---

## 6. ```syn_map```

### ***Purpose***

Maps generic logic into standard cells.

### ***What Happens***

- Replaces generic gates with real library cells.
- Uses cells available in `.lib` file.
- Creates gate-level mapped design.

### ***Input***

- Generic synthesized netlist.

### ***Output***

- Gate-level mapped netlist.

---

## 7. ```syn_opt```

### ***Purpose***

Optimizes mapped design for timing, area, and power.

### ***What Happens***

- Fixes timing violations.
- Performs gate sizing.
- Inserts buffers if required.
- Improves overall QoR (Quality of Results).

### ***Input***

- Mapped gate-level design.

### ***Output***

- Optimized gate-level netlist.

---

## 8. ```report_timing```

### ***Purpose***

Generates timing analysis report.

### ***What Happens***

- Calculates setup timing.
- Calculates hold timing.
- Finds critical timing paths.
- Reports slack values.

### ***Input***

- Optimized synthesized design.

### ***Output***

- Timing report (`timing.rpt`)

---

## 9. ```report_area```

### ***Purpose***

Generates area utilization report.

### ***What Happens***

- Calculates total cell area.
- Reports standard cell usage.

### ***Input***

- Synthesized gate-level netlist.

### ***Output***

- Area report (`area.rpt`)

---

## 10. ```report_power```

### ***Purpose***

Generates power consumption report.

### ***What Happens***

- Calculates dynamic power.
- Calculates leakage power.
- Calculates internal power.

### ***Input***

- Optimized synthesized design.

### ***Output***

- Power report (`power.rpt`)

---

## 11. ```write_hdl```

### ***Purpose***

Writes synthesized gate-level Verilog netlist.

### ***What Happens***

- Exports mapped design into Verilog format.
- Converts RTL logic into gate-level representation.

### ***Input***

- Optimized synthesized design.

### ***Output***

- Gate-level netlist (`Netlist.v`)

---

## 12. ```history```

### ***Purpose***

Displays previously executed commands.

### ***What Happens***

- Shows command history of current Genus session.

### ***Input***

- Current tool session.

### ***Output***

- List of executed commands.

---

## 13. ```exit```

### ***Purpose***

Closes Cadence Genus session.

### ***What Happens***

- Safely terminates synthesis session.

### ***Input***

- Current running session.

### ***Output***

- Exits Genus tool.

## 14. ```set_dont_use SDFF*```

### ***Purpose***

Prevents Cadence Genus from using specific library cells (here, all cells starting with `SDFF`) during synthesis.

---

### ***What Happens***

- The tool excludes all standard cells matching the pattern `SDFF*`.
- These cells will not be considered during mapping or optimization.
- Forces Genus to choose alternative flip-flop cells from the library.

---

### ***Why It Is Used***

- To avoid using slow, high-power, or non-preferred flip-flop cells.
- To enforce usage of specific timing-optimized or low-power FFs.
- To control technology mapping strategy.
- Useful when certain cells are:
  - Not timing-closed
  - Not supported in target flow
  - Restricted by design guidelines

---

### ***Input***

- Cell name pattern: `SDFF*`
  (matches all flip-flops like SDFFQX1, SDFFRX2, etc.)

---

### ***Output***

- These cells are removed from synthesis mapping options.
- Netlist will be built without `SDFF*` cells.

---

### ***Example***

If library contains:

```text
SDFFQX1
SDFFRX2
DFFX1
```

After command:

```tcl
set_dont_use SDFF*
```

Genus will only use:

```text
DFFX1
```

and ignore all `SDFF*` cells.

---

### ***Impact on Design***

- May change timing results (setup/hold).
- May increase or decrease area/power depending on alternatives.
- Gives designer control over final mapped architecture.
