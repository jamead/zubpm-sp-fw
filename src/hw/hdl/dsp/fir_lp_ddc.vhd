----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/05/2019 09:26:06 AM
-- Design Name: 
-- Module Name: beam_sine_rom - Behavioral
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;


entity fir_lp_ddc is
    port ( clk : in std_logic;
           rst : in std_logic;
           din : in signed(23 downto 0);
           dout : out signed(23 downto 0)
         );
end fir_lp_ddc;
 
architecture behv of fir_lp_ddc is

    type coef_data_type is array(0 to 3) of signed(15 downto 0);
    type tap_type is array(0 to 3) of signed(39 downto 0);
    
    
    --coefficients, 16 bits.  (0.1321, 0.3679, 0.3679, 0.1321)
    --int16(0.1231*2^16)
    signal coef_data : coef_data_type := (x"21D1", x"5E2F", x"5E2F", x"21D1");
    signal tap       : tap_type;
    signal sum       : tap_type;


 

begin

-- Transposed Form Implementation

--multipliers
process(clk)
  begin
    if (rising_edge(clk)) then
       tap(0) <= din * coef_data(3); 
       tap(1) <= din * coef_data(2);
       tap(2) <= din * coef_data(1);
       tap(3) <= din * coef_data(0);
    end if;
end process;

process(clk)
  begin
    if (rising_edge(clk)) then
       sum(0) <= tap(0); 
       sum(1) <= tap(1) + sum(0); 
       sum(2) <= tap(2) + sum(1);
       sum(3) <= tap(3) + sum(2); 
    end if;
end process;





--register the output
process(clk, rst)
   begin
      if (rst = '1') then
         dout <= x"000000";
      elsif (clk'event and clk = '1') then
         dout <= sum(3)(39 downto 16);
      end if;
 end process;



end behv;
