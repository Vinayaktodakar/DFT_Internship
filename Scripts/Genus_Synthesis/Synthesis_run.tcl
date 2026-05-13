
# TCL Script Used

```tcl
read_hdl ../rtl/counter.v

read_libs /tech/libraries/RAK_LIBS/lib/max/slow.lib

elaborate

read_sdc ../sdc/Counter_sdc.sdc

syn_generic
syn_map
syn_opt

report_timing > ../reports/timing.rpt
report_area  > ../reports/area.rpt
report_power > ../reports/power.rpt

write_hdl > ../netlist/Netlist.v

history

exit
