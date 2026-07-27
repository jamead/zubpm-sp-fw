----------------------------------------------------------------------------------
-- Company:  Brookhaven National Lab
-- Engineer: Joseph Mead
-- 
-- Create Date: 09/19/2019 10:25:22 AM
-- Design Name: 
-- Module Name: beam_integrate.vhd
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description:   Performs a 10 Hz filter with a decimation of 942857.
--                Implemented as a block averager followed by a 4 tap fir.
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.bpm_package.ALL;  


entity sa_dsp is
  port (
    clk             : in std_logic;
    rst             : in std_logic;
    tbt_data        : in t_tbt_data;
    tbt_trig        : in std_logic;
    sa_trig         : in std_logic;
    sa_data         : out t_sa_data

);
end sa_dsp;      
  
 
architecture behv of sa_dsp is

  constant ACCUMLEN      : INTEGER := 38000; 
 
  --1/38000= 26.31578e-6 * 2^16 * 2^10= 1766 => x"06E6"
  constant SCALE         : std_logic_vector(15 downto 0) := x"06E6"; 

  signal cha_accum           : signed(47 downto 0);
  signal chb_accum           : signed(47 downto 0);
  signal chc_accum           : signed(47 downto 0);
  signal chd_accum           : signed(47 downto 0);
  signal xpos_accum          : signed(47 downto 0);  
  signal ypos_accum          : signed(47 downto 0);    
  signal sum_accum           : signed(47 downto 0); 

  signal cha_accum_lat       : signed(47 downto 0);
  signal chb_accum_lat       : signed(47 downto 0);
  signal chc_accum_lat       : signed(47 downto 0);
  signal chd_accum_lat       : signed(47 downto 0);
  signal xpos_accum_lat      : signed(47 downto 0);  
  signal ypos_accum_lat      : signed(47 downto 0);    
  signal sum_accum_lat       : signed(47 downto 0); 
  
  signal cha_accum_scaled    : signed(63 downto 0);
  signal chb_accum_scaled    : signed(63 downto 0);
  signal chc_accum_scaled    : signed(63 downto 0);
  signal chd_accum_scaled    : signed(63 downto 0);
  signal xpos_accum_scaled   : signed(63 downto 0);  
  signal ypos_accum_scaled   : signed(63 downto 0);    
  signal sum_accum_scaled    : signed(63 downto 0);   
  
  signal accum_len           : std_logic_vector(21 downto 0);
  signal accum_cnt           : INTEGER RANGE 0 to ACCUMLEN;
  signal accum_done           : std_logic;
  
  signal sa_cnt_i            : std_logic_vector(31 downto 0);
  
  signal sa_cha              : std_logic_vector(31 downto 0);
 
--   attribute mark_debug     : string;
--   attribute mark_debug of cha_accum: signal is "true";
--   attribute mark_debug of cha_accum_lat: signal is "true";
--   attribute mark_debug of cha_accum_scaled: signal is "true";  
--   attribute mark_debug of xpos_accum: signal is "true";
--   attribute mark_debug of xpos_accum_lat: signal is "true";
--   attribute mark_debug of xpos_accum_scaled: signal is "true";  
   
--   attribute mark_debug of sa_data:  signal is "true";  
--   attribute mark_debug of sa_trig: signal is "true";
--   attribute mark_debug of accum_cnt: signal is "true";
--   attribute mark_debug of accum_done: signal is "true";
--   attribute mark_debug of sa_cnt: signal is "true";
 
 
begin  

sa_data.cnt <= sa_cnt_i;

--truncate output to 32 bits
sa_data.cha_mag <= cha_accum_scaled(57 downto 26);
sa_data.chb_mag <= chb_accum_scaled(57 downto 26);
sa_data.chc_mag <= chc_accum_scaled(57 downto 26);
sa_data.chd_mag <= chd_accum_scaled(57 downto 26);
sa_data.xpos <= xpos_accum_scaled(57 downto 26);
sa_data.ypos <= ypos_accum_scaled(57 downto 26);
sa_data.sum <= sum_accum_scaled(57 downto 26);


 

-- registered scaled output
process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        cha_accum_scaled <= (others => '0');
        chb_accum_scaled <= (others => '0');       
        chc_accum_scaled <= (others => '0');       
        chd_accum_scaled <= (others => '0');     
        xpos_accum_scaled <= (others => '0'); 
        ypos_accum_scaled <= (others => '0');
        sum_accum_scaled <= (others => '0');
        --sa_trig <= '0'; 

      else
        if (sa_trig = '1') then 
        --if (accum_done = '1') then
          cha_accum_scaled <= cha_accum_lat * signed(SCALE);  
          chb_accum_scaled <= chb_accum_lat * signed(SCALE);             
          chc_accum_scaled <= chc_accum_lat * signed(SCALE);           
          chd_accum_scaled <= chd_accum_lat * signed(SCALE);    
          xpos_accum_scaled <= xpos_accum_lat * signed(SCALE);   
          ypos_accum_scaled <= ypos_accum_lat * signed(SCALE);  
          sum_accum_scaled <= sum_accum_lat * signed(SCALE);  
          --sa_trig <= '1';      
        --else
          --sa_trig <= '0';         
        end if;
      end if;
    end if; 
 end process;
 
 




-- do the accumulation (block average)
process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        cha_accum <= (others => '0');
        chb_accum <= (others => '0');
        chc_accum <= (others => '0');
        chd_accum <= (others => '0');
        xpos_accum <= (others => '0');
        ypos_accum <= (others => '0');
        sum_accum <= (others => '0');
        accum_done <= '0';
        accum_cnt <= 0;
        sa_cnt_i <= (others => '0');
      else  
        if (tbt_trig = '1') then
          if (accum_cnt = ACCUMLEN-1) then
            cha_accum <= resize(tbt_data.cha_mag,cha_accum'length); 
            chb_accum <= resize(tbt_data.chb_mag,chb_accum'length); 
            chc_accum <= resize(tbt_data.chc_mag,chc_accum'length); 
            chd_accum <= resize(tbt_data.chd_mag,chd_accum'length); 
            xpos_accum <= resize(tbt_data.xpos_nm,xpos_accum'length); 
            ypos_accum <= resize(tbt_data.ypos_nm,ypos_accum'length); 
            sum_accum <= resize(tbt_data.sum,sum_accum'length);               
--            cha_accum <= x"0000" & tbt_data.cha_mag; 
--            chb_accum <= x"0000" & tbt_data.chb_mag; 
--            chc_accum <= x"0000" & tbt_data.chc_mag; 
--            chd_accum <= x"0000" & tbt_data.chd_mag; 
--            xpos_accum <= x"0000" & tbt_data.xpos; 
--            ypos_accum <= x"0000" & tbt_data.ypos; 
--            sum_accum <= x"0000" & tbt_data.sum;
            cha_accum_lat <= cha_accum;
            chb_accum_lat <= chb_accum;
            chc_accum_lat <= chc_accum;
            chd_accum_lat <= chd_accum;            
            xpos_accum_lat <= xpos_accum;
            ypos_accum_lat <= ypos_accum;           
            sum_accum_lat <= sum_accum;     
            accum_cnt <= 0;
            accum_done <= '1';
            sa_cnt_i <= sa_cnt_i + 1;
          else
            accum_done <= '0';
            accum_cnt <= accum_cnt + 1;
            cha_accum <= tbt_data.cha_mag + cha_accum;
            chb_accum <= tbt_data.chb_mag + chb_accum;           
            chc_accum <= tbt_data.chc_mag + chc_accum;           
            chd_accum <= tbt_data.chd_mag + chd_accum;           
            xpos_accum <= tbt_data.xpos_nm + xpos_accum;
            ypos_accum <= tbt_data.ypos_nm + ypos_accum;          
            sum_accum <= tbt_data.sum + sum_accum;   
          end if;
        end if;  
      end if;
   end if;
end process;




  
end behv;
