# Simple ALU PnR lab: Nangate45 + Fusion Compiler

Only `ALU_TOP`, with **SS / TT / FF** cell timing corners. The scripts use direct
commands and a few ordinary Tcl variables: no configuration framework or namespaces.
Copy this whole folder to Linux; all paths are relative to this folder.

## Run these three steps

From **inside this folder**, with your Synopsys tools on `PATH`:

```bash
lc_shell -f build_libs.tcl
dc_shell -f synth.tcl
fc_shell -f run_all.tcl
```

1. **Library Compiler, once:** build all three `.db` files from the supplied
   matching Liberty files. Rebuild TT too; do not substitute the old TT binary.
2. **DC:** re-synthesize the copied RTL using Nangate45 SS cells. The old lab's
   TSMC-mapped netlist cannot be used with Nangate45.
3. **FC:** run the PnR stages. You can also launch `fc_shell -gui` and source the
   lines in `run_all.tcl` one at a time; this is the easiest way to study the lab.

If the tools are not on `PATH`, their previously supplied installation paths are:

```text
/home/hwang/EDA/synopsys/tools/lc/X-2025.06/bin/lc_shell
/home/hwang/EDA/synopsys/tools/syn/X-2025.06-SP4/bin/dc_shell
/home/hwang/EDA/synopsys/tools/fusioncompiler/X-2025.06/bin/fc_shell
```

## What to read, in order

| Script | What it does |
| --- | --- |
| `constraints.tcl` | Clock, input/output delays, input driver, output load |
| `des_import.tcl` | Read the mapped netlist and physical/timing libraries |
| `MMMC.tcl` | Set up SS, TT, FF and the wire RC data |
| `floorplan.tcl` | Create the core and place boundary pins |
| `power_plan.tcl` | Create VDD/VSS ring, stripes and cell-row rails |
| `placement.tcl` | Place/optimize cells and insert constant drivers |
| `cts.tcl` | Build and optimize the clock tree |
| `routing.tcl` | Route signals and optimize |
| `chip_finish.tcl` | Add row fillers and check the physical result |
| `outputs_gen.tcl` | Save netlists/DEF/SPEF/SDC/SDF and timing reports |

Each stage saves a named checkpoint in `work/ALU_TOP.dlib`. Reports go to
`reports/`, exports to `outputs/`. Inspect errors and violations; script completion
does not mean timing or routing is clean. For a fresh rerun, close FC and rename
the old `work` folder first. Reports/exports use fixed names and are overwritten
on another run, so rename those folders too if you want to preserve them.

## The three timing corners

| Scenario | Liberty corner | Voltage | Temperature |
| --- | --- | --- | --- |
| `FUNC_SS` | slow / SlowSlow | 0.95 V | 125 C |
| `FUNC_TT` | typical / TypTyp | 1.10 V | 25 C |
| `FUNC_FF` | fast / FastFast | 1.25 V | 0 C |

All three are active for setup and hold. These values come from the actual library
headers; all three specify process number 1. The kit supplies **one TLU+ file**,
reused for early/late RC in all scenarios. This models three cell corners, without
claiming separate best/worst interconnect corners.

The copied physical/RC files live in `std_cells/`. All three Liberty files come from the
[mflowgen FreePDK45 kit's initial release](https://github.com/mflowgen/freepdk-45nm/tree/ef96dca4a64106eb033572552fc48b4bcac37334),
before its later well-tap changes. This avoids a mismatch in the downloaded TT
Liberty: its tie outputs are named `Y`, while the LEF uses `Z`. The matched set
uses `Z`. FF/SS library identifiers were made unique so all three can coexist;
their cell names and timing tables are unchanged. All 134 cells were checked
across corners and against LEF signal pins/areas. See `std_cells/SOURCES.md`.

## Deliberate simplifications

- The copied top connects `CLK`/`RST` directly and removes scan ports/muxes.
  The four ALU units and decoder are unchanged. Original lab files are untouched.
- The clock remains **100 ns**, with the lab's **20 ns I/O delays**. Reset release
  is also modeled as a timed input; review that assumption for a real design.
- Output load is **10 fF**, a stated learning assumption replacing the original
  75 pF. Nangate uses fF; FC is explicitly set to fF to match DC.
- Core size comes from cell area at 60% utilization. CTS uses tool defaults.
  There are no ECO branches, custom clock routing rules, or report helper functions.
- Basic power connectivity, route checks, tie cells, fillers and RC data remain:
  removing these would hide important parts of the PnR flow.
- GDS export (`outputs/ALU_TOP_pnr.gds`) includes routed geometry and LEF-derived cell frames, using technology layer numbers. It is a demonstration layout, not a complete fabrication layout: this kit has no full standard-cell GDS. GLS remains omitted because this kit has no simulation models.
  SDF is still exported. Foundry signoff/IR/EM and an I/O pad ring are outside this lab.

Local checks passed: all 13 Tcl files parse, the LC/DC/FC script sequence runs
with explicit mock tool commands, all three scenarios produce the intended
report/export calls, and the copied ALU connections are preserved. These are
script checks, not synthesis or physical implementation. Library Compiler, DC
and FC must still be run on your Linux installation. The
SS/TT/FF binaries and Nangate-mapped ALU netlist are generated by the first two steps;
they are not pre-generated here.
