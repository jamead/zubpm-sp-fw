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

entity beam_ddc is
  port ( 
    rst             : in std_logic;
    clk             : in std_logic;
    tbt_trig        : in std_logic;
    lpfilt_sel      : in std_logic;
    din             : in signed(23 downto 0);
    sine            : in signed(15 downto 0);
    cos             : in signed(15 downto 0);
    ddc_done        : out std_logic;
    isum            : out signed(31 downto 0);
    qsum            : out signed(31 downto 0);
    mag             : out signed(31 downto 0);
    phs             : out signed(31 downto 0)
 
);
end beam_ddc;
  
architecture behv of beam_ddc is
 
component fir_lp_ddc is
  port ( 
    clk : in std_logic;
    rst : in std_logic;
    din : in signed(23 downto 0);
    dout : out signed(23 downto 0)
 );
end component;

component fir_compiler_lp_ddc is
  port (
    aclk : IN STD_LOGIC;
    s_axis_data_tvalid : IN STD_LOGIC;
    s_axis_data_tready : OUT STD_LOGIC;
    s_axis_data_tdata : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(47 DOWNTO 0)
  );
end component;




component seqpolar 
  port (
    i_clk : in std_logic;
    i_reset : in std_logic;
    i_stb : in std_logic;
    i_xval : in signed(28 downto 0);
    i_yval : in signed(28 downto 0);
    i_aux : in std_logic;
    o_busy : out std_logic;
    o_done : out std_logic;
    o_mag : out signed(25 downto 0);
    o_phase : out signed(25 downto 0);
    o_aux : out std_logic
);
end component;        


component rect2polar_seq 
  port (
    i_clk : in std_logic;
    i_reset : in std_logic;
    i_stb : in std_logic;
    i_xval : in signed(31 downto 0);
    i_yval : in signed(31 downto 0);
    i_aux : in std_logic;
    o_busy : out std_logic;
    o_done : out std_logic;
    o_mag : out signed(31 downto 0);
    o_phase : out signed(31 downto 0);
    o_aux : out std_logic
);
end component;       




signal qraw            : signed(39 downto 0);
signal qraw_sc         : signed(23 downto 0);
signal qfir            : signed(23 downto 0);
signal qfir4tap        : signed(23 downto 0);
signal qfir100tap      : signed(23 downto 0);
signal iraw            : signed(39 downto 0);
signal iraw_sc         : signed(23 downto 0);
signal ifir            : signed(23 downto 0);
signal ifir4tap        : signed(23 downto 0);
signal ifir100tap      : signed(23 downto 0);

signal qfilt_tready    : std_logic;
signal qfilt_tvalid    : std_logic;
signal qfilt_tdata_fp  : std_logic_vector(47 downto 0);
signal qfilt_tdata     : signed(23 downto 0);

signal ifilt_tready    : std_logic;
signal ifilt_tvalid    : std_logic;
signal ifilt_tdata_fp  : std_logic_vector(47 downto 0);
signal ifilt_tdata     : signed(23 downto 0);

signal iacc            : signed(31 downto 0);
signal qacc            : signed(31 downto 0);

signal cordic_done     : std_logic;

signal mag_i           : signed(25 downto 0);
signal phs_i           : signed(25 downto 0);



-- attribute mark_debug     : string;
-- attribute mark_debug of din:signal is "true";
-- attribute mark_debug of sine: signal is "true";
-- attribute mark_debug of cos: signal is "true";
-- attribute mark_debug of iraw_sc: signal is "true";
-- attribute mark_debug of qraw_sc: signal is "true";
-- attribute mark_debug of ifir: signal is "true";
-- attribute mark_debug of qfir: signal is "true";


begin



  
--down convert multipliers
process(clk)
  begin
    if (rising_edge(clk)) then
       qraw <= din * sine;
       iraw <= din * cos;
    end if;
end process;
qraw_sc <= qraw(39 downto 16);
iraw_sc <= iraw(39 downto 16);



-- low pass filters to cut out the sum term from the multiply
-- 4 tap fir filter  
q_firfilt: fir_lp_ddc
    port map ( 
      clk => clk, 
      rst => rst, 
      din => qraw_sc,
      dout => qfir4tap
   );
   
   
-- 101 tap fir filter (to remove Pilot Tone)   
q_fircompfilt:  fir_compiler_lp_ddc 
  port map (
    aclk => clk, 
    s_axis_data_tvalid => '1', 
    s_axis_data_tready => qfilt_tready,  
    s_axis_data_tdata => std_logic_vector(qraw_sc), 
    m_axis_data_tvalid => qfilt_tvalid, 
    m_axis_data_tdata => qfilt_tdata_fp
  );  
   
 qfir100tap <= signed(qfilt_tdata_fp(47 downto 24));  



  
i_firfilt: fir_lp_ddc
    port map ( 
      clk => clk, 
      rst => rst, 
      din => iraw_sc,
      dout => ifir4tap
   );


-- 101 tap fir filter (to remove Pilot Tone)   
i_fircompfilt:  fir_compiler_lp_ddc 
  port map (
    aclk => clk, 
    s_axis_data_tvalid => '1', 
    s_axis_data_tready => ifilt_tready,  
    s_axis_data_tdata => std_logic_vector(iraw_sc), 
    m_axis_data_tvalid => ifilt_tvalid, 
    m_axis_data_tdata => ifilt_tdata_fp
  );  
   
 ifir100tap <= signed(ifilt_tdata_fp(47 downto 24));  



process(clk)
  begin
    if (rising_edge(clk)) then
      if (lpfilt_sel = '0') then
         qfir <= qfir4tap;
         ifir <= ifir4tap;
      else
         qfir <= qfir100tap;
         ifir <= ifir100tap;
      end if;
    end if;
end process;



-- accumulate I,Q for a turn
process(clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1')  then
        isum <= (others => '0');
        qsum <= (others => '0');
        iacc <= (others => '0');
        qacc <= (others => '0');
      else
        if (tbt_trig = '1') then
          isum <= iacc;
          qsum <= qacc;
          iacc <= (others => '0');
          qacc <= (others => '0');
        else
          iacc <= iacc + ifir;
          qacc <= qacc + qfir;
        end if;
      end if;
    end if;
end process;
 

-- convert i,q to mag, phase
cordic: seqpolar --rect2polar_seq --seqpolar 
  port map (
    i_clk => clk, 
    i_reset => rst,
    i_stb => tbt_trig, --tenhz_valid,
    i_xval => isum(31 downto 3),  
    i_yval => qsum(31 downto 3),  
    i_aux => ('0'), 
    o_busy => open, 
    o_done => cordic_done, --open,  
    o_mag => mag_i, 
    o_phase => phs_i, 
    o_aux => open
);

ddc_done <= cordic_done;

--mag <=  mag_i;
--phs <=  phs_i;
--mag <= (31 downto 26 => mag_i(25)) & mag_i;
--phs <= (31 downto 26 => phs_i(25)) & phs_i;

mag <= mag_i & "000000";
phs <= phs_i & "000000";

end behv;
