# Library provenance

Physical and RC files were copied unchanged from your workspace's `NanGate45`
directory, which contains the
[ABKGroup Synopsys enablement](https://github.com/ABKGroup/NanGate45-Synopsys-Enablement).
`SOURCE_README.md` is the downloaded directory's original README, retained unchanged.
The `.tf`, cell LEF, TLU+ and layer map are the only physical/RC inputs read by
this flow. Cadence QRC/captable files, fake RAMs and unused extraction formats
were not copied.

## Consistent timing views

Source repository: [mflowgen/freepdk-45nm](https://github.com/mflowgen/freepdk-45nm).
Pinned commit: `ef96dca4a64106eb033572552fc48b4bcac37334` (initial release).

| Local file | Upstream file | Local modification |
| --- | --- | --- |
| `NangateOpenCellLibrary_typical.lib` | [stdcells.lib](https://github.com/mflowgen/freepdk-45nm/blob/ef96dca4a64106eb033572552fc48b4bcac37334/stdcells.lib) | None |
| `NangateOpenCellLibrary_fast.lib` | [stdcells-bc.lib](https://github.com/mflowgen/freepdk-45nm/blob/ef96dca4a64106eb033572552fc48b4bcac37334/stdcells-bc.lib) | Library identifier changed to `NangateOpenCellLibrary_fast` |
| `NangateOpenCellLibrary_slow.lib` | [stdcells-wc.lib](https://github.com/mflowgen/freepdk-45nm/blob/ef96dca4a64106eb033572552fc48b4bcac37334/stdcells-wc.lib) | Library identifier changed to `NangateOpenCellLibrary_slow` |

Why TT was replaced: your downloaded typical Liberty names the `LOGIC0_X1` and
`LOGIC1_X1` output `Y`, whereas the downloaded LEF calls it `Z`. The upstream
TT/FF/SS set consistently uses `Z`. The downloaded TT binary was not retained:
rebuilding all three removes uncertainty about which source its binary used.
No timing tables were modified or fabricated. Existing copyright notices remain.

Validation: all 134 cells in each Liberty have identical names, external signal
pin sets and areas across TT/FF/SS. Each matches the corresponding downloaded
LEF macro's signal pins and area. The LEF also contains a physical-only
`TAPCELL_X1` macro absent from this Liberty set; this lab does not insert it.
These structural checks do not replace FC library preparation/checks or signoff.

## SHA-256 of the supplied files

```text
d67a510fcd040b53b3a9819ef883b0ec07527fedcebe6b0c2f405d12196771eb  NangateOpenCellLibrary.layermap
ae48ca01bc12b9f0c44717b7275ba8884f1760bf562f5a42e3ca39906ddc9e54  NangateOpenCellLibrary.macro.mod.lef
baff37f0835a1db60f2c3a3890715236e310bcc16ff4ff94b550518d8cb80702  NangateOpenCellLibrary.tf
f1d3f53e18b8138ea45c6df6424c9f547c1f021e931f13b75adee11841d677bf  NangateOpenCellLibrary.tlup
7c08823aa809fb8c1d633b7f985c3f8a56c1f06e4d3a05b00c487e9e4b4805b7  NangateOpenCellLibrary_fast.lib
899e4a91977dde6aaca8e99073ae7a02fa546510bb4a393e6bab4a8ee2f98b16  NangateOpenCellLibrary_slow.lib
2efd0b32eb580e4e60e72fc0575bb3bc69aac907c91d908442e4ae6d7fe55895  NangateOpenCellLibrary_typical.lib
```

Original upstream FF SHA-256 before renaming the library identifier:
`31a231d64224b86d60e88c572e280f12e5d26361115e0b22bfc7e744fe8349ac`.
Original upstream SS SHA-256 before renaming the library identifier:
`372787d4970a6bde9fcd26e5499920c289ac5c7c780e21c3d518a64c002008be`.
