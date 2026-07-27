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

entity tbt_dsp is
  port ( 
    rst             : in std_logic;
    clk             : in std_logic;
    adc_data        : in t_adc_raw;
    tbt_trig        : in std_logic;
    tbt_data        : out t_tbt_data;
    tbt_params      : in t_reg_o_tbt
);
end tbt_dsp;
   
architecture behv of tbt_dsp is
  


signal sine        : signed(15 downto 0);
signal cos         : signed(15 downto 0);

signal cha_qraw    : signed(31 downto 0);
signal cha_qraw_sc : signed(23 downto 0);
signal cha_qfir    : signed(23 downto 0);
signal cha_iraw    : signed(31 downto 0);
signal cha_iraw_sc : signed(23 downto 0);
signal cha_ifir    : signed(23 downto 0);

signal ddc_done    : std_logic;
signal pos_done    : std_logic;
signal cha_mag     : signed(31 downto 0);
signal cha_phs     : signed(31 downto 0);
signal chb_mag     : signed(31 downto 0);
signal chb_phs     : signed(31 downto 0);
signal chc_mag     : signed(31 downto 0);
signal chc_phs     : signed(31 downto 0);
signal chd_mag     : signed(31 downto 0);
signal chd_phs     : signed(31 downto 0);
signal xpos        : signed(31 downto 0);
signal ypos        : signed(31 downto 0);
signal xpos_nm     : signed(31 downto 0);   
signal ypos_nm     : signed(31 downto 0);   
signal sum         : signed(31 downto 0);

signal adca_raw    : signed(31 downto 0);
signal adcb_raw    : signed(31 downto 0);
signal adcc_raw    : signed(31 downto 0);
signal adcd_raw    : signed(31 downto 0);



signal adca_sc    : signed(23 downto 0);
signal adcb_sc    : signed(23 downto 0);
signal adcc_sc    : signed(23 downto 0);
signal adcd_sc    : signed(23 downto 0);


-- attribute mark_debug     : string;
-- attribute mark_debug of tbt_params: signal is "true";
-- attribute mark_debug of adca_sc: signal is "true";
-- attribute mark_debug of adcb_sc: signal is "true";
-- attribute mark_debug of adcc_sc: signal is "true";
-- attribute mark_debug of adcd_sc: signal is "true";
------ attribute mark_debug of sine: signal is "true";
------ attribute mark_debug of cos: signal is "true";
------ attribute mark_debug of tbt_trig: signal is "true";
------ attribute mark_debug of ddc_done: signal is "true";
------ attribute mark_debug of pos_done: signal is "true";
-- attribute mark_debug of cha_mag: signal is "true";
-- attribute mark_debug of chb_mag: signal is "true"; 
-- attribute mark_debug of chc_mag: signal is "true";
-- attribute mark_debug of chd_mag: signal is "true"; 
---- attribute mark_debug of xpos: signal is "true";
---- attribute mark_debug of ypos: signal is "true"; 
---- attribute mark_debug of sum: signal is "true";
----attribute mark_debug of xpos_nm: signal is "true";
---- attribute mark_debug of ypos_nm: signal is "true"; 


begin

 
tbt_data.cha_mag <= cha_mag;
tbt_data.cha_phs <= cha_phs;
tbt_data.chb_mag <= chb_mag;
tbt_data.chb_phs <= chb_phs;
tbt_data.chc_mag <= chc_mag;
tbt_data.chc_phs <= chc_phs;
tbt_data.chd_mag <= chd_mag;
tbt_data.chd_phs <= chd_phs;
tbt_data.xpos <= xpos;
tbt_data.ypos <= ypos;
tbt_data.xpos_nm <= xpos_nm;
tbt_data.ypos_nm <= ypos_nm;
tbt_data.sum <= sum;
 
 

 
 
 
 -- lookup table for complex multiply
sine_term : entity work.beam_sine_rom 
  port map ( 
    clk => clk, 
    rst => rst, 
    tbt_trig => tbt_trig,
    dout => sine
);

cos_term : entity work.beam_cos_rom 
  port map ( 
    clk => clk, 
    rst => rst, 
    tbt_trig => tbt_trig,
    dout => cos
);
  
 

 
 
 process(clk)
  begin
    if (rising_edge(clk)) then
      adca_raw <= signed(adc_data(0)) * signed(tbt_params.cha_gain);
      adcb_raw <= signed(adc_data(1)) * signed(tbt_params.chb_gain);
      adcc_raw <= signed(adc_data(2)) * signed(tbt_params.chc_gain);
      adcd_raw <= signed(adc_data(3)) * signed(tbt_params.chd_gain);
    end if;
end process;

 adca_sc <= adca_raw(30 downto 7);
 adcb_sc <= adcb_raw(30 downto 7);
 adcc_sc <= adcc_raw(30 downto 7);
 adcd_sc <= adcd_raw(30 downto 7);  
  
  
cha_ddc: entity work.beam_ddc
  port map (
    clk => clk,
    rst => rst,
    tbt_trig => tbt_trig,
    lpfilt_sel => tbt_params.ddc_lpfilt_sel,
    din => adca_sc, --adc_data(0),
    sine => sine,
    cos => cos,
    ddc_done => ddc_done, 
    isum => tbt_data.cha_i,
    qsum => tbt_data.cha_q,
    mag => cha_mag,
    phs => cha_phs
);    
  
  
chb_ddc: entity work.beam_ddc
  port map (
    clk => clk,
    rst => rst,
    tbt_trig => tbt_trig,
    lpfilt_sel => tbt_params.ddc_lpfilt_sel,    
    din => adcb_sc, --adc_data(1),
    sine => sine,
    cos => cos,
    isum => tbt_data.chb_i,
    qsum => tbt_data.chb_q,
    mag => chb_mag,
    phs => chb_phs
);   


chc_ddc: entity work.beam_ddc
  port map (
    clk => clk,
    rst => rst,
    tbt_trig => tbt_trig,
    lpfilt_sel => tbt_params.ddc_lpfilt_sel,   
    din => adcc_sc, 
    sine => sine,
    cos => cos,
    isum => tbt_data.chc_i,
    qsum => tbt_data.chc_q,
    mag => chc_mag,
    phs => chc_phs
);    
  
  
chd_ddc: entity work.beam_ddc
  port map (
    clk => clk,
    rst => rst,
    tbt_trig => tbt_trig,
    lpfilt_sel => tbt_params.ddc_lpfilt_sel,   
    din => adcd_sc, 
    sine => sine,
    cos => cos,
    isum => tbt_data.chd_i,
    qsum => tbt_data.chd_q,
    mag => chd_mag,
    phs => chd_phs
);   


tbtpos: entity work.pos_calc
  port map ( 
    clk => clk,
    rst => rst,
    ddc_done => ddc_done,
    cha_mag => cha_mag,
    chb_mag => chb_mag,
    chc_mag => chc_mag,
    chd_mag => chd_mag, 
    tbt_params => tbt_params,              
    xpos => xpos,
    xpos_nm => xpos_nm,
    ypos => ypos,
    ypos_nm => ypos_nm,
    sum => sum,
    pos_done => pos_done
);



end behv;
