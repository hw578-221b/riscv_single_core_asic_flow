# Run ONCE in Library Compiler, from this folder:
# lc_shell -f build_libs.tcl
# Build all three .db files from the consistent, supplied Liberty set.
# Rebuilding TT also avoids the downloaded kit's tie-cell pin-name mismatch.

read_lib std_cells/NangateOpenCellLibrary_typical.lib
write_lib NangateOpenCellLibrary -format db \
    -output std_cells/NangateOpenCellLibrary_typical.db

read_lib std_cells/NangateOpenCellLibrary_fast.lib
write_lib NangateOpenCellLibrary_fast -format db \
    -output std_cells/NangateOpenCellLibrary_fast.db

read_lib std_cells/NangateOpenCellLibrary_slow.lib
write_lib NangateOpenCellLibrary_slow -format db \
    -output std_cells/NangateOpenCellLibrary_slow.db

exit
