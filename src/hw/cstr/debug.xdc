create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list adc_inst/adc0_fco_pll/inst/clk_out1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 32 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {ps_pl/trig2beam_dly[0]} {ps_pl/trig2beam_dly[1]} {ps_pl/trig2beam_dly[2]} {ps_pl/trig2beam_dly[3]} {ps_pl/trig2beam_dly[4]} {ps_pl/trig2beam_dly[5]} {ps_pl/trig2beam_dly[6]} {ps_pl/trig2beam_dly[7]} {ps_pl/trig2beam_dly[8]} {ps_pl/trig2beam_dly[9]} {ps_pl/trig2beam_dly[10]} {ps_pl/trig2beam_dly[11]} {ps_pl/trig2beam_dly[12]} {ps_pl/trig2beam_dly[13]} {ps_pl/trig2beam_dly[14]} {ps_pl/trig2beam_dly[15]} {ps_pl/trig2beam_dly[16]} {ps_pl/trig2beam_dly[17]} {ps_pl/trig2beam_dly[18]} {ps_pl/trig2beam_dly[19]} {ps_pl/trig2beam_dly[20]} {ps_pl/trig2beam_dly[21]} {ps_pl/trig2beam_dly[22]} {ps_pl/trig2beam_dly[23]} {ps_pl/trig2beam_dly[24]} {ps_pl/trig2beam_dly[25]} {ps_pl/trig2beam_dly[26]} {ps_pl/trig2beam_dly[27]} {ps_pl/trig2beam_dly[28]} {ps_pl/trig2beam_dly[29]} {ps_pl/trig2beam_dly[30]} {ps_pl/trig2beam_dly[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 16 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {ps_pl/trig2beam_thresh[0]} {ps_pl/trig2beam_thresh[1]} {ps_pl/trig2beam_thresh[2]} {ps_pl/trig2beam_thresh[3]} {ps_pl/trig2beam_thresh[4]} {ps_pl/trig2beam_thresh[5]} {ps_pl/trig2beam_thresh[6]} {ps_pl/trig2beam_thresh[7]} {ps_pl/trig2beam_thresh[8]} {ps_pl/trig2beam_thresh[9]} {ps_pl/trig2beam_thresh[10]} {ps_pl/trig2beam_thresh[11]} {ps_pl/trig2beam_thresh[12]} {ps_pl/trig2beam_thresh[13]} {ps_pl/trig2beam_thresh[14]} {ps_pl/trig2beam_thresh[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 32 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {find_beam/count_reg[0]} {find_beam/count_reg[1]} {find_beam/count_reg[2]} {find_beam/count_reg[3]} {find_beam/count_reg[4]} {find_beam/count_reg[5]} {find_beam/count_reg[6]} {find_beam/count_reg[7]} {find_beam/count_reg[8]} {find_beam/count_reg[9]} {find_beam/count_reg[10]} {find_beam/count_reg[11]} {find_beam/count_reg[12]} {find_beam/count_reg[13]} {find_beam/count_reg[14]} {find_beam/count_reg[15]} {find_beam/count_reg[16]} {find_beam/count_reg[17]} {find_beam/count_reg[18]} {find_beam/count_reg[19]} {find_beam/count_reg[20]} {find_beam/count_reg[21]} {find_beam/count_reg[22]} {find_beam/count_reg[23]} {find_beam/count_reg[24]} {find_beam/count_reg[25]} {find_beam/count_reg[26]} {find_beam/count_reg[27]} {find_beam/count_reg[28]} {find_beam/count_reg[29]} {find_beam/count_reg[30]} {find_beam/count_reg[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 32 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {find_beam/clock_count[0]} {find_beam/clock_count[1]} {find_beam/clock_count[2]} {find_beam/clock_count[3]} {find_beam/clock_count[4]} {find_beam/clock_count[5]} {find_beam/clock_count[6]} {find_beam/clock_count[7]} {find_beam/clock_count[8]} {find_beam/clock_count[9]} {find_beam/clock_count[10]} {find_beam/clock_count[11]} {find_beam/clock_count[12]} {find_beam/clock_count[13]} {find_beam/clock_count[14]} {find_beam/clock_count[15]} {find_beam/clock_count[16]} {find_beam/clock_count[17]} {find_beam/clock_count[18]} {find_beam/clock_count[19]} {find_beam/clock_count[20]} {find_beam/clock_count[21]} {find_beam/clock_count[22]} {find_beam/clock_count[23]} {find_beam/clock_count[24]} {find_beam/clock_count[25]} {find_beam/clock_count[26]} {find_beam/clock_count[27]} {find_beam/clock_count[28]} {find_beam/clock_count[29]} {find_beam/clock_count[30]} {find_beam/clock_count[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 16 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {find_beam/threshold[0]} {find_beam/threshold[1]} {find_beam/threshold[2]} {find_beam/threshold[3]} {find_beam/threshold[4]} {find_beam/threshold[5]} {find_beam/threshold[6]} {find_beam/threshold[7]} {find_beam/threshold[8]} {find_beam/threshold[9]} {find_beam/threshold[10]} {find_beam/threshold[11]} {find_beam/threshold[12]} {find_beam/threshold[13]} {find_beam/threshold[14]} {find_beam/threshold[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 16 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {find_beam/adc_data[2][0]} {find_beam/adc_data[2][1]} {find_beam/adc_data[2][2]} {find_beam/adc_data[2][3]} {find_beam/adc_data[2][4]} {find_beam/adc_data[2][5]} {find_beam/adc_data[2][6]} {find_beam/adc_data[2][7]} {find_beam/adc_data[2][8]} {find_beam/adc_data[2][9]} {find_beam/adc_data[2][10]} {find_beam/adc_data[2][11]} {find_beam/adc_data[2][12]} {find_beam/adc_data[2][13]} {find_beam/adc_data[2][14]} {find_beam/adc_data[2][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 16 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {find_beam/adc_data[0][0]} {find_beam/adc_data[0][1]} {find_beam/adc_data[0][2]} {find_beam/adc_data[0][3]} {find_beam/adc_data[0][4]} {find_beam/adc_data[0][5]} {find_beam/adc_data[0][6]} {find_beam/adc_data[0][7]} {find_beam/adc_data[0][8]} {find_beam/adc_data[0][9]} {find_beam/adc_data[0][10]} {find_beam/adc_data[0][11]} {find_beam/adc_data[0][12]} {find_beam/adc_data[0][13]} {find_beam/adc_data[0][14]} {find_beam/adc_data[0][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 16 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {find_beam/adc_data[1][0]} {find_beam/adc_data[1][1]} {find_beam/adc_data[1][2]} {find_beam/adc_data[1][3]} {find_beam/adc_data[1][4]} {find_beam/adc_data[1][5]} {find_beam/adc_data[1][6]} {find_beam/adc_data[1][7]} {find_beam/adc_data[1][8]} {find_beam/adc_data[1][9]} {find_beam/adc_data[1][10]} {find_beam/adc_data[1][11]} {find_beam/adc_data[1][12]} {find_beam/adc_data[1][13]} {find_beam/adc_data[1][14]} {find_beam/adc_data[1][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 16 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {find_beam/adc_data[3][0]} {find_beam/adc_data[3][1]} {find_beam/adc_data[3][2]} {find_beam/adc_data[3][3]} {find_beam/adc_data[3][4]} {find_beam/adc_data[3][5]} {find_beam/adc_data[3][6]} {find_beam/adc_data[3][7]} {find_beam/adc_data[3][8]} {find_beam/adc_data[3][9]} {find_beam/adc_data[3][10]} {find_beam/adc_data[3][11]} {find_beam/adc_data[3][12]} {find_beam/adc_data[3][13]} {find_beam/adc_data[3][14]} {find_beam/adc_data[3][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list find_beam/threshold_hit]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list find_beam/counting]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list find_beam/done]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list find_beam/trig_sync_d]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets adc_clk]
