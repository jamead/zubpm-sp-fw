################################################################################
# Main tcl for the module
################################################################################

# ==============================================================================
proc init {} {
  ::fwfwk::printCBM "In ./hw/src/main.tcl init()..."



}

# ==============================================================================
proc setSources {} {
  ::fwfwk::printCBM "In ./hw/src/main.tcl setSources()..."

  variable Sources 
  lappend Sources {"../hdl/top_tb.sv" "SystemVerilog"} 
  
  lappend Sources {"../hdl/top.vhd" "VHDL 2008"} 
  lappend Sources {"../hdl/ps_io.vhd" "VHDL 2008"} 
  lappend Sources {"../hdl/bpm_package.vhd" "VHDL 2008"} 
  lappend Sources {"../hdl/adc_ltc2195.vhd" "VHDL 2008"} 
  lappend Sources {"../hdl/adc_s2p.vhd" "VHDL 2008"} 
  lappend Sources {"../hdl/ltc2195_spi.vhd" "VHDL 2008"} 
  lappend Sources {"../hdl/spi_ad9510.vhd" "VHDL 2008"} 
  lappend Sources {"../hdl/spi_pe43712.vhd" "VHDL 2008"} 
  lappend Sources {"../hdl/adc2fifo.vhd" "VHDL 2008"} 
  lappend Sources {"../hdl/tbt2fifo.vhd" "VHDL 2008"}  
  lappend Sources {"../hdl/dsp_cntrl.vhd" "VHDL 2008"}    
  lappend Sources {"../hdl/trig_logic.vhd" "VHDL 2008"} 
  lappend Sources {"../hdl/stretch.vhd" "VHDL 2008"} 
  lappend Sources {"../hdl/sync_cdc.vhd" "VHDL 2008"}   
  lappend Sources {"../hdl/adc2dma.vhd" "VHDL 2008"} 
  lappend Sources {"../hdl/tbt2dma.vhd" "VHDL 2008"}    
  lappend Sources {"../hdl/fa2dma.vhd" "VHDL 2008"}   
  lappend Sources {"../hdl/ltc2986_spi.vhd" "VHDL 2008"}  
  lappend Sources {"../hdl/dsp/tbt_dsp.vhd" "VHDL 2008"}   
  lappend Sources {"../hdl/dsp/beam_sine_rom.vhd" "VHDL 2008"} 
  lappend Sources {"../hdl/dsp/beam_cos_rom.vhd" "VHDL 2008"}    
  lappend Sources {"../hdl/dsp/beam_ddc.vhd" "VHDL 2008"} 
  lappend Sources {"../hdl/dsp/fir_lp_ddc.vhd" "VHDL 2008"}
  lappend Sources {"../hdl/dsp/pos_calc.vhd" "VHDL 2008"}  
  lappend Sources {"../hdl/dsp/seqpolar.v" "Verilog"}      
    
  lappend Sources {"../hdl/rffe_switch.vhd" "VHDL 2008"}       
      
  lappend Sources {"../hdl/dsp/fa_dsp.vhd" "VHDL 2008"} 
  lappend Sources {"../hdl/dsp/sa_dsp.vhd" "VHDL 2008"}  
  
  lappend Sources {"../hdl/evr/evr_top.vhd" "VHDL 2008"} 
  lappend Sources {"../hdl/evr/ts_gen.vhd" "VHDL 2008"} 
  
  lappend Sources {"../hdl/evr/evg_top.vhd" "VHDL 2008"}   
  lappend Sources {"../hdl/evr/event_rcv_chan.vhd" "VHDL 2008"} 
  lappend Sources {"../hdl/evr/event_rcv_ts.vhd" "VHDL 2008"}  
  #lappend Sources {"../hdl/evr/EventReceiverChannel.v" "Verilog"}  
  #lappend Sources {"../hdl/evr/timeofDayReceiver.v" "Verilog"} 

  lappend Sources {"../cstr/pins.xdc"  "XDC"}
  lappend Sources {"../cstr/afepins.xdc"  "XDC"}
  lappend Sources {"../cstr/gth.xdc"  "XDC"}   
  lappend Sources {"../cstr/timing.xdc"  "XDC"} 
  lappend Sources {"../cstr/debug.xdc"  "XDC"} 
  
  
}

# ==============================================================================
proc setAddressSpace {} {
   ::fwfwk::printCBM "In ./hw/src/main.tcl setAddressSpace()..."
  variable AddressSpace
  
  addAddressSpace AddressSpace "pl_regs"   RDL  {} ../rdl/pl_regs.rdl

}


# ==============================================================================
proc doOnCreate {} {
  # variable Vhdl
  variable TclPath

      
  ::fwfwk::printCBM "In ./hw/src/main.tcl doOnCreate()"
  set_property part             xczu6eg-ffvb1156-1-e         [current_project]
  set_property target_language  VHDL                         [current_project]
  set_property default_lib      xil_defaultlib               [current_project]
   
  #set_property used_in_synthesis false [get_files /home/mead/rfbpm/fwk/zubpm/src/hw/hdl/top_tb.sv] 
  #set_property used_in_implementation false [get_files  top_tb.v] 
   
  source ${TclPath}/system.tcl
  source ${TclPath}/adc_fco_phaseshift.tcl
  source ${TclPath}/adcbuf_fifo.tcl
  source ${TclPath}/tbtbuf_fifo.tcl 
  source ${TclPath}/adcdata_fifo.tcl 
  source ${TclPath}/div_gen.tcl
  source ${TclPath}/evr_gth.tcl
  source ${TclPath}/fir_compiler_lp_ddc.tcl
  source ${TclPath}/rffe_sw_shift.tcl

  addSources "Sources" 
  
  ::fwfwk::printCBM "TclPath = ${TclPath}"
  ::fwfwk::printCBM "SrcPath = ${::fwfwk::SrcPath}"
  
  set_property used_in_synthesis false [get_files ${::fwfwk::SrcPath}/hw/hdl/top_tb.sv] 
  set_property used_in_implementation false [get_files ${::fwfwk::SrcPath}/hw/hdl/top_tb.sv] 
  
  #open_wave_config "${::fwfwk::SrcPath}/hw/sim/top_tb_behav.wcfg"
  

  
  
}

# ==============================================================================
proc doOnBuild {} {
  ::fwfwk::printCBM "In ./hw/src/main.tcl doOnBuild()"



}


# ==============================================================================
proc setSim {} {
}
