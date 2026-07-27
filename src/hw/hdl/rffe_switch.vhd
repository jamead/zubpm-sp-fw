----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/18/2020 03:19:57 PM
-- Design Name: 
-- Module Name: tbt_dsp - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;


library work;
use work.bpm_package.ALL;
 
--library UNISIM;
--use UNISIM.VComponents.all;

entity rffe_switch is
  port ( 
    rst               : in std_logic;
    clk               : in std_logic;
    tbt_trig          : in std_logic;
    fa_trig           : in std_logic;
    reg_o             : in t_reg_o_swrffe;
    adc_data_i        : in t_adc_raw; 
    adc_data_o        : out t_adc_raw; 
    adc_data_dma      : out t_adc_raw; 
    sw_rffe_p         : out std_logic;
    sw_rffe_n         : out std_logic;
    sw_rffe_demux     : out std_logic;
    sw_rffe_time      : out std_logic
);
end rffe_switch;
 
architecture behv of rffe_switch is
   
component rffe_sw_shift IS
  port (
    a : in std_logic_vector(8 downto 0); 
    D : in std_logic_vector(0 downto 0); 
    CLK : in std_logic; 
    Q : out std_logic_vector(0 downto 0)
  );
end component;

  signal sw_rffe        : std_logic;
  signal sw_rffe_i      : std_logic;
  signal sw_rffe_di     : std_logic_vector(0 downto 0);
  signal sw_rffe_do     : std_logic_vector(0 downto 0);
  signal sw_cnt         : INTEGER range 0 to 65535; 
  signal fa_cnt         : INTEGER range 0 to 65535;
  signal fa_cnt_lat     : INTEGER range 0 to 65535;
  signal fa_trig_dlyd   : std_logic_vector(0 downto 0);
  signal fa_trig_vector : std_logic_vector(0 downto 0);


 attribute mark_debug     : string;
 attribute mark_debug of sw_rffe_p: signal is "true";
 attribute mark_debug of sw_rffe_demux: signal is "true";
 attribute mark_debug of tbt_trig: signal is "true";
 attribute mark_debug of fa_trig: signal is "true";
 attribute mark_debug of sw_rffe_i: signal is "true";
 attribute mark_debug of fa_cnt: signal is "true";
 attribute mark_debug of fa_cnt_lat: signal is "true";
 attribute mark_debug of sw_cnt: signal is "true";
 attribute mark_debug of fa_trig_dlyd: signal is "true";
 attribute mark_debug of reg_o: signal is "true";


begin

sw_rffe_p <= sw_rffe;
sw_rffe_n <= not sw_rffe;


sw_rffe <= '0' when reg_o.enb = "00" else
           '1' when reg_o.enb = "01" else
           sw_rffe_i;
           
sw_rffe_time <= fa_trig_dlyd(0);

-- count adc pulses between fa trigs
-- for debugging purposes only
process (clk, rst)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        fa_cnt <= 0;
        fa_cnt_lat <= 0;
      else
        if (fa_trig = '1') then
          fa_cnt_lat <= fa_cnt;
          fa_cnt <= 0;
        else
          fa_cnt <= fa_cnt + 1;
        end if;
      end if;
    end if;
end process;



-- generate a delayed version of the fa_trig signal
-- so that the rffe switch can start anywhere in the turn

fa_trig_vector(0) <= fa_trig;
fa_shft : rffe_sw_shift
   port map (
     a => reg_o.trigdly(8 downto 0),
     d => fa_trig_vector,
     clk => clk,
     q => fa_trig_dlyd
 );




-- generate the rffe switch signal
-- 5890 adc clocks is 1/2 fa period  (310*19)
process (clk, rst)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        sw_rffe_i <= '0';
        sw_cnt <= 0;
      else
        sw_cnt <= sw_cnt + 1;
        if (fa_trig_dlyd(0) = '1') then
          sw_cnt <= 0;
          sw_rffe_i  <= '0';
        elsif (sw_cnt >= 5889) then  
          sw_rffe_i <= '1';
        end if;
      end if;
    end if;
end process;







-- shift delay the demux signal to compensate for the rf switch delay
sw_rffe_di(0) <= sw_rffe;
sw_rffe_demux <= sw_rffe_do(0);
 
sw_shft : rffe_sw_shift
   port map (
     a => reg_o.demuxdly,
     d => sw_rffe_di,
     clk => clk,
     q => sw_rffe_do
 );
 
 --0=chA, 1=chB, 2=chC, 3=chD
 --switch A-C  and B-D
-- do the switcher demuxing
 process(clk)
  begin
    if (rising_edge(clk)) then
      if (sw_rffe_do(0) = '0') then
        adc_data_o(0) <= adc_data_i(0);
        adc_data_o(1) <= adc_data_i(1);
        adc_data_o(2) <= adc_data_i(2);
        adc_data_o(3) <= adc_data_i(3);               
      else
        adc_data_o(2) <= adc_data_i(0);
        adc_data_o(3) <= adc_data_i(1);
        adc_data_o(0) <= adc_data_i(2);
        adc_data_o(1) <= adc_data_i(3);  
      end if; 
    end if;
end process;



process(clk)
  begin
    if (rising_edge(clk)) then
      if (reg_o.adcdma_sel = '0') then
        adc_data_dma(0) <= adc_data_i(0);
        adc_data_dma(1) <= adc_data_i(1);
        adc_data_dma(2) <= adc_data_i(2);
        adc_data_dma(3) <= adc_data_i(3);               
      else
        adc_data_dma(0) <= adc_data_o(0);
        adc_data_dma(1) <= adc_data_o(1);
        adc_data_dma(2) <= adc_data_o(2);
        adc_data_dma(3) <= adc_data_o(3);  
      end if; 
    end if;
end process;



end behv;
