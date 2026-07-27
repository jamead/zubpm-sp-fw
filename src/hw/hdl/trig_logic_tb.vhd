-------------------------------------------------------------------------------
-- Testbench for trig_logic
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.bpm_package.ALL; 


entity tb_trig_logic is
end tb_trig_logic;

architecture sim of tb_trig_logic is
  -- DUT signals
  signal adc_clk        : std_logic := '0';
  signal reset          : std_logic := '1';
  signal reg_o          : t_reg_o_dma;
  signal reg_i          : t_reg_i_dma;
  signal evr_trig       : std_logic := '0';
  signal dma_adc_active : std_logic := '0';
  signal dma_tbt_active : std_logic := '0';
  signal dma_fa_active  : std_logic := '0';
  signal evr_ts         : std_logic_vector(63 downto 0) := (others => '0');
  signal evr_ts_lat     : std_logic_vector(63 downto 0);
  signal dma_permit     : std_logic;
  signal dma_trig       : std_logic;

begin
  -- DUT instantiation
  uut: entity work.trig_logic
    port map (
      adc_clk        => adc_clk,
      reset          => reset,
      reg_o          => reg_o,
      reg_i          => reg_i,
      evr_trig       => evr_trig,
      dma_adc_active => dma_adc_active,
      dma_tbt_active => dma_tbt_active,
      dma_fa_active  => dma_fa_active,
      evr_ts         => evr_ts,
      evr_ts_lat     => evr_ts_lat,
      dma_permit     => dma_permit,
      dma_trig       => dma_trig
    );

  -- Clock generation: 100 MHz
  clk_proc: process
  begin
    wait for 5 ns;
    adc_clk <= not adc_clk;
  end process;

  -- Stimulus
  stim_proc: process
  begin
    -- Hold reset
    reset <= '1';
    wait for 20 ns;
    reset <= '0';

    -- Initialize reg_o
    reg_o.adc_enb   <= '1';
    reg_o.tbt_enb   <= '1';
    reg_o.fa_enb    <= '1';
    reg_o.trigsrc   <= '0';  -- start with EVR
    reg_o.soft_trig <= '0';

    -- Apply EVR trigger
    evr_ts <= x"0000000100000001";



    evr_trig <= '1';
    wait for 10 ns;
    evr_trig <= '0';

    -- Simulate DMA running
    wait for 40 ns;
    dma_adc_active <= '1';

    wait for 200 ns;
    evr_trig <= '1';
    wait for 10 ns;
    evr_trig <= '0';
    wait for 200 ns;
    
    wait for 500 ns;
    
    dma_adc_active <= '0';
    
    wait for 100 ns;
    
    evr_trig <= '1';
    wait for 10 ns;
    evr_trig <= '0';

    wait for 500 ns;
    reg_o.txtoioc_done <= '1';
    wait for 100 ns;
    reg_o.txtoioc_done <= '0';
    
    wait for 3000 ns;
    
    
    -- another trigger
    
    evr_trig <= '1';
    wait for 10 ns;
    evr_trig <= '0';


    wait for 40 ns;
    dma_adc_active <= '1';

    wait for 200 ns;
    evr_trig <= '1';
    wait for 10 ns;
    evr_trig <= '0';
    wait for 200 ns;
    
    wait for 500 ns;
    
    dma_adc_active <= '0';
    
    wait for 100 ns;
    
    evr_trig <= '1';
    wait for 10 ns;
    evr_trig <= '0';

    wait for 500 ns;
    reg_o.txtoioc_done <= '1';
    wait for 100 ns;
    reg_o.txtoioc_done <= '0';  
    
 
   -- another trigger
    
    evr_trig <= '1';
    wait for 10 ns;
    evr_trig <= '0';


    wait for 40 ns;
    dma_adc_active <= '1';

    wait for 200 ns;
    evr_trig <= '1';
    wait for 10 ns;
    evr_trig <= '0';
    wait for 200 ns;
    
    wait for 500 ns;
    
    dma_adc_active <= '0';
    
    wait for 100 ns;
    
    evr_trig <= '1';
    wait for 10 ns;
    evr_trig <= '0';

    wait for 500 ns;
    reg_o.txtoioc_done <= '1';
    wait for 100 ns;
    reg_o.txtoioc_done <= '0';  
    
        
    

    -- Switch to soft trigger
    --wait for 40 ns;
    --reg_o.trigsrc <= '1';

    -- Apply soft trigger pulse
    --reg_o.soft_trig <= '1';
    --wait for 10 ns;
    --reg_o.soft_trig <= '0';



    -- End simulation
    wait for 10000 ns;
    assert false report "Simulation finished." severity failure;
  end process;
end sim;

