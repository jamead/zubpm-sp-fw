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

use std.textio.all;

library work;
use work.bpm_package.ALL;
 
--library UNISIM;
--use UNISIM.VComponents.all;

entity pos_calc is
  port ( 
    rst             : in std_logic;
    clk             : in std_logic;
    ddc_done        : in std_logic;
    cha_mag         : in signed(31 downto 0);
    chb_mag         : in signed(31 downto 0);
    chc_mag         : in signed(31 downto 0);
    chd_mag         : in signed(31 downto 0);
    tbt_params      : in t_reg_o_tbt;              
    xpos            : out signed(31 downto 0);
    ypos            : out signed(31 downto 0);
    xpos_nm         : out signed(31 downto 0);
    ypos_nm         : out signed(31 downto 0);
    sum             : out signed(31 downto 0);
    pos_done        : out std_logic   
);
end pos_calc;

architecture behv of pos_calc is

  
   

component div_gen IS
  port (
    aclk : IN STD_LOGIC;
    s_axis_divisor_tvalid : IN STD_LOGIC;
    s_axis_divisor_tdata : IN std_logic_vector(31 DOWNTO 0);
    s_axis_dividend_tvalid : IN STD_LOGIC;
    s_axis_dividend_tdata : IN std_logic_vector(31 DOWNTO 0);
    m_axis_dout_tvalid : OUT STD_LOGIC;
    m_axis_dout_tdata : OUT std_logic_vector(63 DOWNTO 0)
  );
end component;


signal xnum      : signed(31 downto 0);
signal ynum      : signed(31 downto 0);

signal xpos_nm64 : signed(63 downto 0);
signal ypos_nm64 : signed(63 downto 0);


signal xnumer    : std_logic_vector(31 downto 0);
signal ynumer    : std_logic_vector(31 downto 0);
signal denom     : std_logic_vector(31 downto 0);

signal xdiv_data : std_logic_vector(63 downto 0);
signal ydiv_data : std_logic_vector(63 downto 0);



-- attribute mark_debug     : string;
-- attribute mark_debug of xnum: signal is "true";
-- attribute mark_debug of ynum: signal is "true";
-- attribute mark_debug of sum: signal is "true";



begin


ynum <= (cha_mag + chb_mag) - (chc_mag + chd_mag);
xnum <= (cha_mag + chd_mag) - (chb_mag + chc_mag);
sum <= cha_mag + chb_mag + chc_mag + chd_mag;
  



xnumer <= std_logic_vector(xnum);
ynumer <= std_logic_vector(ynum);
denom <= std_logic_vector(sum);



xpos <= signed(xdiv_data(31 downto 0));
ypos <= signed(ydiv_data(31 downto 0));

xpos_nm64 <= signed(xdiv_data(31 downto 0)) * signed(tbt_params.kx);
xpos_nm <= xpos_nm64(62 downto 31) - signed(tbt_params.xpos_offset);  

ypos_nm64 <= signed(ydiv_data(31 downto 0)) * signed(tbt_params.ky);
ypos_nm <= ypos_nm64(62 downto 31) - signed(tbt_params.ypos_offset);




xpos_div: div_gen
  port map(
    aclk => clk, 
    s_axis_divisor_tvalid => ddc_done, 
    s_axis_divisor_tdata => denom, 
    s_axis_dividend_tvalid => ddc_done,
    s_axis_dividend_tdata => xnumer, 
    m_axis_dout_tvalid => pos_done, 
    m_axis_dout_tdata => xdiv_data
  );


ypos_div: div_gen
  port map(
    aclk => clk, 
    s_axis_divisor_tvalid => ddc_done, 
    s_axis_divisor_tdata => denom, 
    s_axis_dividend_tvalid => ddc_done,
    s_axis_dividend_tdata => ynumer, 
    m_axis_dout_tvalid => open, 
    m_axis_dout_tdata => ydiv_data
  );


--  process(tbt_trig,rst)
--    --file location is ./vivado.sim/sim_1/behav/xsim
--    --file adc_vector   : text open read_mode is "/home/mead/rfbpm/quadadc/zdfe_qadc_v11_ad9653/src/sim_adcdata.txt";
--    file tbt_vector   : text open write_mode is "/home/mead/jam/rfbpm/pcb/tbt_digitizer/python/sim_tbtdata.txt";

--    variable row       : line;
--    variable tbt_cnt    : integer range 0 to 1000;

  
--    begin
--      if (rising_edge(tbt_trig)) then
--        if (rst = '1') then
--           tbt_cnt := 0;
--        else
--           write(row,to_integer(signed(tbt.cha_mag)),right,12);
--           write(row,to_integer(signed(tbt.chb_mag)),right,12);         
--           write(row,to_integer(signed(tbt.chc_mag)),right,12);   
--           write(row,to_integer(signed(tbt.chd_mag)),right,12);             
--           write(row,to_integer(signed(xnumer)),right,12);
--           write(row,to_integer(signed(ynumer)),right,12);
--           write(row,to_integer(signed(denom)),right,12);
--           write(row,to_integer(signed(xpos)),right,12);
--           write(row,to_integer(signed(ypos)),right,12);         
--           writeline(tbt_vector,row);
--           tbt_cnt := tbt_cnt + 1; 
--           report "Writing TbT data = " & integer'image(tbt_cnt);
--           --if (tbt_cnt = 100) then
--           --  file_close(tbt_vector);
--           --end if;
--        end if;
--      end if;
--end process;


end behv;
